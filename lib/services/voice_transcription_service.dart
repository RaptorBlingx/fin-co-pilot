import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Voice Transcription Service with Speech-to-Text Extension Integration
///
/// Flow:
/// 1. Record audio (max 10 seconds for quick transactions)
/// 2. Upload audio to Cloud Storage
/// 3. Speech-to-Text extension automatically transcribes
/// 4. Wait for transcription (listen to Firestore)
/// 5. Return transcribed text
///
/// Benefits:
/// - Accurate transcription (Google Speech-to-Text API)
/// - Multiple language support
/// - Automatic punctuation
/// - Cost-effective (free tier: 60 minutes/month)
class VoiceTranscriptionService {
  static final VoiceTranscriptionService _instance = 
      VoiceTranscriptionService._internal();
  factory VoiceTranscriptionService() => _instance;
  VoiceTranscriptionService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  String? _currentRecordingPath;

  /// Check if recording is in progress
  bool get isRecording => _isRecording;

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await _recorder.hasPermission()) {
        print('⚠️  Microphone permission denied');
        return false;
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final audioId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentRecordingPath = '${tempDir.path}/voice_$audioId.wav';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav, // WAV format for best compatibility
          bitRate: 128000,
          sampleRate: 16000, // 16kHz for speech (optimal for Speech-to-Text)
          numChannels: 1, // Mono
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      print('🎤 Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      print('❌ Recording start error: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording and return audio file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️  No recording in progress');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        print('⚠️  Recording stopped but no file created');
        return null;
      }

      print('✅ Recording stopped: $path');
      return path;
    } catch (e) {
      print('❌ Recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;

        // Delete the file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        print('🚫 Recording cancelled');
      }
    } catch (e) {
      print('⚠️  Error cancelling recording: $e');
    }
  }

  /// Transcribe audio file using Speech-to-Text extension
  Future<Map<String, dynamic>> transcribeAudio({
    required String audioFilePath,
    String? userId,
  }) async {
    try {
      print('🎙️  Starting audio transcription...');
      final startTime = DateTime.now();

      // Get user ID
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique audio ID
      final audioId = DateTime.now().millisecondsSinceEpoch.toString();

      // Step 1: Upload audio to Cloud Storage (triggers Speech-to-Text extension)
      print('⬆️  Uploading audio to Cloud Storage...');
      final audioUrl = await _uploadAudio(audioFilePath, uid, audioId);
      print('✅ Audio uploaded: $audioUrl');

      // Step 2: Wait for Speech-to-Text to transcribe (listen to Firestore)
      print('👂 Waiting for Speech-to-Text transcription...');
      final transcription = await _waitForTranscription(uid, audioId);
      
      if (transcription == null || transcription.isEmpty) {
        print('⚠️  No transcription received - audio may be unclear');
        return {
          'success': false,
          'error': 'Could not transcribe audio. Please speak clearly and try again.',
          'confidence': 0.0,
        };
      }

      print('✅ Transcription complete: "$transcription"');

      // Get transcription confidence if available
      final docRef = _firestore
          .collection('transcriptions')
          .doc(uid)
          .collection('results')
          .doc(audioId);
      final docSnapshot = await docRef.get();
      final confidence = docSnapshot.data()?['confidence'] as double? ?? 0.8;

      final processingTime = DateTime.now().difference(startTime).inSeconds;
      print('✅ Audio transcribed in ${processingTime}s');

      return {
        'success': true,
        'transcript': transcription,
        'confidence': confidence,
        'audioUrl': audioUrl,
        'audioId': audioId,
        'processingTimeMs': DateTime.now().difference(startTime).inMilliseconds,
      };
    } catch (e) {
      print('❌ Audio transcription error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'confidence': 0.0,
      };
    } finally {
      // Clean up audio file
      try {
        final file = File(audioFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️  Error deleting audio file: $e');
      }
    }
  }

  /// Upload audio to Cloud Storage (triggers Speech-to-Text extension)
  Future<String> _uploadAudio(String audioFilePath, String userId, String audioId) async {
    try {
      // Upload to path that matches Speech-to-Text extension config:
      // voice_inputs/{userId}/audio/{audioId}
      final storageRef = _storage.ref().child('voice_inputs/$userId/audio/$audioId.wav');
      
      final audioFile = File(audioFilePath);
      
      // Upload with metadata
      final uploadTask = storageRef.putFile(
        audioFile,
        SettableMetadata(
          contentType: 'audio/wav',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('❌ Audio upload error: $e');
      rethrow;
    }
  }

  /// Wait for Speech-to-Text extension to transcribe audio
  /// 
  /// Listens to Firestore collection: transcriptions/{userId}/results/{audioId}
  /// Timeout: 20 seconds
  Future<String?> _waitForTranscription(String userId, String audioId) async {
    try {
      final docRef = _firestore
          .collection('transcriptions')
          .doc(userId)
          .collection('results')
          .doc(audioId);

      // Listen for document creation with timeout
      final docStream = docRef.snapshots();
      
      await for (final snapshot in docStream.timeout(
        const Duration(seconds: 20),
        onTimeout: (sink) {
          sink.addError(TimeoutException('Speech-to-Text transcription timed out after 20 seconds'));
        },
      )) {
        if (snapshot.exists) {
          final data = snapshot.data();
          
          // Check if transcription is complete
          if (data != null && data.containsKey('transcript')) {
            final transcript = data['transcript'] as String?;
            
            // Validate transcript
            if (transcript != null && transcript.trim().isNotEmpty) {
              print('✅ Speech-to-Text transcription complete');
              return transcript;
            }
          }
          
          // If document exists but no transcript yet, keep waiting
          print('⏳ Speech-to-Text still processing...');
        }
      }

      return null;
    } on TimeoutException catch (e) {
      print('⏱️  Speech-to-Text transcription timeout: $e');
      throw Exception('Audio transcription is taking longer than expected. Please try again.');
    } catch (e) {
      print('❌ Speech-to-Text transcription error: $e');
      rethrow;
    }
  }

  /// Delete audio and transcription data
  Future<void> deleteTranscription(String userId, String audioId) async {
    try {
      // Delete from Storage
      final storageRef = _storage.ref().child('voice_inputs/$userId/audio/$audioId.wav');
      await storageRef.delete();

      // Delete from Firestore
      final docRef = _firestore
          .collection('transcriptions')
          .doc(userId)
          .collection('results')
          .doc(audioId);
      await docRef.delete();

      print('🗑️  Transcription deleted: $audioId');
    } catch (e) {
      print('⚠️  Error deleting transcription: $e');
      // Don't throw - deletion errors are not critical
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.dispose();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
