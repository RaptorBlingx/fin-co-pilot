import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_theme.dart';

/// A markdown-aware text widget that renders bold, headers, lists, etc.
/// Use instead of plain [Text] when displaying AI-generated content.
class MarkdownText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final bool selectable;

  const MarkdownText({
    super.key,
    required this.data,
    this.style,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        context.textTheme.bodyMedium?.copyWith(height: 1.5) ??
        const TextStyle();

    final sheet = MarkdownStyleSheet(
      p: baseStyle,
      pPadding: EdgeInsets.zero,
      h1: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * 1.6,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h2: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * 1.4,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h3: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * 1.2,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      listBullet: baseStyle.copyWith(
        color: baseStyle.color?.withOpacity(0.6),
      ),
      blockSpacing: 12,
      listIndent: 16,
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryIndigo.withOpacity(0.4),
            width: 3,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      code: baseStyle.copyWith(
        fontFamily: 'monospace',
        fontSize: (baseStyle.fontSize ?? 14) * 0.9,
        backgroundColor: baseStyle.color?.withOpacity(0.06),
      ),
    );

    return MarkdownBody(
      data: data,
      styleSheet: sheet,
      selectable: selectable,
      shrinkWrap: true,
      softLineBreak: true,
    );
  }
}
