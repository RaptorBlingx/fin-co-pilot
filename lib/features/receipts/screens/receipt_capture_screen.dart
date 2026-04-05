import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/receipt_ocr_service_with_vision.dart'; // Vision AI integration
import '../../../services/preferences_service.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../models/transaction.dart' as model;
// REMOVED: import 'receipt_review_screen.dart'; // Tier 2 feature - broken, moved to backup

/// Receipt Capture Screen (Week 10 Feature)
///
/// Allows users to:
/// - Take photo of receipt with camera
/// - Select existing photo from gallery
/// - Auto-edge detection (via camera crop)
/// - Process receipt with Vision Agent OCR
/// - Navigate to review screen for confirmation
///
/// Target: Works with wrinkled/folded receipts
///
/// NOTE: V1.0 shows placeholder - full feature coming in V2.0
class ReceiptCaptureScreen extends StatefulWidget {
  const ReceiptCaptureScreen({super.key});

  @override
  State<ReceiptCaptureScreen> createState() => _ReceiptCaptureScreenState();
}

class _ReceiptCaptureScreenState extends State<ReceiptCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReceiptOCRServiceWithVision _ocrService = ReceiptOCRServiceWithVision(); // Vision AI
  final AuthService _authService = AuthService();

  File? _imageFile;
  bool _isProcessing = false;
  double _processingProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _imageFile == null ? _buildCaptureOptions(theme) : _buildPreview(theme),
      ),
    );
  }

  /// Build capture options (camera/gallery)
  Widget _buildCaptureOptions(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Scan Your Receipt',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Get itemized tracking and price intelligence',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Camera button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _captureImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Gallery button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _captureImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tips: Good lighting, lay receipt flat, capture all text',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image preview with process button
  Widget _buildPreview(ThemeData theme) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _imageFile!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Processing indicator
        if (_isProcessing) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                LinearProgressIndicator(value: _processingProgress),
                const SizedBox(height: 8),
                Text(
                  _getProcessingMessage(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Retake button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _retakePhoto,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Process button
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processReceipt,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isProcessing ? 'Processing...' : 'Process Receipt'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Capture image from camera or gallery
  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Balance quality and file size
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing image: $e')),
        );
      }
    }
  }

  /// Retake photo
  void _retakePhoto() {
    setState(() {
      _imageFile = null;
    });
  }

  /// Process receipt with OCR
  Future<void> _processReceipt() async {
    if (_imageFile == null) return;

    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to scan receipts')),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
    });

    try {
      // Step 1: Upload image (triggers Vision AI)
      _updateProgress(0.2, 'Uploading image...');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Vision AI extracts text
      _updateProgress(0.5, 'Extracting text with Vision AI...');
      
      // Process with Vision AI
      final result = await _ocrService.processReceipt(
        imageFile: _imageFile!,
        userId: user.uid,
      );

      _updateProgress(0.8, 'Parsing receipt data...');
      await Future.delayed(const Duration(milliseconds: 300));

      _updateProgress(1.0, 'Complete!');

      if (!result['success']) {
        throw Exception(result['error'] ?? 'Could not process receipt');
      }

      // Get receipt data
      final receiptData = result['data'];
      final warnings = result['warnings'] as List<String>?;

      // Show success message
      if (mounted) {
        String message = '✅ Receipt processed successfully!';
        if (warnings != null && warnings.isNotEmpty) {
          message += '\n⚠️ ${warnings.join(', ')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Show receipt data (for now, just display in dialog)
        // Save transaction from receipt OCR data
        await _saveReceiptTransaction(receiptData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing receipt: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingProgress = 0.0;
        });
      }
    }
  }

  /// Save transaction from receipt OCR data
  Future<void> _saveReceiptTransaction(Map<String, dynamic> receiptData) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final currency = PreferencesService.getCurrency() ?? 'USD';
      final store = receiptData['store'] as String? ?? 'Unknown Store';
      final total = (receiptData['total'] as num?)?.toDouble() ?? 0.0;

      DateTime txnDate = DateTime.now();
      if (receiptData['date'] != null) {
        try {
          txnDate = DateTime.parse(receiptData['date'].toString());
        } catch (_) {}
      }

      final transaction = model.Transaction(
        userId: user.uid,
        amount: total,
        currency: currency,
        category: 'shopping',
        merchant: store,
        description: 'Receipt from $store',
        paymentMethod: 'cash',
        transactionDate: txnDate,
        createdAt: DateTime.now(),
        inputMethod: 'receipt_scan',
        receiptData: receiptData,
      );

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      // Update budget spending
      final month =
          '${txnDate.year}-${txnDate.month.toString().padLeft(2, '0')}';
      final budgetQuery = await firestore
          .collection('budgets')
          .where('user_id', isEqualTo: user.uid)
          .where('category', isEqualTo: 'shopping')
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (budgetQuery.docs.isNotEmpty) {
        final budgetDoc = budgetQuery.docs.first;
        final currentSpending =
            (budgetDoc.data()['currentSpending'] as num?)?.toDouble() ?? 0;
        await firestore.collection('budgets').doc(budgetDoc.id).update({
          'currentSpending': currentSpending + total,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      HapticUtils.heavy();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Transaction saved: ${CurrencyUtils.formatAmount(total, currency)} at $store',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Update processing progress
  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _processingProgress = progress;
      });
    }
  }

  /// Get processing message based on progress
  String _getProcessingMessage() {
    if (_processingProgress < 0.2) return 'Uploading image...';
    if (_processingProgress < 0.5) return 'Analyzing receipt with AI...';
    if (_processingProgress < 0.8) return 'Extracting items and prices...';
    if (_processingProgress < 1.0) return 'Finalizing...';
    return 'Complete!';
  }
}
