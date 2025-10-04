import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/preferences_service.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  Future<void> _handleComplete(BuildContext context) async {
    // Mark onboarding as complete
    await PreferencesService.setOnboardingComplete(true);
    
    if (context.mounted) {
      context.go(AppConstants.routeDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 120,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 48),
              
              // Title
              const Text(
                'You\'re All Set!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Fin Co-Pilot is ready to help you track expenses, '
                'analyze spending, and make smarter financial decisions.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              
              const Spacer(),
              
              // Start Button
              ElevatedButton(
                onPressed: () => _handleComplete(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Start Using Fin Co-Pilot',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}