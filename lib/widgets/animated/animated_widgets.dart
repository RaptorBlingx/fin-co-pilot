import 'package:flutter/material.dart';
import '../../themes/app_theme.dart';
import '../../utils/animation_utils.dart';
import '../../utils/haptic_utils.dart';

/// Animated button with haptic feedback and micro-interactions
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final double elevation;
  final AnimatedButtonType type;
  final Size? size;

  const AnimatedButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingL,
      vertical: AppTheme.spacingM,
    ),
    this.borderRadius,
    this.elevation = 2,
    this.type = AnimatedButtonType.elevated,
    this.size,
  }) : super(key: key);

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward();
      HapticUtils.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _resetPress();
  }

  void _handleTapCancel() {
    _resetPress();
  }

  void _resetPress() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.isDisabled || widget.isLoading;
    
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.textColor ?? Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color: widget.textColor,
          ),
          const SizedBox(width: AppTheme.spacingS),
        ],
        Text(
          widget.text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: widget.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    Widget button = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: _buildButtonByType(context, buttonContent, isDisabled),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: button,
    );
  }

  Widget _buildButtonByType(BuildContext context, Widget content, bool isDisabled) {
    final backgroundColor = widget.backgroundColor ?? AppTheme.primaryGreen;
    final textColor = widget.textColor ?? Colors.white;
    
    switch (widget.type) {
      case AnimatedButtonType.elevated:
        return Container(
          width: widget.size?.width,
          height: widget.size?.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey[300] : backgroundColor,
            borderRadius: widget.borderRadius ?? AppTheme.mediumRadius,
            boxShadow: isDisabled ? [] : [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                offset: const Offset(0, widget.elevation),
                blurRadius: widget.elevation * 2,
              ),
            ],
          ),
          child: content,
        );
        
      case AnimatedButtonType.outlined:
        return Container(
          width: widget.size?.width,
          height: widget.size?.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isPressed ? backgroundColor.withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isDisabled ? Colors.grey[300]! : backgroundColor,
              width: 1.5,
            ),
            borderRadius: widget.borderRadius ?? AppTheme.mediumRadius,
          ),
          child: content,
        );
        
      case AnimatedButtonType.text:
        return Container(
          width: widget.size?.width,
          height: widget.size?.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _isPressed ? backgroundColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: widget.borderRadius ?? AppTheme.smallRadius,
          ),
          child: content,
        );
    }
  }
}

enum AnimatedButtonType { elevated, outlined, text }

/// Animated card with hover effects and smooth transitions
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final double elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool enableHoverEffect;
  final Duration animationDuration;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.margin = const EdgeInsets.all(AppTheme.spacingS),
    this.padding = const EdgeInsets.all(AppTheme.spacingM),
    this.elevation = 2,
    this.backgroundColor,
    this.borderRadius,
    this.enableHoverEffect = true,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation + 4,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.enableHoverEffect) return;
    
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimationUtils.fadeIn(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin,
              child: Material(
                elevation: _elevationAnimation.value,
                borderRadius: widget.borderRadius ?? AppTheme.mediumRadius,
                color: widget.backgroundColor ?? Theme.of(context).cardColor,
                child: InkWell(
                  onTap: widget.onTap != null ? () {
                    HapticUtils.lightImpact();
                    widget.onTap!();
                  } : null,
                  onHover: _handleHover,
                  borderRadius: widget.borderRadius ?? AppTheme.mediumRadius,
                  child: Container(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated form field with floating label and validation states
class AnimatedFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final String? errorText;
  final Color? backgroundColor;
  final EdgeInsets margin;

  const AnimatedFormField({
    Key? key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.errorText,
    this.backgroundColor,
    this.margin = const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
  }) : super(key: key);

  @override
  State<AnimatedFormField> createState() => _AnimatedFormFieldState();
}

class _AnimatedFormFieldState extends State<AnimatedFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    
    _borderColorAnimation = ColorTween(
      begin: AppTheme.mediumGray,
      end: AppTheme.primaryGreen,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _controller.forward();
      HapticUtils.selectionClick();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    _hasError = widget.errorText != null;
    
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _borderColorAnimation,
        builder: (context, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? AppTheme.getSurfaceColor(context),
                  borderRadius: AppTheme.mediumRadius,
                  border: Border.all(
                    color: _hasError 
                        ? AppTheme.errorRed 
                        : _borderColorAnimation.value ?? AppTheme.mediumGray,
                    width: _isFocused ? 2 : 1,
                  ),
                  boxShadow: _isFocused ? [
                    BoxShadow(
                      color: (_hasError ? AppTheme.errorRed : AppTheme.primaryGreen).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  validator: widget.validator,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  maxLines: widget.maxLines,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hint,
                    prefixIcon: widget.prefixIcon != null 
                        ? Icon(widget.prefixIcon) 
                        : null,
                    suffixIcon: widget.suffixIcon != null 
                        ? IconButton(
                            icon: Icon(widget.suffixIcon),
                            onPressed: widget.onSuffixTap,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(AppTheme.spacingM),
                    labelStyle: TextStyle(
                      color: _hasError 
                          ? AppTheme.errorRed 
                          : _isFocused 
                              ? AppTheme.primaryGreen 
                              : AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ),
              ),
              if (_hasError) ...[
                const SizedBox(height: AppTheme.spacingS),
                AnimationUtils.slideInFromLeft(
                  child: Text(
                    widget.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Animated floating action button with expand/collapse functionality
class AnimatedFAB extends StatefulWidget {
  final List<FABItem> items;
  final IconData mainIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final bool mini;

  const AnimatedFAB({
    Key? key,
    required this.items,
    this.mainIcon = Icons.add,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.mini = false,
  }) : super(key: key);

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    HapticUtils.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        
        // Action items
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;  
              final item = entry.value;
              return AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Label
                          if (item.label != null)
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingM,
                                  vertical: AppTheme.spacingS,
                                ),
                                child: Text(
                                  item.label!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          const SizedBox(width: AppTheme.spacingS),
                          // Mini FAB
                          FloatingActionButton.small(
                            onPressed: () {
                              item.onPressed();
                              _toggleExpanded();
                            },
                            backgroundColor: item.backgroundColor ?? widget.backgroundColor,
                            foregroundColor: item.foregroundColor ?? widget.foregroundColor,
                            child: Icon(item.icon),
                            heroTag: 'fab_$index',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
            
            // Main FAB
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return FloatingActionButton(
                  onPressed: _toggleExpanded,
                  backgroundColor: widget.backgroundColor,
                  foregroundColor: widget.foregroundColor,
                  mini: widget.mini,
                  tooltip: widget.tooltip,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Icon(widget.mainIcon),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class FABItem {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FABItem({
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });
}