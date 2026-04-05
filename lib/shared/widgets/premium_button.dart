import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/haptic_utils.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PREMIUM BUTTON
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum PremiumButtonVariant { primary, secondary, ghost, danger }

class PremiumButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final PremiumButtonVariant variant;
  final bool isLoading;
  final bool isSuccess;
  final bool isFullWidth;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = PremiumButtonVariant.primary,
    this.isLoading = false,
    this.isSuccess = false,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: DesignTokens.durationInstant,
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: DesignTokens.buttonPressScale,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: DesignTokens.curveStandard,
    ));
  }

  @override
  void didUpdateWidget(PremiumButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      HapticUtils.success();
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.onPressed != null && !widget.isLoading && !widget.isSuccess;

  void _handleTapDown(TapDownDetails _) {
    if (!_enabled) return;
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticUtils.medium();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve content
    Widget content;
    if (widget.isSuccess) {
      content = Icon(Icons.check_rounded, size: DesignTokens.iconMD, color: _foregroundColor(colors, isDark));
    } else if (widget.isLoading) {
      content = SizedBox(
        width: DesignTokens.iconSM,
        height: DesignTokens.iconSM,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _foregroundColor(colors, isDark),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: DesignTokens.iconSM),
            const SizedBox(width: DesignTokens.space8),
          ],
          widget.child,
        ],
      );
    }

    Widget button = ScaleTransition(
      scale: _scaleAnim,
      child: _buildButtonShell(context, colors, isDark, content),
    );

    if (widget.isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildButtonShell(
    BuildContext context,
    ColorScheme colors,
    bool isDark,
    Widget content,
  ) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return _PrimaryButton(
          enabled: _enabled,
          isDark: isDark,
          isFullWidth: widget.isFullWidth,
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: content,
          ),
        );

      case PremiumButtonVariant.secondary:
        return _GlassButton(
          enabled: _enabled,
          isDark: isDark,
          isFullWidth: widget.isFullWidth,
          colors: colors,
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: colors.primary),
              child: IconTheme.merge(
                data: IconThemeData(color: colors.primary),
                child: content,
              ),
            ),
          ),
        );

      case PremiumButtonVariant.ghost:
        return TextButton(
          onPressed: _enabled ? _handleTap : null,
          style: TextButton.styleFrom(
            minimumSize: const Size(DesignTokens.buttonMinWidth, DesignTokens.buttonMinHeight),
          ),
          child: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: content,
          ),
        );

      case PremiumButtonVariant.danger:
        return _DangerButton(
          enabled: _enabled,
          isDark: isDark,
          isFullWidth: widget.isFullWidth,
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: content,
              ),
            ),
          ),
        );
    }
  }

  Color _foregroundColor(ColorScheme colors, bool isDark) {
    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return Colors.white;
      case PremiumButtonVariant.secondary:
        return colors.primary;
      case PremiumButtonVariant.ghost:
        return colors.primary;
      case PremiumButtonVariant.danger:
        return Colors.white;
    }
  }
}

// ──────────────── Primary Gradient Button ────────────────────────

class _PrimaryButton extends StatelessWidget {
  final bool enabled;
  final bool isDark;
  final bool isFullWidth;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final VoidCallback onTapCancel;
  final Widget child;

  const _PrimaryButton({
    required this.enabled,
    required this.isDark,
    required this.isFullWidth,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isDark ? AppTheme.primaryGradientDark : AppTheme.primaryGradient;
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: DesignTokens.durationFast,
        child: Container(
          constraints: BoxConstraints(
            minHeight: DesignTokens.buttonMinHeight,
            minWidth: isFullWidth ? double.infinity : DesignTokens.buttonMinWidth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: DesignTokens.borderRadiusMD,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppTheme.primaryIndigo.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────── Secondary Glass Button ─────────────────────────

class _GlassButton extends StatelessWidget {
  final bool enabled;
  final bool isDark;
  final bool isFullWidth;
  final ColorScheme colors;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final VoidCallback onTapCancel;
  final Widget child;

  const _GlassButton({
    required this.enabled,
    required this.isDark,
    required this.isFullWidth,
    required this.colors,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: DesignTokens.durationFast,
        child: Container(
          constraints: BoxConstraints(
            minHeight: DesignTokens.buttonMinHeight,
            minWidth: isFullWidth ? double.infinity : DesignTokens.buttonMinWidth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: DesignTokens.borderRadiusMD,
            border: Border.all(
              color: colors.primary.withOpacity(isDark ? 0.2 : 0.15),
            ),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

// ──────────────── Danger Button ──────────────────────────────────

class _DangerButton extends StatelessWidget {
  final bool enabled;
  final bool isDark;
  final bool isFullWidth;
  final VoidCallback onTap;
  final GestureTapDownCallback onTapDown;
  final GestureTapUpCallback onTapUp;
  final VoidCallback onTapCancel;
  final Widget child;

  const _DangerButton({
    required this.enabled,
    required this.isDark,
    required this.isFullWidth,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: DesignTokens.durationFast,
        child: Container(
          constraints: BoxConstraints(
            minHeight: DesignTokens.buttonMinHeight,
            minWidth: isFullWidth ? double.infinity : DesignTokens.buttonMinWidth,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space24,
            vertical: DesignTokens.space12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.rose600 : AppTheme.rose500,
            borderRadius: DesignTokens.borderRadiusMD,
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: AppTheme.rose500.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// LEGACY COMPAT — LoadingButton redirects to PremiumButton
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum ButtonType { elevated, outlined, text }

class LoadingButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    PremiumButtonVariant variant;
    switch (type) {
      case ButtonType.elevated:
        variant = PremiumButtonVariant.primary;
      case ButtonType.outlined:
        variant = PremiumButtonVariant.secondary;
      case ButtonType.text:
        variant = PremiumButtonVariant.ghost;
    }
    return PremiumButton(
      onPressed: onPressed,
      variant: variant,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      child: Text(label),
    );
  }
}
