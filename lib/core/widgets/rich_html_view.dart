import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';

/// Renders HTML-formatted rich text strings (from web CKEditor / Summernote / TinyMCE)
/// into clean, native Flutter widgets with styled headings, numbered & bulleted lists,
/// bold/italic inline text, and decoded HTML entities.
class RichHtmlView extends StatelessWidget {
  final String html;
  final TextStyle? baseStyle;

  const RichHtmlView({
    super.key,
    required this.html,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) {
      return Text('Məlumat qeyd olunmayıb.', style: baseStyle ?? TextStyle(color: AppColors.textSecondary, fontSize: 13));
    }

    final palette = AppPalette.of(context);
    final blocks = _parseHtmlToBlocks(html);

    if (blocks.isEmpty) {
      return Text(
        _decodeHtmlEntities(_stripHtmlTags(html)),
        style: baseStyle ?? TextStyle(color: palette.textPrimary, fontSize: 13, height: 1.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((b) => _buildBlock(context, b, palette)).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, _HtmlBlock block, AppPalette palette) {
    final defaultStyle = baseStyle ?? TextStyle(
      fontSize: 13,
      color: palette.textPrimary,
      height: 1.45,
    );

    switch (block.type) {
      case _BlockType.heading:
        final hLevel = block.headingLevel;
        final double size = switch (hLevel) {
          1 => 18,
          2 => 16,
          3 => 14.5,
          _ => 13.5,
        };
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text.rich(
            TextSpan(
              children: _parseInlineSpans(
                block.content,
                defaultStyle.copyWith(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  color: palette.brandNavy,
                  height: 1.3,
                ),
              ),
            ),
          ),
        );

      case _BlockType.orderedListItem:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 1),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${block.listIndex}.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: palette.brandRoyal,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: _parseInlineSpans(block.content, defaultStyle)),
                ),
              ),
            ],
          ),
        );

      case _BlockType.unorderedListItem:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 8),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.brandRoyal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: _parseInlineSpans(block.content, defaultStyle)),
                ),
              ),
            ],
          ),
        );

      case _BlockType.paragraph:
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text.rich(
            TextSpan(children: _parseInlineSpans(block.content, defaultStyle)),
          ),
        );
    }
  }

  static List<_HtmlBlock> _parseHtmlToBlocks(String raw) {
    final List<_HtmlBlock> blocks = [];
    String text = raw.trim();

    // Normalizing newlines & breaks
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Matching blocks regex
    final blockRegex = RegExp(
      r'<(h[1-6]|ol|ul|p|div)([^>]*)>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in blockRegex.allMatches(text)) {
      final tag = match.group(1)!.toLowerCase();
      final inner = match.group(3)!.trim();

      if (tag.startsWith('h')) {
        final level = int.tryParse(tag.substring(1)) ?? 2;
        blocks.add(_HtmlBlock(type: _BlockType.heading, content: inner, headingLevel: level));
      } else if (tag == 'ol' || tag == 'ul') {
        final isOrdered = tag == 'ol';
        final liRegex = RegExp(r'<li[^>]*>(.*?)</li>', caseSensitive: false, dotAll: true);
        int itemIdx = 1;
        for (final liMatch in liRegex.allMatches(inner)) {
          final liContent = liMatch.group(1)!.trim();
          blocks.add(_HtmlBlock(
            type: isOrdered ? _BlockType.orderedListItem : _BlockType.unorderedListItem,
            content: liContent,
            listIndex: itemIdx++,
          ));
        }
      } else {
        if (inner.isNotEmpty) {
          blocks.add(_HtmlBlock(type: _BlockType.paragraph, content: inner));
        }
      }
      lastEnd = match.end;
    }

    // Remaining text if any
    if (lastEnd < text.length && blocks.isEmpty) {
      final leftover = text.substring(lastEnd).trim();
      if (leftover.isNotEmpty) {
        blocks.add(_HtmlBlock(type: _BlockType.paragraph, content: leftover));
      }
    }

    return blocks;
  }

  static List<InlineSpan> _parseInlineSpans(String rawHtml, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];

    // Strip internal <p> tags inside list items
    String cleaned = rawHtml.replaceAll(RegExp(r'</?p[^>]*>', caseSensitive: false), '');

    final tagRegex = RegExp(
      r'<(strong|b|em|i|u|code|span)([^>]*)>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    int currentIndex = 0;
    for (final match in tagRegex.allMatches(cleaned)) {
      // Leading plain text
      if (match.start > currentIndex) {
        final textBefore = cleaned.substring(currentIndex, match.start);
        spans.add(TextSpan(
          text: _decodeHtmlEntities(_stripHtmlTags(textBefore)),
          style: baseStyle,
        ));
      }

      final tag = match.group(1)!.toLowerCase();
      final tagText = _decodeHtmlEntities(_stripHtmlTags(match.group(3) ?? ''));

      TextStyle spanStyle = baseStyle;
      if (tag == 'strong' || tag == 'b') {
        spanStyle = baseStyle.copyWith(fontWeight: FontWeight.w900);
      } else if (tag == 'em' || tag == 'i') {
        spanStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
      } else if (tag == 'u') {
        spanStyle = baseStyle.copyWith(decoration: TextDecoration.underline);
      } else if (tag == 'code') {
        spanStyle = baseStyle.copyWith(
          fontFamily: 'monospace',
          backgroundColor: Colors.black.withValues(alpha: 0.05),
          fontWeight: FontWeight.w700,
        );
      }

      spans.add(TextSpan(text: tagText, style: spanStyle));
      currentIndex = match.end;
    }

    // Trailing plain text
    if (currentIndex < cleaned.length) {
      final textAfter = cleaned.substring(currentIndex);
      spans.add(TextSpan(
        text: _decodeHtmlEntities(_stripHtmlTags(textAfter)),
        style: baseStyle,
      ));
    }

    return spans;
  }

  static String _stripHtmlTags(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&bull;', '•')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®');
  }

  /// Utility function to cleanly strip HTML tags and decode entities for 1-2 line previews
  static String stripToPlain(String html) {
    final stripped = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    return _decodeHtmlEntities(stripped).trim();
  }
}

enum _BlockType { heading, paragraph, orderedListItem, unorderedListItem }

class _HtmlBlock {
  final _BlockType type;
  final String content;
  final int headingLevel;
  final int listIndex;

  _HtmlBlock({
    required this.type,
    required this.content,
    this.headingLevel = 2,
    this.listIndex = 1,
  });
}
