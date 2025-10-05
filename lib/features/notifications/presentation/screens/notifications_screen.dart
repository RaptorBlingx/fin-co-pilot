import 'package:flutter/material.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/budget_monitoring_service.dart';
import '../../../../services/coaching_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final BudgetMonitoringService _budgetMonitoring = BudgetMonitoringService();
  final CoachingService _coachingService = CoachingService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Push Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildNotificationSection(
              title: '💰 Budget Alerts',
              description: 'Stay on top of your spending with smart budget notifications',
              color: Colors.red,
              actions: [
                _buildActionButton(
                  'Test Budget Alert',
                  Icons.warning,
                  Colors.orange,
                  () => _testBudgetAlert(),
                ),
                _buildActionButton(
                  'Check Budget Status',
                  Icons.analytics,
                  Colors.blue,
                  () => _checkBudgetStatus(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNotificationSection(
              title: '💡 Coaching Tips',
              description: 'Daily personalized financial advice and insights',
              color: Colors.green,
              actions: [
                _buildActionButton(
                  'Send Daily Tip',
                  Icons.lightbulb,
                  Colors.amber,
                  () => _sendCoachingTip(),
                ),
                _buildActionButton(
                  'Weekly Report',
                  Icons.report,
                  Colors.purple,
                  () => _sendWeeklyReport(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNotificationSection(
              title: '🏆 Achievements',
              description: 'Celebrate your financial milestones and streaks',
              color: Colors.purple,
              actions: [
                _buildActionButton(
                  'Test Milestone',
                  Icons.emoji_events,
                  Colors.amber,
                  () => _testMilestone(),
                ),
                _buildActionButton(
                  'Check Milestones',
                  Icons.track_changes,
                  Colors.indigo,
                  () => _checkMilestones(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildNotificationSection(
              title: '🏷️ Price Alerts',
              description: 'Get notified when prices drop on items you\'re tracking',
              color: Colors.orange,
              actions: [
                _buildActionButton(
                  'Test Price Drop',
                  Icons.trending_down,
                  Colors.green,
                  () => _testPriceAlert(),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildTokenInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'M14: Push Notifications',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Smart financial notifications to keep you informed and motivated on your money management journey.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required String description,
    required Color color,
    required List<Widget> actions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(Icons.notifications, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
      ),
    );
  }

  Widget _buildTokenInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📱 Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  _notificationService.isInitialized 
                    ? 'Notification Service: Initialized' 
                    : 'Notification Service: Not Initialized',
                  style: TextStyle(
                    color: _notificationService.isInitialized ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.token, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _notificationService.fcmToken != null 
                      ? 'FCM Token: ${_notificationService.fcmToken!.substring(0, 20)}...'
                      : 'FCM Token: Not available',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Demo actions
  void _testBudgetAlert() async {
    await _notificationService.sendBudgetAlert(
      title: '⚠️ Budget Alert - Demo',
      body: 'You\'ve used 85% of your Food budget. \$45.50 remaining this month.',
      category: 'Food',
      amount: 254.50,
      budgetLimit: 300.00,
    );
    _showSnackBar('Budget alert sent!');
  }

  void _checkBudgetStatus() async {
    await _budgetMonitoring.checkBudgetAlerts();
    _showSnackBar('Budget status checked!');
  }

  void _sendCoachingTip() async {
    await _coachingService.sendDailyCoachingTip();
    _showSnackBar('Coaching tip sent!');
  }

  void _sendWeeklyReport() async {
    await _coachingService.sendWeeklyReport();
    _showSnackBar('Weekly report sent!');
  }

  void _testMilestone() async {
    await _notificationService.sendMilestoneNotification(
      title: '🏆 Achievement Unlocked!',
      body: 'Congratulations! You\'ve completed 7 days of staying under budget!',
      milestoneType: 'spending_streak',
      achievementData: {
        'streak': 7,
        'type': 'budget_streak',
        'achievedAt': DateTime.now().toIso8601String(),
      },
    );
    _showSnackBar('Milestone notification sent!');
  }

  void _checkMilestones() async {
    await _budgetMonitoring.checkSpendingMilestones();
    _showSnackBar('Milestones checked!');
  }

  void _testPriceAlert() async {
    await _notificationService.sendPriceAlert(
      title: '🏷️ Price Drop Alert!',
      body: 'Great news! The iPhone 15 Pro you\'re tracking dropped from \$999 to \$899!',
      itemName: 'iPhone 15 Pro',
      oldPrice: 999.00,
      newPrice: 899.00,
    );
    _showSnackBar('Price alert sent!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}