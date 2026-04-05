import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../shared/widgets/glass_card.dart';

class SmartSuggestion {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const SmartSuggestion({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class SmartSuggestionCard extends StatelessWidget {
  final SmartSuggestion suggestion;

  const SmartSuggestionCard({super.key, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return GlassCard(
      onTap: () {
        HapticUtils.light();
        suggestion.onTap();
      },
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space16,
        vertical: DesignTokens.space12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: suggestion.color.withOpacity(isDark ? 0.15 : 0.10),
            ),
            child: Icon(
              suggestion.icon,
              size: DesignTokens.iconSM,
              color: suggestion.color,
            ),
          ),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  suggestion.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space8),
          Icon(
            PhosphorIcons.caretRight(),
            size: DesignTokens.iconSM,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
