import 'package:flutter/material.dart';

/// Beautiful error state widget with retry functionality
///
/// Shows helpful error messages with recovery options
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final ErrorType errorType;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.retryLabel = 'Try Again',
    this.onRetry,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.errorType = ErrorType.generic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIcon = icon ?? _getIconForErrorType(errorType);
    final effectiveColor = _getColorForErrorType(errorType, theme);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: effectiveColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      effectiveIcon,
                      size: 80,
                      color: effectiveColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Actions
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: effectiveColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
      case ErrorType.permission:
        return Icons.lock_outline_rounded;
      case ErrorType.timeout:
        return Icons.timer_off_rounded;
      case ErrorType.generic:
      default:
        return Icons.error_outline_rounded;
    }
  }

  Color _getColorForErrorType(ErrorType type, ThemeData theme) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.permission:
        return Colors.amber;
      case ErrorType.timeout:
        return Colors.deepOrange;
      case ErrorType.generic:
      default:
        return theme.colorScheme.error;
    }
  }
}

enum ErrorType {
  generic,
  network,
  server,
  notFound,
  permission,
  timeout,
}

/// Predefined error states for common scenarios
class ErrorStates {
  // Network error
  static Widget networkError(BuildContext context, VoidCallback onRetry) {
    return ErrorStateWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again',
      errorType: ErrorType.network,
      onRetry: onRetry,
    );
  }

  // Server error
  static Widget serverError(BuildContext context, VoidCallback onRetry) {
    return ErrorStateWidget(
      title: 'Something Went Wrong',
      message: 'We\'re having trouble connecting to our servers. Please try again in a moment',
      errorType: ErrorType.server,
      onRetry: onRetry,
    );
  }

  // Not found
  static Widget notFound(BuildContext context, {VoidCallback? onGoBack}) {
    return ErrorStateWidget(
      title: 'Not Found',
      message: 'The item you\'re looking for doesn\'t exist or has been removed',
      errorType: ErrorType.notFound,
      retryLabel: 'Go Back',
      onRetry: onGoBack,
    );
  }

  // Permission denied
  static Widget permissionDenied(
    BuildContext context, {
    required String permissionName,
    VoidCallback? onOpenSettings,
  }) {
    return ErrorStateWidget(
      title: 'Permission Required',
      message: 'We need $permissionName permission to continue. Please enable it in your device settings',
      errorType: ErrorType.permission,
      retryLabel: 'Open Settings',
      onRetry: onOpenSettings,
    );
  }

  // Timeout error
  static Widget timeout(BuildContext context, VoidCallback onRetry) {
    return ErrorStateWidget(
      title: 'Request Timeout',
      message: 'The request took too long to complete. Please try again',
      errorType: ErrorType.timeout,
      onRetry: onRetry,
    );
  }

  // Generic error
  static Widget generic(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    return ErrorStateWidget(
      title: 'Oops!',
      message: message,
      errorType: ErrorType.generic,
      onRetry: onRetry,
    );
  }

  // SMS permission denied (specific to app)
  static Widget smsPermissionDenied(
    BuildContext context,
    VoidCallback onOpenSettings,
  ) {
    return ErrorStateWidget(
      title: 'SMS Permission Required',
      message: 'We need SMS permission to automatically track your bank transactions. Enable it in settings for the best experience',
      errorType: ErrorType.permission,
      retryLabel: 'Open Settings',
      onRetry: onOpenSettings,
      secondaryActionLabel: 'Continue Without SMS',
      onSecondaryAction: () => Navigator.pop(context),
    );
  }

  // Camera permission denied
  static Widget cameraPermissionDenied(
    BuildContext context,
    VoidCallback onOpenSettings,
  ) {
    return ErrorStateWidget(
      title: 'Camera Permission Required',
      message: 'We need camera permission to scan receipts. Enable it in settings to continue',
      errorType: ErrorType.permission,
      retryLabel: 'Open Settings',
      onRetry: onOpenSettings,
      secondaryActionLabel: 'Cancel',
      onSecondaryAction: () => Navigator.pop(context),
    );
  }
}

/// Inline error banner for non-blocking errors
class ErrorBanner extends StatelessWidget {
  final String message;
  final ErrorType errorType;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.errorType = ErrorType.generic,
    this.onDismiss,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColorForErrorType(errorType);

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getIconForErrorType(errorType),
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, color: color),
                tooltip: 'Retry',
              ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: color),
                tooltip: 'Dismiss',
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return Icons.cloud_off_rounded;
      case ErrorType.notFound:
        return Icons.search_off_rounded;
      case ErrorType.permission:
        return Icons.lock_outline_rounded;
      case ErrorType.timeout:
        return Icons.timer_off_rounded;
      case ErrorType.generic:
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.permission:
        return Colors.amber;
      case ErrorType.timeout:
        return Colors.deepOrange;
      case ErrorType.generic:
      default:
        return Colors.red.shade400;
    }
  }
}

/// Success banner for positive feedback
class SuccessBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData? icon;

  const SuccessBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = Colors.green;

    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon ?? Icons.check_circle_rounded,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, color: color),
                tooltip: 'Dismiss',
              ),
          ],
        ),
      ),
    );
  }
}
