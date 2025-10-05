import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _budgetAlerts = true;
  bool _spendingInsights = true;
  bool _priceDrops = false;
  bool _weeklySummary = true;
  String _preferredTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data != null && data['notification_settings'] != null) {
        final settings = data['notification_settings'] as Map<String, dynamic>;
        setState(() {
          _notificationsEnabled = settings['enabled'] ?? true;
          _budgetAlerts = settings['budget_alerts'] ?? true;
          _spendingInsights = settings['spending_insights'] ?? true;
          _priceDrops = settings['price_drops'] ?? false;
          _weeklySummary = settings['weekly_summary'] ?? true;
          _preferredTime = settings['preferred_time'] ?? '09:00';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'notification_settings': {
          'enabled': _notificationsEnabled,
          'budget_alerts': _budgetAlerts,
          'spending_insights': _spendingInsights,
          'price_drops': _priceDrops,
          'weekly_summary': _weeklySummary,
          'preferred_time': _preferredTime,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          // Master toggle
          SwitchListTile(
            title: const Text(
              'Enable Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Receive alerts and insights'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSettings();
            },
            secondary: const Icon(Icons.notifications_active),
          ),

          const Divider(),

          // Notification types
          Opacity(
            opacity: _notificationsEnabled ? 1.0 : 0.5,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                    'Notification Types',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

                SwitchListTile(
                  title: const Text('Budget Alerts'),
                  subtitle: const Text('Get notified when approaching budget limits'),
                  value: _budgetAlerts,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _budgetAlerts = value);
                          _saveSettings();
                        }
                      : null,
                  secondary: const Icon(Icons.account_balance_wallet),
                ),

                SwitchListTile(
                  title: const Text('Spending Insights'),
                  subtitle: const Text('Weekly tips and spending analysis'),
                  value: _spendingInsights,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _spendingInsights = value);
                          _saveSettings();
                        }
                      : null,
                  secondary: const Icon(Icons.lightbulb_outline),
                ),

                SwitchListTile(
                  title: const Text('Price Drop Alerts'),
                  subtitle: const Text('Get notified when tracked items go on sale'),
                  value: _priceDrops,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _priceDrops = value);
                          _saveSettings();
                        }
                      : null,
                  secondary: const Icon(Icons.trending_down),
                ),

                SwitchListTile(
                  title: const Text('Weekly Summary'),
                  subtitle: const Text('Recap of your spending every week'),
                  value: _weeklySummary,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _weeklySummary = value);
                          _saveSettings();
                        }
                      : null,
                  secondary: const Icon(Icons.calendar_today),
                ),
              ],
            ),
          ),

          const Divider(),

          // Preferred time
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Preferred Time'),
            subtitle: Text('Receive daily notifications at $_preferredTime'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _notificationsEnabled ? _selectPreferredTime : null,
            ),
          ),

          const Divider(),

          // Notification history
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Notification History'),
            subtitle: const Text('View past notifications'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showNotificationHistory(),
          ),

          // Test notification
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Send Test Notification'),
            subtitle: const Text('Check if notifications are working'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _notificationsEnabled ? _sendTestNotification : null,
          ),

          // Clear all
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text(
              'Clear All Notifications',
              style: TextStyle(color: Colors.red),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _clearAllNotifications,
          ),

          const SizedBox(height: 16),

          // Info card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'About Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Notifications help you stay on track with your financial goals. '
                      'We\'ll only send relevant alerts based on your spending patterns.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPreferredTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_preferredTime.split(':')[0]),
        minute: int.parse(_preferredTime.split(':')[1]),
      ),
    );

    if (picked != null) {
      setState(() {
        _preferredTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _saveSettings();
    }
  }

  Future<void> _sendTestNotification() async {
    await _notificationService.sendMilestoneNotification(
      title: '🎉 Test Notification',
      body: 'Notifications are working correctly! Your FinCoPilot is ready to help you stay on track.',
      milestoneType: 'test',
      achievementData: {
        'type': 'test_notification',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showNotificationHistory() {
    final user = _authService.currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _NotificationHistoryScreen(userId: user.uid),
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will clear your notification history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.cancelAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

// Notification History Screen
class _NotificationHistoryScreen extends StatelessWidget {
  final String userId;

  const _NotificationHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your notification history will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp?.toDate();

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForType(data['type']).withOpacity(0.1),
                    child: Icon(
                      _getIconForType(data['type']),
                      color: _getColorForType(data['type']),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: data['read'] == true
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['body'] ?? ''),
                      const SizedBox(height: 4),
                      if (date != null)
                        Text(
                          '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11, 
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  trailing: data['read'] != true
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () async {
                    if (data['read'] != true) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(doc.id)
                          .update({'read': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'budget_alert':
        return Icons.account_balance_wallet;
      case 'coaching_tip':
        return Icons.lightbulb;
      case 'price_alert':
        return Icons.trending_down;
      case 'milestone':
        return Icons.emoji_events;
      case 'test':
        return Icons.science;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'budget_alert':
        return Colors.orange;
      case 'coaching_tip':
        return Colors.green;
      case 'price_alert':
        return Colors.blue;
      case 'milestone':
        return Colors.purple;
      case 'test':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}