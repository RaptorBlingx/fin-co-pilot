import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/animation_utils.dart';

/// Lottie animation widgets for various states and interactions
class LottieAnimations {
  
  // Asset paths for Lottie animations
  static const String _loadingPath = 'assets/lottie/loading.json';
  static const String _successPath = 'assets/lottie/success.json';
  static const String _errorPath = 'assets/lottie/error.json';
  static const String _emptyPath = 'assets/lottie/empty.json';
  static const String _moneyPath = 'assets/lottie/money.json';
  static const String _chartPath = 'assets/lottie/chart.json';
  static const String _celebrationPath = 'assets/lottie/celebration.json';
  static const String _walletPath = 'assets/lottie/wallet.json';
  static const String _coinPath = 'assets/lottie/coin.json';
  static const String _profilePath = 'assets/lottie/profile.json';

  /// Loading animation with customizable size and message
  static Widget loading({
    double size = 100,
    String? message,
    Color? textColor,
    bool repeat = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            _loadingPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: repeat,
            // Use custom loading animation or fallback to built-in
            errorBuilder: (context, error, stackTrace) {
              return AnimationUtils.loadingDots(
                color: textColor ?? AppTheme.primaryGreen,
                size: size / 8,
              );
            },
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: textColor ?? AppTheme.slate600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Success animation with checkmark
  static Widget success({
    double size = 120,
    String? message,
    Color? textColor,
    bool repeat = false,
    VoidCallback? onAnimationComplete,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            _successPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: repeat,
            onLoaded: (composition) {
              if (onAnimationComplete != null) {
                Future.delayed(composition.duration, onAnimationComplete);
              }
            },
            // Fallback success animation
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: textColor ?? AppTheme.successGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ).animate()
                .scale(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                )
                .fade();
            },
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppTheme.successGreen,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Error animation with warning/error icon
  static Widget error({
    double size = 120,
    String? message,
    Color? textColor,
    bool repeat = false,
    VoidCallback? onAnimationComplete,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            _errorPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: repeat,
            onLoaded: (composition) {
              if (onAnimationComplete != null) {
                Future.delayed(composition.duration, onAnimationComplete);
              }
            },
            // Fallback error animation
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: textColor ?? AppTheme.errorRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: size * 0.5,
                ),
              ).animate()
                .shake(duration: const Duration(milliseconds: 600))
                .fade();
            },
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppTheme.errorRed,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Empty state animation
  static Widget empty({
    double size = 150,
    String? title,
    String? subtitle,
    Widget? action,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Lottie.asset(
            _emptyPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: true,
            // Fallback empty state
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(size / 2),
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  color: AppTheme.mediumGray,
                  size: size * 0.4,
                ),
              ).animate()
                .fade()
                .scale(curve: Curves.easeOutBack);
            },
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: AppTheme.spacingL),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.slate600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppTheme.spacingL),
          action,
        ],
      ],
    );
  }

  /// Money/finance related animation
  static Widget money({
    double size = 100,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _moneyPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        controller: controller,
        // Fallback money animation
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
              ),
              borderRadius: BorderRadius.circular(size / 8),
            ),
            child: Icon(
              Icons.attach_money,
              color: Colors.white,
              size: size * 0.6,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: const Duration(milliseconds: 2000));
        },
      ),
    );
  }

  /// Chart/analytics animation
  static Widget chart({
    double size = 100,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _chartPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        controller: controller,
        // Fallback chart animation
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.infoBlue],
              ),
              borderRadius: BorderRadius.circular(size / 8),
            ),
            child: Icon(
              Icons.trending_up,
              color: Colors.white,
              size: size * 0.6,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              duration: const Duration(milliseconds: 2000),
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
            );
        },
      ),
    );
  }

  /// Celebration animation for achievements
  static Widget celebration({
    double size = 200,
    bool repeat = false,
    VoidCallback? onComplete,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _celebrationPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        onLoaded: (composition) {
          if (onComplete != null) {
            Future.delayed(composition.duration, onComplete);
          }
        },
        // Fallback celebration
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.celebration,
                  color: AppTheme.primaryGreen,
                  size: size * 0.6,
                ),
                ...List.generate(6, (index) {
                  return Positioned(
                    top: size * 0.2,
                    left: size * 0.2 + (index * size * 0.1),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: [
                          AppTheme.primaryGreen,
                          AppTheme.accentOrange,
                          AppTheme.accentBlue,
                          AppTheme.successGreen,
                        ][index % 4],
                        shape: BoxShape.circle,
                      ),
                    ).animate(delay: Duration(milliseconds: index * 100))
                      .moveY(
                        duration: const Duration(milliseconds: 800),
                        begin: 0,
                        end: -size * 0.3,
                        curve: Curves.easeOut,
                      )
                      .fade(
                        duration: const Duration(milliseconds: 800),
                        begin: 1.0,
                        end: 0.0,
                      ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Wallet animation
  static Widget wallet({
    double size = 100,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _walletPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        controller: controller,
        // Fallback wallet animation
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
              ),
              borderRadius: BorderRadius.circular(size / 6),
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: size * 0.6,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              duration: const Duration(milliseconds: 2000),
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
            );
        },
      ),
    );
  }

  /// Coin flip animation
  static Widget coin({
    double size = 80,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _coinPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        controller: controller,
        // Fallback coin animation
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.accentOrange, AppTheme.warningOrange],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '\$',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .flip(duration: const Duration(milliseconds: 1500));
        },
      ),
    );
  }

  /// Profile/user animation
  static Widget profile({
    double size = 100,
    bool repeat = true,
    AnimationController? controller,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        _profilePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: repeat,
        controller: controller,
        // Fallback profile animation
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentPurple, AppTheme.primaryGreen],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: size * 0.6,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .scale(
              duration: const Duration(milliseconds: 2000),
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
            );
        },
      ),
    );
  }
}

/// Status animation widget that combines lottie with contextual information
class StatusAnimation extends StatelessWidget {
  final StatusType status;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final double size;
  final VoidCallback? onComplete;

  const StatusAnimation({
    Key? key,
    required this.status,
    this.title,
    this.subtitle,
    this.action,
    this.size = 120,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.fadeIn(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimation(),
          if (title != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.light 
                    ? AppTheme.slate600 
                    : AppTheme.slate400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacingL),
            action!,
          ],
        ],
      ),
    );
  }

  Widget _buildAnimation() {
    switch (status) {
      case StatusType.loading:
        return LottieAnimations.loading(size: size);
      case StatusType.success:
        return LottieAnimations.success(
          size: size,
          onAnimationComplete: onComplete,
        );
      case StatusType.error:
        return LottieAnimations.error(
          size: size,
          onAnimationComplete: onComplete,
        );
      case StatusType.empty:
        return LottieAnimations.empty(size: size);
      case StatusType.celebration:
        return LottieAnimations.celebration(
          size: size,
          onComplete: onComplete,
        );
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case StatusType.loading:
        return AppTheme.primaryGreen;
      case StatusType.success:
        return AppTheme.successGreen;
      case StatusType.error:
        return AppTheme.errorRed;
      case StatusType.empty:
        return AppTheme.mediumGray;
      case StatusType.celebration:
        return AppTheme.primaryGreen;
    }
  }
}

enum StatusType {
  loading,
  success,
  error,
  empty,
  celebration,
}