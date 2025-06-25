import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle highlightStyle;
  final TextStyle textStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.highlightStyle,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(RegExp.escape(query), caseSensitive: false);
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: textStyle);
    }

    final spans = <TextSpan>[];
    int previousIndex = 0;

    for (final match in matches) {
      if (match.start > previousIndex) {
        spans.add(TextSpan(
          text: text.substring(previousIndex, match.start),
          style: textStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: highlightStyle,
      ));
      previousIndex = match.end;
    }

    if (previousIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(previousIndex),
        style: textStyle,
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
