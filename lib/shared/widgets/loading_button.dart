import 'package:flutter/material.dart';
import '../../core/utils/haptic_utils.dart';

class LoadingButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final ButtonType type;

  const LoadingButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.type = ButtonType.elevated,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading || widget.onPressed == null) return;
    
    HapticUtils.medium();
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    Widget button;
    
    switch (widget.type) {
      case ButtonType.elevated:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : _handleTap,
          child: content,
        );
        break;
      case ButtonType.outlined:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : _handleTap,
          child: content,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: widget.isLoading ? null : _handleTap,
          child: content,
        );
        break;
    }

    if (widget.isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: button,
    );
  }
}

enum ButtonType {
  elevated,
  outlined,
  text,
}