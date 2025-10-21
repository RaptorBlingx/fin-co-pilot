import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/gradient_fab.dart';

// Import your existing screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/financial_copilot/presentation/screens/financial_copilot_screen.dart';

/// Provider for managing the selected navigation tab
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Main app navigation widget with 4-tab bottom navigation
/// 
/// ARCHITECTURE DECISION: Changed from 5-tab to 4-tab layout
/// - Removed disabled "Add" tab (was causing UX confusion)
/// - FAB handles all "Add Transaction" functionality
/// - Cleaner, more premium feel
class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    // 4 main screens - NO PLACEHOLDERS
    final List<Widget> screens = [
      const DashboardScreen(),        // Tab 0: Home
      const TransactionsScreen(),      // Tab 1: Transactions (FIXED - using real screen)
      const InsightsScreen(),          // Tab 2: Insights
      const MoreScreen(),              // Tab 3: More
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      // Global FAB - accessible from all tabs
      floatingActionButton: GradientFAB(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FinancialCopilotScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        icon: Icons.auto_awesome,
        tooltip: 'Fin Copilot',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}