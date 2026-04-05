import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/haptic_utils.dart';

/// A glass-tinted search bar with animated expand/collapse and clear button.
class GlassSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;

  const GlassSearchBar({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
  });

  @override
  State<GlassSearchBar> createState() => _GlassSearchBarState();
}

class _GlassSearchBarState extends State<GlassSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clear() {
    _controller.clear();
    HapticUtils.light();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<GlassTheme>()!;

    return ClipRRect(
      borderRadius: DesignTokens.borderRadiusMD,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma * 0.5,
          sigmaY: glass.blurSigma * 0.5,
        ),
        child: Container(
          height: DesignTokens.minTapTarget,
          decoration: BoxDecoration(
            color: glass.glassBackground,
            borderRadius: DesignTokens.borderRadiusMD,
            border: Border.all(color: glass.glassBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: DesignTokens.space12),
              Icon(
                PhosphorIcons.magnifyingGlass(),
                size: DesignTokens.iconSM,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.space8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: widget.autofocus,
                  style: Theme.of(context).textTheme.bodyMedium,
                  onSubmitted: widget.onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant.withOpacity(0.6),
                        ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () => HapticUtils.light(),
                ),
              ),
              AnimatedSwitcher(
                duration: DesignTokens.durationFast,
                child: _hasText
                    ? IconButton(
                        key: const ValueKey('clear'),
                        icon: Icon(
                          PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                          size: DesignTokens.iconSM,
                          color: colors.onSurfaceVariant,
                        ),
                        onPressed: _clear,
                        splashRadius: DesignTokens.iconSM,
                      )
                    : const SizedBox(width: DesignTokens.space12, key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
