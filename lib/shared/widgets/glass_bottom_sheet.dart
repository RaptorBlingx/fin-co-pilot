import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// Premium glass-treated bottom sheet.
///
/// ```dart
/// showGlassBottomSheet(
///   context: context,
///   builder: (ctx) => Column(children: [...]),
/// );
/// ```
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool isScrollControlled = false,
  double? maxHeight,
}) {
  HapticFeedback.mediumImpact();

  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) {
      final glass = ctx.glass;
      final isDark = ctx.isDark;
      final cs = ctx.colors;

      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXXL),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurMedium,
              sigmaY: DesignTokens.glassBlurMedium,
            ),
            child: Container(
              constraints: maxHeight != null
                  ? BoxConstraints(maxHeight: maxHeight)
                  : null,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceContainer.withOpacity(0.92)
                    : Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusXXL),
                ),
                border: Border(
                  top: BorderSide(
                    color: glass.glassBorder,
                    width: DesignTokens.glassBorderWidth,
                  ),
                  left: BorderSide(
                    color: glass.glassBorder,
                    width: DesignTokens.glassBorderWidth,
                  ),
                  right: BorderSide(
                    color: glass.glassBorder,
                    width: DesignTokens.glassBorderWidth,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.paddingM),
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withOpacity(0.4),
                        borderRadius: DesignTokens.borderRadiusFull,
                      ),
                    ),
                  ),
                  // Content
                  Flexible(child: builder(ctx)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
