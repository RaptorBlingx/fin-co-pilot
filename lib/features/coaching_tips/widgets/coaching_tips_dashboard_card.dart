import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/coaching_tips_library_service.dart';
import '../../../models/coaching_tip.dart' as library_model;
import '../screens/coaching_tips_library_screen.dart';

/// Dashboard card showing featured coaching tip
///
/// Displays a random or contextual coaching tip from the library
/// Taps navigate to full coaching tips library
class CoachingTipsDashboardCard extends StatelessWidget {
  const CoachingTipsDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final libraryService = CoachingTipsLibraryService();

    return StreamBuilder<List<library_model.CoachingTip>>(
      stream: libraryService.getHighlyRatedTips(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final tips = snapshot.data!;
        // Show the first highly-rated tip (can randomize later)
        final tip = tips.first;

        return Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachingTipsLibraryScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.purple.shade50,
                    Colors.blue.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Coach\'s Tip',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap to browse 100+ tips',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tip content
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tip.category).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getCategoryColor(tip.category).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tip.category.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getCategoryColor(tip.category),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tip text
                        Text(
                          tip.tip,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Rating
                        if (tip.effectiveness != null)
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  index < tip.effectiveness!.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${tip.effectiveness!.toStringAsFixed(1)} (${tip.usageCount} views)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'budgeting':
        return Colors.blue;
      case 'impulse':
        return Colors.orange;
      case 'savings':
        return Colors.green;
      case 'debt':
        return Colors.red;
      case 'stress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
