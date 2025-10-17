import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/gradient_fab.dart';

// Import your existing screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/add_transaction/presentation/add_transaction_screen.dart' as conversational;

// Navigation State Provider
final currentTabIndexProvider = StateProvider<int>((ref) => 0);

class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(currentTabIndexProvider);
    
    // Define your screens for each tab
    final screens = [
      const DashboardScreen(),           // Tab 0: Home
      const _PlaceholderScreen(                // Tab 1: Transactions (will be created later)
        title: 'Transactions', 
        icon: Icons.receipt_long,
      ),
      const SizedBox.shrink(),              // Tab 2: Empty (Add via FAB only)
      const InsightsScreen(),            // Tab 3: Insights (analytics & charts)
      const MoreScreen(),                // Tab 4: More
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      
      // FLOATING ACTION BUTTON
      floatingActionButton: GradientFAB(
        onPressed: () {
          // Navigate to Add Transaction screen (conversational UI)
          _showAddTransactionModal(context);
        },
        icon: Icons.add_rounded,
        tooltip: 'Add Transaction',
      ),
      
      // Position FAB
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      // Bottom Navigation
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // Don't navigate to index 2 (Add tab) via bottom nav
          // User should use FAB instead
          if (index != 2) {
            ref.read(currentTabIndexProvider.notifier).state = index;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
            // This tab is handled by FAB - navigation blocked in onDestinationSelected
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
  
  void _showAddTransactionModal(BuildContext context) {
    // OPTION 1: Full-screen modal (recommended for conversational UI)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const conversational.AddTransactionScreen(),
        fullscreenDialog: true,
      ),
    );
    
    // OPTION 2: Bottom sheet (alternative)
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => const AddTransactionBottomSheet(),
    // );
  }
}

// Old placeholder removed - now using the real conversational AddTransactionScreen

// Temporary placeholder widget
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  
  const _PlaceholderScreen({
    required this.title,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Screen coming soon',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}