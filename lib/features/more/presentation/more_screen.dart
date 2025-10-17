import 'package:flutter/material.dart';
import '../../reports/presentation/screens/reports_screen.dart';
import '../../shopping/presentation/screens/shopping_screen.dart';
import '../../coaching/presentation/screens/coaching_screen.dart';
import '../../settings/presentation/screens/settings_screen.dart';
import '../../settings/presentation/screens/notification_settings_screen.dart';
import '../../price_intelligence/presentation/price_intelligence_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Features',
            items: [
              _MenuItem(
                icon: Icons.analytics_outlined,
                title: 'Price Intelligence',
                subtitle: 'Track items & predict purchases',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PriceIntelligenceScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.assessment_outlined,
                title: 'Reports',
                subtitle: 'Monthly summaries & exports',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.shopping_bag_outlined,
                title: 'Shopping',
                subtitle: 'Price comparison & deals',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShoppingScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.psychology_outlined,
                title: 'Coach',
                subtitle: 'AI financial advisor',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CoachingScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Settings',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Account',
                subtitle: 'Profile & preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Alerts & reminders',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Theme & display',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'FAQs & contact us',
                onTap: () {
                  // TODO: Create Help screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon!')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Fin Co-Pilot v1.0.0',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Card(
          child: Column(
            children: items.map((item) => _buildMenuItem(context, item)).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuItem(BuildContext context, _MenuItem item) {
    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      subtitle: Text(item.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}