import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/app_initializer.dart';
import '../../../services/sms/sms_listener_service.dart';

/// SMS Permission Screen (Onboarding Step 3)
///
/// Week 2 Killer Feature: SMS Auto-Parsing
/// - Explains 80% automatic capture benefit
/// - Shows example SMS notification
/// - Requests SMS permissions
/// - Starts background listener on grant
///
/// Design: Beautiful, trustworthy, anxiety-reducing
class SmsPermissionScreen extends ConsumerStatefulWidget {
  const SmsPermissionScreen({super.key});

  @override
  ConsumerState<SmsPermissionScreen> createState() =>
      _SmsPermissionScreenState();
}

class _SmsPermissionScreenState extends ConsumerState<SmsPermissionScreen>
    with SingleTickerProviderStateMixin {
  final SmsListenerService _smsService = SmsListenerService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Progress indicator
                  _buildProgressIndicator(theme),

                  const SizedBox(height: 32),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          _buildIconHeader(theme),

                          const SizedBox(height: 32),

                          // Title
                          Text(
                            'Zero-Effort Tracking',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Subtitle
                          Text(
                            'Let Fin Copilot automatically capture 80% of your spending from bank SMS alerts.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Example notification card
                          _buildExampleNotification(theme),

                          const SizedBox(height: 32),

                          // Benefits list
                          _buildBenefitsList(theme),

                          const SizedBox(height: 24),

                          // Privacy note
                          _buildPrivacyNote(theme),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Row(
      children: [
        // Step 1 (completed)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: theme.colorScheme.primary,
          ),
        ),

        // Step 2 (completed)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: theme.colorScheme.primary,
          ),
        ),

        // Step 3 (current)
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primaryContainer,
              width: 3,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),

        // Step 4 (upcoming)
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.outline.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildIconHeader(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.sms_outlined,
        size: 40,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildExampleNotification(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notification_important,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Transaction Detected',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🍽️ \$5.50 at Starbucks - Coffee?',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                  ),
                  child: const Text('YES'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                  child: const Text('NO'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final benefits = [
      {
        'icon': Icons.auto_awesome,
        'title': '80% Automatic Capture',
        'desc': 'No more manual entry for most transactions',
      },
      {
        'icon': Icons.speed,
        'title': 'Instant Processing',
        'desc': 'Get notifications in under 2 seconds',
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'One-Tap Confirmation',
        'desc': 'Just tap YES or NO - that\'s it!',
      },
      {
        'icon': Icons.security,
        'title': 'Private & Secure',
        'desc': 'All processing happens on your device',
      },
    ];

    return Column(
      children: benefits
          .map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        benefit['icon'] as IconData,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit['title'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            benefit['desc'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPrivacyNote(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We only read bank transaction alerts. No personal messages are ever accessed or stored.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleEnableSmsCapture,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enable Auto-Capture',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : _handleSkip,
          child: Text(
            'Skip for now',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEnableSmsCapture() async {
    setState(() => _isLoading = true);

    try {
      // Check if permissions are already granted
      final hasPermissions = await _smsService.hasPermissions();

      if (hasPermissions) {
        // Permissions already granted, initialize service
        final success = await _initializeSmsService();
        if (success) {
          _navigateNext();
        }
      } else {
        // Request permissions
        final granted = await _smsService.hasPermissions();

        if (granted) {
          // Initialize service
          final success = await _initializeSmsService();
          if (success) {
            _navigateNext();
          }
        } else {
          // Permission denied
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _initializeSmsService() async {
    // Use AppInitializer to enable SMS auto-parsing
    // This will update user preferences and start the listener
    final appInitializer = AppInitializer();
    return await appInitializer.enableSmsAutoParsing();
  }

  void _handleSkip() {
    _navigateNext();
  }

  void _navigateNext() {
    // Navigate to next onboarding step or home
    context.go('/onboarding/complete');
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'SMS permission is required to automatically capture your transactions. '
          'You can enable it later in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSkip();
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleEnableSmsCapture();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Something went wrong'),
        content: const Text(
          'We couldn\'t enable SMS auto-capture. You can try again later in Settings.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSkip();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
