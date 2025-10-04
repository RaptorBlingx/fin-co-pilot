import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              
              // Icon
              const Icon(
                Icons.rocket_launch,
                size: 120,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Welcome to Fin Co-Pilot!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Your AI-powered financial assistant is here to help you:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Features
              _buildFeature(
                icon: Icons.camera_alt,
                title: 'Scan Receipts',
                description: 'Just take a photo, we\'ll handle the rest',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeature(
                icon: Icons.mic,
                title: 'Voice Input',
                description: 'Tell us your expenses naturally',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeature(
                icon: Icons.insights,
                title: 'Smart Insights',
                description: 'AI-powered spending analysis',
              ),
              
              const SizedBox(height: 16),
              
              _buildFeature(
                icon: Icons.shopping_cart,
                title: 'Price Comparison',
                description: 'Find the best deals automatically',
              ),
              
              const Spacer(),
              
              // Continue Button
              ElevatedButton(
                onPressed: () {
                  context.push('/onboarding/currency');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Get Started',
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
  
  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}