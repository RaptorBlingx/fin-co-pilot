import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/premium_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDark
                ? [AppTheme.darkBackground, const Color(0xFF1A1040)]
                : [AppTheme.slate50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.rocketLaunch(PhosphorIconsStyle.duotone),
                    size: 48,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: DesignTokens.durationSlow).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  curve: DesignTokens.curveDecelerate,
                ),
                
                SizedBox(height: DesignTokens.space24),
                
                // Title
                Text(
                  'Welcome to Fin Co-Pilot!',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                
                SizedBox(height: DesignTokens.space12),
                
                // Subtitle
                Text(
                  'Your AI-powered financial assistant is here to help you:',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 250.ms),
                
                SizedBox(height: DesignTokens.space32),
                
                // Features
                ...[
                  _FeatureItem(
                    icon: PhosphorIcons.camera(PhosphorIconsStyle.duotone),
                    color: AppTheme.primaryIndigo,
                    title: 'Scan Receipts',
                    description: 'Just take a photo, we\'ll handle the rest',
                  ),
                  _FeatureItem(
                    icon: PhosphorIcons.microphone(PhosphorIconsStyle.duotone),
                    color: AppTheme.accentPurple,
                    title: 'Voice Input',
                    description: 'Tell us your expenses naturally',
                  ),
                  _FeatureItem(
                    icon: PhosphorIcons.chartLineUp(PhosphorIconsStyle.duotone),
                    color: AppTheme.accentEmerald,
                    title: 'Smart Insights',
                    description: 'AI-powered spending analysis',
                  ),
                  _FeatureItem(
                    icon: PhosphorIcons.shoppingCart(PhosphorIconsStyle.duotone),
                    color: AppTheme.amber500,
                    title: 'Price Comparison',
                    description: 'Find the best deals automatically',
                  ),
                ].asMap().entries.map((entry) => Padding(
                  padding: EdgeInsets.only(bottom: DesignTokens.space12),
                  child: entry.value,
                ).animate().fadeIn(delay: (350 + entry.key * 100).ms).slideX(begin: -0.1, end: 0)),
                
                const Spacer(),
                
                // Continue Button
                PremiumButton(
                  onPressed: () {
                    context.push('/onboarding/currency');
                  },
                  child: const Text('Get Started'),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                
                SizedBox(height: DesignTokens.space16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Icon(icon, color: color, size: DesignTokens.iconMD),
        ),
        SizedBox(width: DesignTokens.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: DesignTokens.space2),
              Text(
                description,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}