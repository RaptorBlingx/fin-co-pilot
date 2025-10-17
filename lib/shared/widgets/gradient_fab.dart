import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class GradientFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? heroTag;
  final String? tooltip;

  const GradientFAB({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
    this.tooltip = 'Add Transaction',
  });

  @override
  State<GradientFAB> createState() => _GradientFABState();
}

class _GradientFABState extends State<GradientFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    // Animate press
    await _animationController.forward();
    
    // Heavy haptic feedback
    HapticFeedback.heavyImpact();
    
    // Call the actual onPressed
    widget.onPressed();
    
    // Animate release
    await Future.delayed(const Duration(milliseconds: 50));
    await _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        heroTag: widget.heroTag ?? 'gradient_fab',
        tooltip: widget.tooltip,
        onPressed: _handlePress,
        elevation: 6,
        highlightElevation: 12,
        backgroundColor: Colors.transparent,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryIndigo.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}