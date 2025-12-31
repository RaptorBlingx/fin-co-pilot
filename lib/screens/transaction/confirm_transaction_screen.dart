import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/ai/transaction_parser_service.dart';
import '../../services/transaction_service.dart';
import '../../core/constants/categories.dart';

/// Confirmation screen for parsed transactions
/// 
/// Shows parsed fields with edit capability before saving
/// Simple, clean UI following Week 2 goals
class ConfirmTransactionScreen extends StatefulWidget {
  final TransactionParseResult parseResult;

  const ConfirmTransactionScreen({
    super.key,
    required this.parseResult,
  });

  @override
  State<ConfirmTransactionScreen> createState() => _ConfirmTransactionScreenState();
}

class _ConfirmTransactionScreenState extends State<ConfirmTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionService = TransactionService();
  
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  late TextEditingController _descriptionController;
  
  late String _selectedCategory;
  late DateTime _selectedDate;
  String? _selectedPaymentMethod;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize with parsed values
    _amountController = TextEditingController(
      text: widget.parseResult.amount?.toStringAsFixed(2) ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.parseResult.merchant ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.parseResult.description ?? '',
    );
    
    _selectedCategory = widget.parseResult.category ?? 'Other';
    _selectedDate = widget.parseResult.toTransactionData().date ?? DateTime.now();
    _selectedPaymentMethod = widget.parseResult.paymentMethod;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);
      
      // Get current user ID (simplified - in production use proper auth)
      final userId = 'user_123'; // TODO: Replace with actual user ID from auth
      
      // Save transaction using existing service
      await _transactionService.addTransactionFromText(
        userId: userId,
        description: _descriptionController.text,
        currency: 'USD',
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction saved! \$${amount.toStringAsFixed(2)} added to $_selectedCategory'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Return to previous screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transaction'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Confidence indicator
            if (widget.parseResult.confidence < 1.0)
              _buildConfidenceCard(),
            
            const SizedBox(height: 16),
            
            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: AppCategories.categories.map((cat) {
                return DropdownMenuItem(
                  value: cat.name,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 20, color: cat.color),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Merchant field
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(
                labelText: 'Merchant (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Date picker
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
              leading: const Icon(Icons.calendar_today),
              trailing: const Icon(Icons.edit),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Transaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = widget.parseResult.confidence;
    final isHighConfidence = confidence >= 0.7;
    
    return Card(
      color: isHighConfidence ? Colors.blue.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isHighConfidence ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isHighConfidence ? Colors.blue : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHighConfidence ? 'High confidence parse' : 'Please verify details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isHighConfidence ? Colors.blue.shade900 : Colors.orange.shade900,
                    ),
                  ),
                  Text(
                    'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isHighConfidence ? Colors.blue.shade700 : Colors.orange.shade700,
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
}
