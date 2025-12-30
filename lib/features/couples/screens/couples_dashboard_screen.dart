import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/couple_account.dart';
import '../../../models/transaction.dart' as models;
import '../../../services/auth_service.dart';
import '../../../services/couples_service.dart';

/// Couples Dashboard Screen (Week 11 Feature)
///
/// Shows shared financial view for couples:
/// - Your spending vs Partner's spending
/// - Combined totals
/// - Recent transactions from both partners
/// - Shared budgets overview
/// - Large spend notifications
class CouplesDashboardScreen extends StatefulWidget {
  const CouplesDashboardScreen({super.key});

  @override
  State<CouplesDashboardScreen> createState() => _CouplesDashboardScreenState();
}

class _CouplesDashboardScreenState extends State<CouplesDashboardScreen> {
  final CouplesService _couplesService = CouplesService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CoupleAccount? _coupleAccount;
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  // Spending data
  double _mySpending = 0;
  double _partnerSpending = 0;
  List<models.Transaction> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadCoupleAccount();
  }

  Future<void> _loadCoupleAccount() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final account = await _couplesService.getActiveCoupleAccount(user.uid);

      if (account == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No couple account found. Please pair with your partner first.'),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _coupleAccount = account;
      });

      await _loadSpendingData(user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading couple account: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSpendingData(String currentUserId) async {
    if (_coupleAccount == null) return;

    final partnerId = _coupleAccount!.getPartnerId(currentUserId);
    if (partnerId == null) return;

    // Get start and end of selected month
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    try {
      // Load my spending
      final myTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: currentUserId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('type', isEqualTo: 'expense')
          .get();

      double myTotal = 0;
      for (final doc in myTransactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        myTotal += amount;
      }

      // Load partner's spending
      final partnerTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('user_id', isEqualTo: partnerId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .where('type', isEqualTo: 'expense')
          .get();

      double partnerTotal = 0;
      for (final doc in partnerTransactionsSnapshot.docs) {
        final amount = (doc.data()['amount'] as num).toDouble();
        partnerTotal += amount;
      }

      // Load recent transactions from both
      final allTransactionsSnapshot = await _firestore
          .collection('transactions')
          .where('user_id', whereIn: [currentUserId, partnerId])
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date', descending: true)
          .limit(20)
          .get();

      final transactions = allTransactionsSnapshot.docs
          .map((doc) => models.Transaction.fromFirestore(doc))
          .toList();

      setState(() {
        _mySpending = myTotal;
        _partnerSpending = partnerTotal;
        _recentTransactions = transactions;
      });
    } catch (e) {
      print('Error loading spending data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading spending data: $e')),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    final user = _authService.currentUser;
    if (user != null) {
      _loadSpendingData(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Couples Dashboard')),
        body: const Center(child: Text('Please sign in to continue')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couples Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/couples-settings');
            },
            tooltip: 'Couple Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadSpendingData(user.uid),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month selector
                    _buildMonthSelector(theme),
                    const SizedBox(height: 24),

                    // Spending comparison
                    _buildSpendingComparison(theme, user.uid),
                    const SizedBox(height: 24),

                    // Combined total
                    _buildCombinedTotal(theme),
                    const SizedBox(height: 32),

                    // Recent transactions
                    _buildRecentTransactions(theme, user.uid),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    final monthName = _getMonthName(_selectedMonth.month);
    final isCurrentMonth = _selectedMonth.year == DateTime.now().year &&
        _selectedMonth.month == DateTime.now().month;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '$monthName ${_selectedMonth.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth ? Colors.grey : null,
              ),
              onPressed: isCurrentMonth ? null : () => _changeMonth(1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingComparison(ThemeData theme, String currentUserId) {
    if (_coupleAccount == null) return const SizedBox.shrink();

    final partnerId = _coupleAccount!.getPartnerId(currentUserId);
    final partnerUser = partnerId != null ? _coupleAccount!.getUser(partnerId) : null;
    final partnerName = partnerUser?.name ?? 'Partner';

    final totalSpending = _mySpending + _partnerSpending;
    final myPercentage = totalSpending > 0 ? (_mySpending / totalSpending) * 100 : 50.0;
    final partnerPercentage = 100 - myPercentage;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Your spending
            _buildSpendingRow(
              theme,
              'You',
              _mySpending,
              myPercentage,
              Colors.blue,
            ),
            const SizedBox(height: 20),

            // Partner's spending
            _buildSpendingRow(
              theme,
              partnerName,
              _partnerSpending,
              partnerPercentage,
              Colors.pink,
            ),
            const SizedBox(height: 24),

            // Progress bar showing split
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    Expanded(
                      flex: myPercentage.round(),
                      child: Container(color: Colors.blue),
                    ),
                    Expanded(
                      flex: partnerPercentage.round(),
                      child: Container(color: Colors.pink),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingRow(
    ThemeData theme,
    String label,
    double amount,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombinedTotal(ThemeData theme) {
    final totalSpending = _mySpending + _partnerSpending;

    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Combined Spending',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${totalSpending.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
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

  Widget _buildRecentTransactions(ThemeData theme, String currentUserId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_recentTransactions.isEmpty)
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions this month',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentTransactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final transaction = _recentTransactions[index];
              final isMyTransaction = transaction.userId == currentUserId;

              return Card(
                elevation: 1,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isMyTransaction ? Colors.blue : Colors.pink)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      color: isMyTransaction ? Colors.blue : Colors.pink,
                    ),
                  ),
                  title: Text(
                    (transaction.merchant?.isNotEmpty ?? false)
                        ? transaction.merchant!
                        : (transaction.description?.isNotEmpty ?? false ? transaction.description! : 'Transaction'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${isMyTransaction ? 'You' : _getPartnerName(currentUserId)} • ${_formatDate(transaction.date)}',
                  ),
                  trailing: Text(
                    '${transaction.type == models.TransactionType.expense ? '-' : '+'}\$${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.type == models.TransactionType.expense
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _getPartnerName(String currentUserId) {
    if (_coupleAccount == null) return 'Partner';
    final partnerId = _coupleAccount!.getPartnerId(currentUserId);
    if (partnerId == null) return 'Partner';
    final partnerUser = _coupleAccount!.getUser(partnerId);
    return partnerUser?.name ?? 'Partner';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'dining':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.favorite;
      default:
        return Icons.attach_money;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${_getMonthName(date.month)} ${date.day}';
    }
  }
}
