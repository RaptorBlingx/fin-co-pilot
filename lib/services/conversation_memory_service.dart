import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/memory_models.dart';

/// Manages cross-session conversation memory.
/// Summarizes conversations on session end, loads last 3 on session start.
class ConversationMemoryService {
  final FirebaseFirestore _firestore;
  late final GenerativeModel _model;

  static const int _maxSummaries = 10;
  static const int _summariesToLoad = 3;

  ConversationMemoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      systemInstruction: Content.text(
        'You are a conversation summarizer. Given a chat transcript between a user and their AI financial assistant, '
        'produce a concise JSON summary. Focus on: financial topics discussed, decisions made, and open questions. '
        'Respond ONLY with valid JSON, no markdown fences.',
      ),
    );
  }

  DocumentReference _summariesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('memory').doc('conversation_summaries');

  /// Summarize the current conversation and store it.
  /// Call this when the chat session ends (app backgrounded / screen disposed).
  Future<void> summarizeAndStore({
    required String userId,
    required List<MessageSnapshot> messages,
  }) async {
    if (messages.length < 3) return; // Too short to summarize

    try {
      final transcript = _buildTranscript(messages);
      final response = await _model.generateContent([Content.text(transcript)]);
      final text = response.text?.trim() ?? '';

      if (text.isEmpty) return;

      // Parse the summary
      final summary = _parseSummary(text);
      if (summary == null) return;

      // Load existing summaries
      final doc = await _summariesRef(userId).get();
      List<ConversationSummary> existing = [];
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        existing = ConversationSummaries.fromFirestore(data).summaries.toList();
      }

      // Add new summary, keep only last N
      existing.add(summary);
      if (existing.length > _maxSummaries) {
        existing = existing.sublist(existing.length - _maxSummaries);
      }

      await _summariesRef(userId).set(
        ConversationSummaries(summaries: existing).toFirestore(),
      );
    } catch (e) {
      print('[ConversationMemoryService] summarizeAndStore error: $e');
    }
  }

  /// Load the last 3 conversation summaries as a formatted text block
  /// for injection into the system instruction.
  Future<String> loadRecentSummaries(String userId) async {
    try {
      final doc = await _summariesRef(userId).get();
      if (!doc.exists) return '';

      final data = doc.data() as Map<String, dynamic>;
      final summaries = ConversationSummaries.fromFirestore(data).summaries;

      if (summaries.isEmpty) return '';

      final recent = summaries.length > _summariesToLoad
          ? summaries.sublist(summaries.length - _summariesToLoad)
          : summaries;

      final buf = StringBuffer();
      for (final s in recent) {
        final dateStr = '${s.date.month}/${s.date.day}';
        buf.writeln('[$dateStr]');
        if (s.keyTopics.isNotEmpty) {
          buf.writeln('  Topics: ${s.keyTopics.join(", ")}');
        }
        if (s.decisions.isNotEmpty) {
          buf.writeln('  Decisions: ${s.decisions.join(", ")}');
        }
        if (s.openQuestions.isNotEmpty) {
          buf.writeln('  Open: ${s.openQuestions.join(", ")}');
        }
      }
      return buf.toString().trim();
    } catch (e) {
      print('[ConversationMemoryService] loadRecentSummaries error: $e');
      return '';
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  String _buildTranscript(List<MessageSnapshot> messages) {
    final buf = StringBuffer();
    buf.writeln('Summarize this financial assistant conversation as JSON with keys: '
        '"key_topics" (list of strings), "decisions" (list of strings), "open_questions" (list of strings).');
    buf.writeln('---');
    for (final m in messages) {
      final role = m.isUser ? 'USER' : 'ASSISTANT';
      buf.writeln('$role: ${m.text}');
    }
    return buf.toString();
  }

  ConversationSummary? _parseSummary(String text) {
    try {
      // Strip markdown fences if present
      var cleaned = text;
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleaned = cleaned.replaceFirst(RegExp(r'\n?```$'), '');
      }

      // Parse JSON manually to avoid importing dart:convert everywhere
      // Using a simple approach: look for arrays in the text
      final topics = _extractJsonArray(cleaned, 'key_topics');
      final decisions = _extractJsonArray(cleaned, 'decisions');
      final openQuestions = _extractJsonArray(cleaned, 'open_questions');

      return ConversationSummary(
        date: DateTime.now(),
        keyTopics: topics,
        decisions: decisions,
        openQuestions: openQuestions,
      );
    } catch (e) {
      print('[ConversationMemoryService] _parseSummary error: $e');
      return null;
    }
  }

  List<String> _extractJsonArray(String json, String key) {
    final pattern = RegExp('"$key"\\s*:\\s*\\[([^\\]]*)\\]');
    final match = pattern.firstMatch(json);
    if (match == null) return [];

    final arrayContent = match.group(1) ?? '';
    final items = RegExp(r'"([^"]*)"').allMatches(arrayContent);
    return items.map((m) => m.group(1) ?? '').where((s) => s.isNotEmpty).toList();
  }
}

/// Lightweight snapshot of a chat message for summarization.
class MessageSnapshot {
  final String text;
  final bool isUser;

  const MessageSnapshot({required this.text, required this.isUser});
}
