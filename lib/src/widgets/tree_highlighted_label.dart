import 'package:flutter/material.dart';

/// Renders text with fuzzy-match highlights using [RichText].
class TreeHighlightedLabel extends StatelessWidget {
  const TreeHighlightedLabel({
    super.key,
    required this.text,
    required this.matchedIndices,
    this.style,
    this.highlightStyle,
    this.maxLines = 1,
    this.overflow = TextOverflow.clip,
  });

  final String text;
  final List<int> matchedIndices;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle =
        style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final TextStyle computedHighlightStyle =
        highlightStyle ??
        baseStyle.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        );

    if (matchedIndices.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final List<InlineSpan> spans = _buildSpans(
      text: text,
      matchedIndices: matchedIndices,
      baseStyle: baseStyle,
      highlight: computedHighlightStyle,
    );

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans),
    );
  }

  List<InlineSpan> _buildSpans({
    required String text,
    required List<int> matchedIndices,
    required TextStyle baseStyle,
    required TextStyle highlight,
  }) {
    final List<int> sorted = matchedIndices.toList()..sort();
    final Set<int> validMatchSet = sorted.where((int index) => index >= 0 && index < text.length).toSet();

    if (validMatchSet.isEmpty) {
      return <InlineSpan>[TextSpan(text: text, style: baseStyle)];
    }

    final List<InlineSpan> spans = <InlineSpan>[];
    final StringBuffer normalBuffer = StringBuffer();
    final StringBuffer highlightBuffer = StringBuffer();
    bool inHighlight = false;

    for (int i = 0; i < text.length; i++) {
      final bool shouldHighlight = validMatchSet.contains(i);

      if (shouldHighlight) {
        if (!inHighlight && normalBuffer.isNotEmpty) {
          spans.add(TextSpan(text: normalBuffer.toString(), style: baseStyle));
          normalBuffer.clear();
        }
        highlightBuffer.write(text[i]);
        inHighlight = true;
      } else {
        if (inHighlight && highlightBuffer.isNotEmpty) {
          spans.add(TextSpan(text: highlightBuffer.toString(), style: highlight));
          highlightBuffer.clear();
        }
        normalBuffer.write(text[i]);
        inHighlight = false;
      }
    }

    if (highlightBuffer.isNotEmpty) {
      spans.add(TextSpan(text: highlightBuffer.toString(), style: highlight));
    }

    if (normalBuffer.isNotEmpty) {
      spans.add(TextSpan(text: normalBuffer.toString(), style: baseStyle));
    }

    return spans;
  }
}
