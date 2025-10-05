import 'package:flutter/material.dart';
import '../../../../services/transaction_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../shared/models/transaction.dart' as model;
import '../../../../core/utils/currency_utils.dart';
import 'add_transaction_screen.dart';
import 'transaction_detail_screen.dart';
import '../widgets/category_filter.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final transactionService = TransactionService();
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Add search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          CategoryFilter(
            selectedCategory: _selectedCategory,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),

          const Divider(height: 1),

          // Transactions list
          Expanded(
            child: StreamBuilder<List<model.Transaction>>(
              stream: transactionService.getTransactions(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var transactions = snapshot.data ?? [];

                // Filter by category if selected
                if (_selectedCategory != null) {
                  transactions = transactions
                      .where((t) => t.category == _selectedCategory)
                      .toList();
                }

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory != null
                              ? 'No $_selectedCategory transactions'
                              : 'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddTransactionScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            _selectedCategory != null
                                ? 'Add $_selectedCategory transaction'
                                : 'Add Your First Transaction',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate total for filtered transactions
                final total = transactions.fold<double>(
                  0,
                  (sum, transaction) => sum + transaction.amount,
                );

                return Column(
                  children: [
                    // Summary card
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCategory != null
                                    ? '${_selectedCategory![0].toUpperCase()}${_selectedCategory!.substring(1)} Total'
                                    : 'Total Spending',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyUtils.formatAmount(
                                  total,
                                  transactions.first.currency,
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transaction list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return _TransactionTile(transaction: transaction);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final model.Transaction transaction;

  const _TransactionTile({required this.transaction});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'dining':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.health_and_safety;
      case 'bills':
        return Icons.receipt;
      case 'education':
        return Icons.school;
      case 'travel':
        return Icons.flight;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'groceries':
        return Colors.green;
      case 'dining':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'health':
        return Colors.red;
      case 'bills':
        return Colors.brown;
      case 'education':
        return Colors.indigo;
      case 'travel':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                transaction: transaction,
              ),
            ),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getCategoryColor(transaction.category).withOpacity(0.1),
            child: Icon(
              _getCategoryIcon(transaction.category),
              color: _getCategoryColor(transaction.category),
            ),
          ),
          title: Text(
            transaction.merchant ?? transaction.description ?? 'Transaction',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${transaction.category} • ${_formatDate(transaction.transactionDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: Text(
            CurrencyUtils.formatAmount(transaction.amount, transaction.currency),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}