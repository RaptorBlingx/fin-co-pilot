import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/models/product_price_data.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../services/preferences_service.dart';

/// Wishlist Management Screen - Full CRUD with Premium Features
///
/// Features:
/// - Add/Remove products
/// - Set/Edit target prices
/// - Enable/Disable alerts
/// - Priority levels (High/Medium/Low)
/// - Organize by categories
/// - Share wishlist
/// - Filter and sort
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String? _userId;
  List<WatchlistItemWithPriority> _items = [];
  bool _isLoading = true;

  // Filters
  String _sortBy = 'added_date'; // added_date, price, name, priority
  String _filterPriority = 'all'; // all, high, medium, low
  bool _showOnlyPriceDrops = false;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _loadWatchlist();
  }

  Future<void> _loadWatchlist() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('watchlist')
          .where('user_id', isEqualTo: _userId)
          .get();

      _items = snapshot.docs
          .map((doc) => WatchlistItemWithPriority.fromFirestore(doc))
          .toList();

      _applySortAndFilter();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wishlist: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySortAndFilter() {
    // Filter by priority
    var filteredItems = _items;
    if (_filterPriority != 'all') {
      filteredItems = filteredItems
          .where((item) => item.priority.toLowerCase() == _filterPriority)
          .toList();
    }

    // Filter by price drops
    if (_showOnlyPriceDrops) {
      filteredItems = filteredItems
          .where((item) => item.item.isPriceBelowTarget)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price':
        filteredItems.sort((a, b) =>
            a.item.currentPrice.compareTo(b.item.currentPrice));
        break;
      case 'name':
        filteredItems.sort((a, b) =>
            a.item.productName.compareTo(b.item.productName));
        break;
      case 'priority':
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        filteredItems.sort((a, b) =>
            priorityOrder[a.priority.toLowerCase()]!
                .compareTo(priorityOrder[b.priority.toLowerCase()]!));
        break;
      case 'added_date':
      default:
        filteredItems.sort((a, b) =>
            b.item.addedAt.compareTo(a.item.addedAt));
        break;
    }

    setState(() {
      _items = filteredItems;
    });
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await FirebaseFirestore.instance
          .collection('watchlist')
          .doc(itemId)
          .delete();

      HapticUtils.success();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from wishlist')),
        );
      }

      await _loadWatchlist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  Future<void> _toggleAlert(WatchlistItemWithPriority itemWithPriority) async {
    try {
      await FirebaseFirestore.instance
          .collection('watchlist')
          .doc(itemWithPriority.item.id)
          .update({
        'alertEnabled': !itemWithPriority.item.alertEnabled,
      });

      HapticUtils.light();
      await _loadWatchlist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling alert: $e')),
        );
      }
    }
  }

  void _showEditDialog(WatchlistItemWithPriority itemWithPriority) {
    showDialog(
      context: context,
      builder: (context) => _EditWishlistItemDialog(
        item: itemWithPriority,
        onSave: () async {
          await _loadWatchlist();
        },
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter & Sort',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Sort By
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Date Added', 'added_date', _sortBy,
                    (value) => setState(() => _sortBy = value)),
                _buildFilterChip('Price', 'price', _sortBy,
                    (value) => setState(() => _sortBy = value)),
                _buildFilterChip('Name', 'name', _sortBy,
                    (value) => setState(() => _sortBy = value)),
                _buildFilterChip('Priority', 'priority', _sortBy,
                    (value) => setState(() => _sortBy = value)),
              ],
            ),

            const SizedBox(height: 24),

            // Priority Filter
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All', 'all', _filterPriority,
                    (value) => setState(() => _filterPriority = value)),
                _buildFilterChip('High', 'high', _filterPriority,
                    (value) => setState(() => _filterPriority = value)),
                _buildFilterChip('Medium', 'medium', _filterPriority,
                    (value) => setState(() => _filterPriority = value)),
                _buildFilterChip('Low', 'low', _filterPriority,
                    (value) => setState(() => _filterPriority = value)),
              ],
            ),

            const SizedBox(height: 24),

            // Price Drops Only
            SwitchListTile(
              title: const Text('Show Only Price Drops'),
              value: _showOnlyPriceDrops,
              onChanged: (value) {
                setState(() => _showOnlyPriceDrops = value);
              },
            ),

            const SizedBox(height: 16),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applySortAndFilter();
                  HapticUtils.success();
                },
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String currentValue,
    Function(String) onSelected,
  ) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(value);
          HapticUtils.light();
        }
      },
    );
  }

  Future<void> _shareWishlist() async {
    try {
      final text = StringBuffer();
      text.writeln('My Wishlist:');
      text.writeln();

      for (final item in _items) {
        text.writeln(
            '${item.item.productName} - \$${item.item.currentPrice.toStringAsFixed(2)}');
        text.writeln('Target: \$${item.item.targetPrice.toStringAsFixed(2)}');
        text.writeln();
      }

      await Share.share(text.toString(), subject: 'My Price Finder Wishlist');
      HapticUtils.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing wishlist: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
            tooltip: 'Filter & Sort',
          ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareWishlist,
              tooltip: 'Share Wishlist',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadWatchlist,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildWishlistCard(_items[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Your wishlist is empty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start adding products to track their prices',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(WatchlistItemWithPriority itemWithPriority) {
    final item = itemWithPriority.item;
    final isPriceTarget = item.isPriceBelowTarget;
    final priorityColor = _getPriorityColor(itemWithPriority.priority);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove Item'),
            content: Text('Remove "${item.productName}" from wishlist?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteItem(item.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isPriceTarget ? Colors.green : priorityColor,
            width: isPriceTarget ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () async {
            HapticUtils.light();
            // Navigate to product detail (future implementation)
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    if (item.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag, size: 32),
                      ),

                    const SizedBox(width: 12),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Priority Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  itemWithPriority.priority.toUpperCase(),
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              if (isPriceTarget) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green[700],
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'TARGET',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Product Name
                          Text(
                            item.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // Current Price
                          Row(
                            children: [
                              Text(
                                '\$${item.currentPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isPriceTarget
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (item.savingsFromTarget != 0) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  isPriceTarget
                                      ? Icons.trending_down
                                      : Icons.trending_up,
                                  color: isPriceTarget
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                  size: 16,
                                ),
                                Text(
                                  '${item.savingsPercentage.abs().toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: isPriceTarget
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Target Price
                          Text(
                            'Target: \$${item.targetPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            _showEditDialog(itemWithPriority);
                            break;
                          case 'toggle_alert':
                            await _toggleAlert(itemWithPriority);
                            break;
                          case 'delete':
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove Item'),
                                content: Text(
                                    'Remove "${item.productName}" from wishlist?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _deleteItem(item.id);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_alert',
                          child: Row(
                            children: [
                              Icon(item.alertEnabled
                                  ? Icons.notifications_off
                                  : Icons.notifications),
                              const SizedBox(width: 8),
                              Text(item.alertEnabled
                                  ? 'Disable Alerts'
                                  : 'Enable Alerts'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Alert Status
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.alertEnabled
                        ? Colors.blue[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.alertEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        size: 16,
                        color: item.alertEnabled ? Colors.blue[700] : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.alertEnabled
                            ? 'Price alerts enabled'
                            : 'Price alerts disabled',
                        style: TextStyle(
                          color: item.alertEnabled ? Colors.blue[700] : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

/// Extended WatchlistItem with priority
class WatchlistItemWithPriority {
  final WatchlistItem item;
  final String priority; // high, medium, low
  final String? category;
  final String? notes;

  WatchlistItemWithPriority({
    required this.item,
    this.priority = 'medium',
    this.category,
    this.notes,
  });

  factory WatchlistItemWithPriority.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WatchlistItemWithPriority(
      item: WatchlistItem.fromFirestore(doc),
      priority: data['priority'] as String? ?? 'medium',
      category: data['category'] as String?,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      ...item.toFirestore(),
      'priority': priority,
      'category': category,
      'notes': notes,
    };
  }
}

/// Edit Wishlist Item Dialog
class _EditWishlistItemDialog extends StatefulWidget {
  final WatchlistItemWithPriority item;
  final VoidCallback onSave;

  const _EditWishlistItemDialog({
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditWishlistItemDialog> createState() =>
      _EditWishlistItemDialogState();
}

class _EditWishlistItemDialogState extends State<_EditWishlistItemDialog> {
  late TextEditingController _targetPriceController;
  late TextEditingController _notesController;
  late String _priority;
  late bool _alertEnabled;

  @override
  void initState() {
    super.initState();
    _targetPriceController = TextEditingController(
      text: widget.item.item.targetPrice.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: widget.item.notes ?? '');
    _priority = widget.item.priority;
    _alertEnabled = widget.item.item.alertEnabled;
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final targetPrice = double.tryParse(_targetPriceController.text);

    if (targetPrice == null || targetPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target price')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('watchlist')
          .doc(widget.item.item.id)
          .update({
        'targetPrice': targetPrice,
        'priority': _priority,
        'alertEnabled': _alertEnabled,
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      });

      HapticUtils.success();

      if (!mounted) return;

      Navigator.pop(context);
      widget.onSave();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wishlist item updated')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Wishlist Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            Text(
              widget.item.item.productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),

            // Target Price
            TextField(
              controller: _targetPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Price',
                prefixText: '${CurrencyUtils.getCurrencySymbol(PreferencesService.getCurrency() ?? 'USD')} ',
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'high',
                  label: Text('High'),
                  icon: Icon(Icons.priority_high),
                ),
                ButtonSegment(
                  value: 'medium',
                  label: Text('Medium'),
                  icon: Icon(Icons.remove),
                ),
                ButtonSegment(
                  value: 'low',
                  label: Text('Low'),
                  icon: Icon(Icons.low_priority),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _priority = newSelection.first;
                });
                HapticUtils.light();
              },
            ),

            const SizedBox(height: 16),

            // Alert Toggle
            SwitchListTile(
              title: const Text('Enable Price Alerts'),
              subtitle: const Text('Get notified when price drops'),
              value: _alertEnabled,
              onChanged: (value) {
                setState(() {
                  _alertEnabled = value;
                });
                HapticUtils.light();
              },
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Add personal notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
