import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';

/// Service to handle file attachment analysis via Gemini AI.
/// Supports PDF, CSV, TXT, and image files for financial data extraction.
class FileAnalysisService {
  late final GenerativeModel _model;

  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  static const Map<String, String> _extensionToMime = {
    'pdf': 'application/pdf',
    'csv': 'text/csv',
    'txt': 'text/plain',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };

  static const List<String> allowedExtensions = [
    'pdf', 'csv', 'txt', 'jpg', 'jpeg', 'png', 'webp', 'xls', 'xlsx',
  ];

  FileAnalysisService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite-preview',
    );
  }

  /// Pick a file using the system file picker.
  /// Returns null if the user cancels.
  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  /// Validate the picked file (size, extension).
  String? validateFile(PlatformFile file) {
    if (file.size > maxFileSizeBytes) {
      final sizeMB = (file.size / (1024 * 1024)).toStringAsFixed(1);
      return 'File too large ($sizeMB MB). Maximum is 10 MB.';
    }

    final ext = file.extension?.toLowerCase();
    if (ext == null || !allowedExtensions.contains(ext)) {
      return 'Unsupported file type. Allowed: PDF, CSV, TXT, images, Excel.';
    }

    return null; // valid
  }

  /// Analyze a file using Gemini AI for financial data extraction.
  Future<FileAnalysisResult> analyzeFile(PlatformFile file) async {
    try {
      final Uint8List bytes;
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        return FileAnalysisResult(
          success: false,
          errorMessage: 'Could not read the file.',
        );
      }

      final ext = file.extension?.toLowerCase() ?? '';
      final mimeType = _extensionToMime[ext] ?? 'application/octet-stream';
      final fileName = file.name;

      final prompt = _buildAnalysisPrompt(fileName, ext);

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart(mimeType, bytes),
        ])
      ]);

      final responseText = response.text ?? '';

      if (responseText.isEmpty) {
        return FileAnalysisResult(
          success: false,
          errorMessage: 'Could not extract data from the file.',
        );
      }

      return FileAnalysisResult(
        success: true,
        fileName: fileName,
        fileType: ext,
        summary: responseText,
      );
    } catch (e) {
      return FileAnalysisResult(
        success: false,
        errorMessage: 'Failed to analyze file: ${e.toString()}',
      );
    }
  }

  String _buildAnalysisPrompt(String fileName, String ext) {
    return '''
You are a financial document analyst. Analyze this file ("$fileName") and extract all relevant financial information.

Focus on:
1. **Transactions**: Any purchases, payments, transfers, deposits — extract date, amount, merchant/description, category
2. **Account Summary**: Balances, totals, period covered
3. **Patterns**: Recurring charges, subscriptions, large expenses
4. **Key Numbers**: Total income, total spending, net balance

Formatting rules:
- Use plain text, not markdown
- Be concise but thorough
- If it's a bank/credit card statement, list the transactions clearly
- If it's a receipt, extract all line items and totals
- If it's a spreadsheet/CSV, summarize the financial data
- If the file doesn't contain financial data, describe what you see and suggest how you can help

End with a brief 1-2 sentence summary of the key takeaway.
''';
  }
}

class FileAnalysisResult {
  final bool success;
  final String? fileName;
  final String? fileType;
  final String? summary;
  final String? errorMessage;

  FileAnalysisResult({
    required this.success,
    this.fileName,
    this.fileType,
    this.summary,
    this.errorMessage,
  });
}
