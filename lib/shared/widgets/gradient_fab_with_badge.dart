import 'package:flutter/material.dart';
import 'gradient_fab.dart';

class GradientFABWithBadge extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? heroTag;
  final String? tooltip;
  final int badgeCount;
  final Color badgeColor;
  final Color badgeTextColor;

  const GradientFABWithBadge({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
    this.tooltip = 'Add Transaction',
    this.badgeCount = 0,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main FAB
        GradientFAB(
          onPressed: onPressed,
          icon: icon,
          heroTag: heroTag,
          tooltip: tooltip,
        ),
        
        // Badge
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}