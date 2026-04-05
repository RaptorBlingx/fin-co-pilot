import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/haptic_utils.dart';
import '../../shared/widgets/gradient_fab.dart';
import '../navigation/page_transitions.dart';

// Import screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/insights/presentation/screens/insights_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/financial_copilot/presentation/screens/financial_copilot_screen.dart';

/// Provider for managing the selected navigation tab
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Main app navigation widget with M3 NavigationBar + glass treatment.
class AppNavigation extends ConsumerWidget {
  const AppNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final List<Widget> screens = [
      const DashboardScreen(),
      const TransactionsScreen(),
      const InsightsScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      floatingActionButton: GradientFAB(
        onPressed: () {
          HapticUtils.medium();
          context.pushWithSlideUp(const FinancialCopilotScreen());
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withOpacity(0.85)
                  : Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                HapticUtils.light();
                ref.read(selectedIndexProvider.notifier).state = index;
              },
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: colors.primary.withOpacity(0.12),
              height: DesignTokens.bottomNavHeight,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                NavigationDestination(
                  icon: Icon(AppIcons.dashboard, size: DesignTokens.iconMD),
                  selectedIcon: Icon(AppIcons.dashboardFilled, size: DesignTokens.iconMD),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.transactions, size: DesignTokens.iconMD),
                  selectedIcon: Icon(AppIcons.transactionsFilled, size: DesignTokens.iconMD),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.insights, size: DesignTokens.iconMD),
                  selectedIcon: Icon(AppIcons.insightsFilled, size: DesignTokens.iconMD),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.more, size: DesignTokens.iconMD),
                  selectedIcon: Icon(AppIcons.moreFilled, size: DesignTokens.iconMD),
                  label: 'More',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}