import 'package:flutter/material.dart';

class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;

  const QuickActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor ?? colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor ?? colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: QuickActionButton(
            title: 'Reports',
            icon: Icons.analytics_rounded,
            onTap: () {
              Navigator.pushNamed(context, '/reports');
            },
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            iconColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: QuickActionButton(
            title: 'Shopping',
            icon: Icons.shopping_bag_rounded,
            onTap: () {
              Navigator.pushNamed(context, '/shopping');
            },
            backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            iconColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}