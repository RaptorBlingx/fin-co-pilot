import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'receipt_parser_agent.dart';

/// Receipt OCR Service with Cloud Vision AI Extension Integration
///
/// Flow:
/// 1. Upload image to Cloud Storage
/// 2. Vision AI extension automatically extracts text
/// 3. Wait for extraction (listen to Firestore)
/// 4. Pass extracted text to Gemini for intelligent parsing
/// 5. Return structured receipt data
///
/// Benefits:
/// - Higher OCR accuracy (Vision AI specialized for text)
/// - Automatic processing (no manual API calls)
/// - Cost-effective (free tier: 1,000 images/month)
class ReceiptOCRServiceWithVision {
  static final ReceiptOCRServiceWithVision _instance = 
      ReceiptOCRServiceWithVision._internal();
  factory ReceiptOCRServiceWithVision() => _instance;
  ReceiptOCRServiceWithVision._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReceiptParserAgent _parser = ReceiptParserAgent();

  /// Process receipt image with Vision AI + Gemini
  Future<Map<String, dynamic>> processReceipt({
    required File imageFile,
    String? userId,
  }) async {
    try {
      print('📸 Starting receipt OCR with Vision AI...');
      final startTime = DateTime.now();

      // Get user ID
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique image ID
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();

      // Step 1: Upload image to Cloud Storage (triggers Vision AI extension)
      print('⬆️  Uploading image to Cloud Storage...');
      final imageUrl = await _uploadReceiptImage(imageFile, uid, imageId);
      print('✅ Image uploaded: $imageUrl');

      // Step 2: Wait for Vision AI to extract text (listen to Firestore)
      print('👁️  Waiting for Vision AI text extraction...');
      final extractedText = await _waitForVisionAIExtraction(uid, imageId);
      
      if (extractedText == null || extractedText.isEmpty) {
        print('⚠️  No text extracted - image may be blank or unclear');
        return {
          'success': false,
          'error': 'Could not extract text from image. Please try again with a clearer photo.',
          'confidence': 0.0,
        };
      }

      print('✅ Text extracted (${extractedText.length} characters)');
      print('📝 Extracted text preview: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...');

      // Step 3: Parse extracted text with Gemini for intelligent interpretation
      print('🤖 Parsing receipt data with Gemini...');
      final parsedData = await _parser.parseExtractedText(extractedText);

      // Add processing metadata
      parsedData['imageUrl'] = imageUrl;
      parsedData['imageId'] = imageId;
      parsedData['extractedText'] = extractedText;
      parsedData['processingTimeMs'] = DateTime.now().difference(startTime).inMilliseconds;

      final processingTime = DateTime.now().difference(startTime).inSeconds;
      print('✅ Receipt processed in ${processingTime}s');

      return parsedData;
    } catch (e) {
      print('❌ Receipt OCR error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'confidence': 0.0,
      };
    }
  }

  /// Upload receipt image to Cloud Storage (triggers Vision AI extension)
  Future<String> _uploadReceiptImage(File imageFile, String userId, String imageId) async {
    try {
      // Upload to path that matches Vision AI extension config:
      // receipts/{userId}/images/{imageId}
      final storageRef = _storage.ref().child('receipts/$userId/images/$imageId.jpg');
      
      // Upload with metadata
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
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
      print('❌ Image upload error: $e');
      rethrow;
    }
  }

  /// Wait for Vision AI extension to extract text from image
  /// 
  /// Listens to Firestore collection: receipts/{userId}/scans/{imageId}
  /// Timeout: 30 seconds
  Future<String?> _waitForVisionAIExtraction(String userId, String imageId) async {
    try {
      final docRef = _firestore
          .collection('receipts')
          .doc(userId)
          .collection('scans')
          .doc(imageId);

      // Listen for document creation with timeout
      final docStream = docRef.snapshots();
      
      await for (final snapshot in docStream.timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          sink.addError(TimeoutException('Vision AI extraction timed out after 30 seconds'));
        },
      )) {
        if (snapshot.exists) {
          final data = snapshot.data();
          
          // Check if extraction is complete
          if (data != null && data.containsKey('extractedText')) {
            final extractedText = data['extractedText'] as String?;
            
            // Validate extracted text
            if (extractedText != null && extractedText.trim().isNotEmpty) {
              print('✅ Vision AI extraction complete');
              return extractedText;
            }
          }
          
          // If document exists but no text yet, keep waiting
          print('⏳ Vision AI still processing...');
        }
      }

      return null;
    } on TimeoutException catch (e) {
      print('⏱️  Vision AI extraction timeout: $e');
      throw Exception('Receipt processing is taking longer than expected. Please try again.');
    } catch (e) {
      print('❌ Vision AI extraction error: $e');
      rethrow;
    }
  }

  /// Delete receipt image and extracted data
  Future<void> deleteReceipt(String userId, String imageId) async {
    try {
      // Delete from Storage
      final storageRef = _storage.ref().child('receipts/$userId/images/$imageId.jpg');
      await storageRef.delete();

      // Delete from Firestore
      final docRef = _firestore
          .collection('receipts')
          .doc(userId)
          .collection('scans')
          .doc(imageId);
      await docRef.delete();

      print('🗑️  Receipt deleted: $imageId');
    } catch (e) {
      print('⚠️  Error deleting receipt: $e');
      // Don't throw - deletion errors are not critical
    }
  }

  /// Get all receipts for a user
  Stream<List<Map<String, dynamic>>> getReceiptsStream(String userId) {
    return _firestore
        .collection('receipts')
        .doc(userId)
        .collection('scans')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
