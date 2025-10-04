import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../services/transaction_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/preferences_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formController = TextEditingController();
  final _transactionService = TransactionService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  File? _selectedImage;
  String _selectedMethod = 'text'; // text, receipt

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedMethod = 'receipt';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedMethod = 'receipt';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addTransaction() async {
    final user = _authService.currentUser;
    if (user == null) return;
    
    final currency = PreferencesService.getCurrency() ?? 'USD';
    
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;
      
      if (_selectedMethod == 'receipt' && _selectedImage != null) {
        // Add from receipt
        result = await _transactionService.addTransactionFromReceipt(
          userId: user.uid,
          imageFile: _selectedImage!,
          currency: currency,
        );
      } else {
        // Add from text
        if (_formController.text.trim().isEmpty) {
          throw Exception('Please enter a transaction description');
        }
        
        result = await _transactionService.addTransactionFromText(
          userId: user.uid,
          description: _formController.text.trim(),
          currency: currency,
        );
      }
      
      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${result['error']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Method selector
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedMethod = 'text';
                        _selectedImage = null;
                      });
                    },
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Text'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedMethod == 'text'
                          ? Colors.blue.withOpacity(0.1)
                          : null,
                      side: BorderSide(
                        color: _selectedMethod == 'text'
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showImageSourceDialog(),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Receipt'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _selectedMethod == 'receipt'
                          ? Colors.blue.withOpacity(0.1)
                          : null,
                      side: BorderSide(
                        color: _selectedMethod == 'receipt'
                            ? Colors.blue
                            : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Text input method
            if (_selectedMethod == 'text') ...[
              TextField(
                controller: _formController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Describe your expense',
                  hintText: 'e.g., "Spent \$50 on groceries at Costco"',
                  border: OutlineInputBorder(),
                  helperText: 'AI will automatically extract amount, category, and merchant',
                ),
              ),
            ],
            
            // Receipt image preview
            if (_selectedMethod == 'receipt' && _selectedImage != null) ...[
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showImageSourceDialog(),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Another Photo'),
              ),
            ],
            
            // Receipt placeholder
            if (_selectedMethod == 'receipt' && _selectedImage == null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No receipt selected',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Add button
            ElevatedButton(
              onPressed: _isLoading ? null : _addTransaction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}