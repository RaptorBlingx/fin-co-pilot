import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../services/preferences_service.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  Future<void> _handleComplete(BuildContext context) async {
    // Mark onboarding as complete in SharedPreferences
    await PreferencesService.setOnboardingComplete(true);
    
    // CRITICAL: Also mark in Firestore for cross-device persistence
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'onboarding_complete': true});
      print('✅ ONBOARDING: Marked complete in Firestore for user ${user.uid}');
    }
    
    if (context.mounted) {
      context.go(AppConstants.routeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.isDark
                ? [AppTheme.darkBackground, const Color(0xFF0F1A12)]
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
                
                // Success Icon with Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(DesignTokens.space32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.accentEmerald.withOpacity(0.15),
                              AppTheme.accentEmerald.withOpacity(0.05),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                          size: 96,
                          color: AppTheme.accentEmerald,
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: DesignTokens.space40),
                
                // Title
                Text(
                  'You\'re All Set!',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                
                SizedBox(height: DesignTokens.space12),
                
                // Subtitle
                Text(
                  'Fin Co-Pilot is ready to help you track expenses, '
                  'analyze spending, and make smarter financial decisions.',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                
                const Spacer(),
                
                // Start Button
                PremiumButton(
                  onPressed: () => _handleComplete(context),
                  icon: PhosphorIcons.rocketLaunch(),
                  child: const Text('Start Using Fin Co-Pilot'),
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