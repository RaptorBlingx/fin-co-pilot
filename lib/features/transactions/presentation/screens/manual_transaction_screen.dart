import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/transaction.dart' as model;
import '../../../../services/preferences_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../services/custom_category_service.dart';
import '../../../../shared/widgets/add_category_sheet.dart';

class ManualTransactionScreen extends StatefulWidget {
  const ManualTransactionScreen({super.key});

  @override
  State<ManualTransactionScreen> createState() =>
      _ManualTransactionScreenState();
}

class _ManualTransactionScreenState extends State<ManualTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isExpense = true;
  String _selectedCategory = 'Food';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  List<String> _customCategoryNames = [];

  static const List<String> _expenseCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
    'Other',
  ];

  static const List<String> _incomeCategories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Other',
  ];

  static const List<String> _paymentMethods = [
    'Cash',
    'Card',
    'Bank Transfer',
    'Mobile Payment',
    'Other',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.local_hospital,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Salary': Icons.account_balance,
    'Freelance': Icons.work,
    'Investment': Icons.trending_up,
    'Gift': Icons.card_giftcard,
    'Other': Icons.more_horiz,
  };

  List<String> get _categories =>
      _isExpense
          ? [..._expenseCategories, ..._customCategoryNames]
          : [..._incomeCategories, ..._customCategoryNames];

  @override
  void initState() {
    super.initState();
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final service = CustomCategoryService();
    final custom = await service.getCustomCategories();
    if (mounted) {
      setState(() {
        _customCategoryNames = custom.map((c) => c.name).toList();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = PreferencesService.getCurrency() ?? 'USD';
    final currencySymbol = CurrencyUtils.getCurrencySymbol(currency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Type toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward, size: 18),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward, size: 18),
                ),
              ],
              selected: {_isExpense},
              onSelectionChanged: (value) {
                HapticUtils.light();
                setState(() {
                  _isExpense = value.first;
                  // Reset category if current one isn't valid for new type
                  if (!_categories.contains(_selectedCategory)) {
                    _selectedCategory = _categories.first;
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // Amount field
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$currencySymbol ',
                prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter an amount';
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Category chips
            Text(
              'Category',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return FilterChip(
                    selected: isSelected,
                    showCheckmark: false,
                    label: Text(cat),
                    avatar: Icon(
                      _categoryIcons[cat] ?? Icons.more_horiz,
                      size: 18,
                    ),
                    onSelected: (_) {
                      HapticUtils.light();
                      setState(() => _selectedCategory = cat);
                    },
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('Custom'),
                  onPressed: () async {
                    final result = await showAddCategorySheet(context);
                    if (result != null && mounted) {
                      setState(() {
                        _customCategoryNames.add(result.name);
                        _selectedCategory = result.name;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Merchant
            TextFormField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Merchant (optional)',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),

            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: theme.textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),

            const SizedBox(height: 16),

            // Payment method dropdown
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: const Icon(Icons.payment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              items: _paymentMethods
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPaymentMethod = value);
                }
              },
            ),

            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveTransaction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Transaction'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      HapticUtils.light();
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currency = PreferencesService.getCurrency() ?? 'USD';
      final amount = double.parse(_amountController.text);

      // For income, use 'Income' as category in Firestore
      final category =
          _isExpense ? _selectedCategory.toLowerCase() : 'income';

      final transaction = model.Transaction(
        userId: user.uid,
        amount: amount,
        currency: currency,
        category: category,
        merchant: _merchantController.text.isNotEmpty
            ? _merchantController.text.trim()
            : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text.trim()
            : '${_isExpense ? "Expense" : "Income"}: $_selectedCategory',
        paymentMethod: _selectedPaymentMethod.toLowerCase().replaceAll(' ', '_'),
        transactionDate: _selectedDate,
        createdAt: DateTime.now(),
        inputMethod: 'manual',
      );

      // Save to Firestore
      await _firestore
          .collection('transactions')
          .add(transaction.toFirestore());

      // Update budget spending (expenses only)
      if (_isExpense) {
        await _updateBudgetSpending(
          userId: user.uid,
          category: category,
          amount: amount,
          transactionDate: _selectedDate,
        );
      }

      HapticUtils.heavy();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${_isExpense ? "Expense" : "Income"} of ${CurrencyUtils.formatAmount(amount, currency)} saved',
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
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateBudgetSpending({
    required String userId,
    required String category,
    required double amount,
    required DateTime transactionDate,
  }) async {
    try {
      final month =
          '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

      final budgetQuery = await _firestore
          .collection('budgets')
          .where('user_id', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .where('month', isEqualTo: month)
          .limit(1)
          .get();

      if (budgetQuery.docs.isNotEmpty) {
        final budgetDoc = budgetQuery.docs.first;
        final currentSpending =
            (budgetDoc.data()['currentSpending'] as num?)?.toDouble() ?? 0;
        await _firestore.collection('budgets').doc(budgetDoc.id).update({
          'currentSpending': currentSpending + amount,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Budget update failure shouldn't block transaction save
    }
  }
}
