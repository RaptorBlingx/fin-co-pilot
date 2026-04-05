import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../shared/widgets/glass_bottom_sheet.dart';
import '../../../../shared/widgets/add_category_sheet.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../services/transaction_service.dart';
import '../../../../services/custom_category_service.dart';

/// Transaction Edit Screen
/// 
/// PHASE 1 FIX #3: Complete edit functionality (was TODO)
/// Allows users to edit any field of an existing transaction
class TransactionEditScreen extends StatefulWidget {
  final model.Transaction transaction;

  const TransactionEditScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isSaving = false;
  List<CustomCategory> _customCategories = [];

  final List<String> _paymentMethods = [
    'cash',
    'credit_card',
    'debit_card',
    'bank_transfer',
    'digital_wallet',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.transaction.merchant ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction.amount.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.description ?? '',
    );
    _notesController = TextEditingController(
      text: widget.transaction.notes ?? '',
    );
    _selectedCategory = widget.transaction.category;
    _selectedPaymentMethod = widget.transaction.paymentMethod;
    _selectedDate = widget.transaction.transactionDate;
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final custom = await CustomCategoryService().getCustomCategories();
    if (mounted) setState(() => _customCategories = custom);
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newAmount = double.parse(_amountController.text);
      final oldAmount = widget.transaction.amount;
      final oldCategory = widget.transaction.category.toLowerCase();
      final newCategory = _selectedCategory.toLowerCase();
      final transactionService = TransactionService();

      // Update transaction in Firestore
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transaction.id)
          .update({
        'merchant': _merchantController.text.trim(),
        'amount': newAmount,
        'description': _descriptionController.text.trim(),
        'category': newCategory,
        'payment_method': _selectedPaymentMethod,
        'notes': _notesController.text.trim(),
        'transactionDate': Timestamp.fromDate(_selectedDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sync budget spending for amount/category changes
      if (oldCategory == newCategory) {
        // Same category — apply delta
        final delta = newAmount - oldAmount;
        if (delta != 0) {
          await transactionService.updateBudgetSpendingPublic(
            userId: widget.transaction.userId,
            category: newCategory,
            amount: delta,
            transactionDate: _selectedDate,
          );
        }
      } else {
        // Category changed — decrement old, increment new
        await transactionService.updateBudgetSpendingPublic(
          userId: widget.transaction.userId,
          category: oldCategory,
          amount: -oldAmount,
          transactionDate: widget.transaction.transactionDate,
        );
        await transactionService.updateBudgetSpendingPublic(
          userId: widget.transaction.userId,
          category: newCategory,
          amount: newAmount,
          transactionDate: _selectedDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction updated successfully'),
            backgroundColor: AppTheme.accentEmerald,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transaction: $e'),
            backgroundColor: AppTheme.rose500,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = AppCategories.getCategoryByName(_selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        centerTitle: true,
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.space16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryIndigo,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold)),
              tooltip: 'Save',
              onPressed: _saveTransaction,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(DesignTokens.space16),
          children: [
            // Merchant field
            _buildTextField(
              controller: _merchantController,
              label: 'Merchant',
              hint: 'Where did you shop?',
              icon: PhosphorIcons.storefront(),
              capitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a merchant name';
                }
                return null;
              },
            ),
            SizedBox(height: DesignTokens.space16),

            // Amount field
            _buildTextField(
              controller: _amountController,
              label: 'Amount',
              hint: '0.00',
              icon: PhosphorIcons.currencyDollar(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
            SizedBox(height: DesignTokens.space16),

            // Description field
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Brief description of the transaction',
              icon: PhosphorIcons.noteBlank(),
              capitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            SizedBox(height: DesignTokens.space16),

            // Category selector
            GlassCard(
              onTap: _showCategoryPicker,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Icon(category.icon, color: category.color),
                ),
                title: Text(
                  'Category',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                subtitle: Text(
                  _selectedCategory,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  PhosphorIcons.caretDown(),
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space16),

            // Date selector
            GlassCard(
              onTap: _selectDate,
              child: ListTile(
                leading: Icon(
                  PhosphorIcons.calendarBlank(),
                  color: AppTheme.primaryIndigo,
                ),
                title: Text(
                  'Date',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                subtitle: Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  PhosphorIcons.caretDown(),
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space16),

            // Payment Method selector
            GlassCard(
              onTap: _showPaymentMethodPicker,
              child: ListTile(
                leading: Icon(
                  _getPaymentMethodIcon(_selectedPaymentMethod),
                  color: AppTheme.primaryIndigo,
                ),
                title: Text(
                  'Payment Method',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                subtitle: Text(
                  _formatPaymentMethod(_selectedPaymentMethod),
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  PhosphorIcons.caretDown(),
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space16),

            // Notes field
            _buildTextField(
              controller: _notesController,
              label: 'Notes (Optional)',
              hint: 'Add any additional details...',
              icon: PhosphorIcons.note(),
              maxLines: 3,
              capitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: DesignTokens.space24),

            // Save button
            PremiumButton(
              onPressed: _isSaving ? null : _saveTransaction,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Icon(PhosphorIcons.floppyDisk(), size: DesignTokens.iconSM),
                  SizedBox(width: DesignTokens.space8),
                  Text(_isSaving ? 'Saving...' : 'Save Changes'),
                ],
              ),
            ),
          ]
              .animate(interval: DesignTokens.staggerDelay)
              .fadeIn(duration: DesignTokens.durationNormal)
              .slideY(begin: 0.03, end: 0),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        filled: true,
        fillColor: context.colors.surface,
      ),
      textCapitalization: capitalization,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
    );
  }

  void _showCategoryPicker() {
    final allCategories = AppCategories.mergedWith(_customCategories);

    showGlassBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: DesignTokens.space16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: DesignTokens.space12,
                mainAxisSpacing: DesignTokens.space12,
              ),
              itemCount: allCategories.length + 1, // +1 for "Add" tile
              itemBuilder: (context, index) {
                // Last tile = "Add Custom"
                if (index == allCategories.length) {
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await showAddCategorySheet(this.context);
                      if (result != null && mounted) {
                        setState(() {
                          _customCategories.add(result);
                          _selectedCategory = result.name;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                        border: Border.all(
                          color: context.colors.outline.withOpacity(0.2),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.plus(), color: AppTheme.primaryIndigo, size: DesignTokens.iconLG),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            'Custom',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final cat = allCategories[index];
                final isSelected = cat.name.toLowerCase() == _selectedCategory.toLowerCase();
                
                return InkWell(
                  onTap: () {
                    setState(() => _selectedCategory = cat.name);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withOpacity(0.2)
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                      border: Border.all(
                        color: isSelected
                            ? cat.color
                            : context.colors.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(cat.icon, color: cat.color, size: DesignTokens.iconLG),
                        SizedBox(height: DesignTokens.space4),
                        Text(
                          cat.name,
                          style: context.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return PhosphorIcons.money();
      case 'credit_card':
        return PhosphorIcons.creditCard();
      case 'debit_card':
        return PhosphorIcons.contactlessPayment();
      case 'bank_transfer':
        return PhosphorIcons.bank();
      case 'digital_wallet':
        return PhosphorIcons.wallet();
      default:
        return PhosphorIcons.creditCard();
    }
  }

  String _formatPaymentMethod(String method) {
    return method.split('_').map((word) =>
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  void _showPaymentMethodPicker() {
    showGlassBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: DesignTokens.space16),
            ..._paymentMethods.map((method) {
              final isSelected = method == _selectedPaymentMethod;
              return ListTile(
                leading: Icon(
                  _getPaymentMethodIcon(method),
                  color: isSelected ? AppTheme.primaryIndigo : null,
                ),
                title: Text(
                  _formatPaymentMethod(method),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : null,
                    color: isSelected ? AppTheme.primaryIndigo : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color: AppTheme.accentEmerald)
                    : null,
                onTap: () {
                  setState(() => _selectedPaymentMethod = method);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
