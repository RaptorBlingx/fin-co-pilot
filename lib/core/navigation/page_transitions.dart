import 'package:flutter/material.dart';

class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 200),
        );
}

class ScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.8;
            const end = 1.0;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

// Shared axis transition (Material Design)
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisRoute({
    required this.page,
    this.transitionType = SharedAxisTransitionType.scaled,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (transitionType) {
              case SharedAxisTransitionType.horizontal:
                return _buildHorizontalTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
              case SharedAxisTransitionType.vertical:
                return _buildVerticalTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
              case SharedAxisTransitionType.scaled:
                return _buildScaledTransition(
                  animation,
                  secondaryAnimation,
                  child,
                );
            }
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

  static Widget _buildHorizontalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildVerticalTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 0.3);
    const end = Offset.zero;
    const curve = Curves.easeInOutCubic;

    var tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget _buildScaledTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const curve = Curves.easeInOutCubic;

    var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
      CurveTween(curve: curve),
    );

    return ScaleTransition(
      scale: animation.drive(scaleTween),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

// Helper extension for easy navigation
extension NavigationExtension on BuildContext {
  Future<T?> pushWithSlideUp<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpRoute<T>(page: page));
  }

  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(FadeRoute<T>(page: page));
  }

  Future<T?> pushWithScale<T extends Object?>(Widget page) {
    return Navigator.of(this).push<T>(ScaleRoute<T>(page: page));
  }

  Future<T?> pushWithSharedAxis<T extends Object?>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
  }) {
    return Navigator.of(this).push<T>(
      SharedAxisRoute<T>(page: page, transitionType: type),
    );
  }
}