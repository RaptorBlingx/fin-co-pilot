import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../utils/haptic_utils.dart';

/// Enhanced navigation utilities with smooth page transitions
class AppNavigation {
  
  /// Navigate with shared axis transition (horizontal slide)
  static Future<T?> pushWithSlide<T extends Object?>(
    BuildContext context,
    Widget page, {
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate with fade through transition (good for peer pages)
  static Future<T?> pushWithFadeThrough<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate with scale transition (modal-like)
  static Future<T?> pushWithScale<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 400),
    bool maintainState = true,
    bool fullscreenDialog = false,
    Curve curve = Curves.elasticOut,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: curve,
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Navigate with slide up transition (bottom sheet style)
  static Future<T?> pushWithSlideUp<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 350),
    bool maintainState = true,
    bool fullscreenDialog = false,
    Curve curve = Curves.easeOutCubic,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate with rotation transition (unique effect)
  static Future<T?> pushWithRotation<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 500),
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        maintainState: maintainState,
        fullscreenDialog: fullscreenDialog,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return RotationTransition(
            turns: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Replace current page with shared axis transition
  static Future<T?> replaceWithSlide<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            child: child,
          );
        },
      ),
      result: result,
    );
  }

  /// Push and remove all previous routes
  static Future<T?> pushAndClearStack<T extends Object?>(
    BuildContext context,
    Widget page, {
    SharedAxisTransitionType transitionType = SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: transitionType,
            child: child,
          );
        },
      ),
      (route) => false,
    );
  }

  /// Pop with haptic feedback
  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    HapticUtils.lightImpact();
    Navigator.of(context).pop(result);
  }

  /// Pop until specific route
  static void popUntil(BuildContext context, RoutePredicate predicate) {
    HapticUtils.lightImpact();
    Navigator.of(context).popUntil(predicate);
  }

  /// Pop to root
  static void popToRoot(BuildContext context) {
    HapticUtils.mediumImpact();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

/// Custom page route with container transform (for expanding cards)
class ContainerTransformPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final String? routeName;
  final Duration _transitionDuration;

  ContainerTransformPageRoute({
    required this.child,
    this.routeName,
    Duration transitionDuration = const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : _transitionDuration = transitionDuration,
       super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Bottom sheet with container transform
class AnimatedBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => child,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      barrierColor: barrierColor,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
      transitionAnimationController: transitionAnimationController,
    );
  }

  static Future<T?> showWithAnimation<T>({
    required BuildContext context,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: isDismissible,
        barrierColor: Colors.black54,
        transitionDuration: duration,
        reverseTransitionDuration: duration,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).bottomSheetTheme.backgroundColor ??
                         Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          );
        },
      ),
    );
  }
}

/// Custom dialog with animations
class AnimatedDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    Duration transitionDuration = const Duration(milliseconds: 300),
    DialogTransitionType transitionType = DialogTransitionType.scale,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return child;
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return _buildDialogTransition(
          animation: animation,
          child: child,
          transitionType: transitionType,
        );
      },
    );
  }

  static Widget _buildDialogTransition({
    required Animation<double> animation,
    required Widget child,
    required DialogTransitionType transitionType,
  }) {
    switch (transitionType) {
      case DialogTransitionType.scale:
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case DialogTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      case DialogTransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      case DialogTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
    }
  }
}

enum DialogTransitionType {
  scale,
  fade,
  slideFromTop,
  slideFromBottom,
}

/// Navigation observer for tracking route changes
class AppNavigationObserver extends NavigatorObserver {
  final Function(Route<dynamic>)? onPush;
  final Function(Route<dynamic>)? onPop;
  final Function(Route<dynamic>, Route<dynamic>?)? onReplace;

  AppNavigationObserver({
    this.onPush,
    this.onPop,
    this.onReplace,
  });

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPush?.call(route);
    HapticUtils.lightImpact();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPop?.call(route);
    HapticUtils.lightImpact();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      onReplace?.call(newRoute, oldRoute);
    }
    HapticUtils.lightImpact();
  }
}