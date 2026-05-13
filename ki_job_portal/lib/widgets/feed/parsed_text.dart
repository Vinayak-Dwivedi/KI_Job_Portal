import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ParsedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const ParsedText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = (style ?? const TextStyle()).copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    final List<TextSpan> spans = [];
    final words = text.split(' ');

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final suffix = i == words.length - 1 ? '' : ' ';

      if (word.startsWith('@') && word.length > 1) {
        final mention = word.substring(1);
        spans.add(
          TextSpan(
            text: '$word$suffix',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // For now, we don't have a direct UID mapping for mentions in plain text
                // So we might search for users or just show a snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mention: $mention')),
                );
              },
          ),
        );
      } else if (word.startsWith('#') && word.length > 1) {
        final hashtag = word.substring(1);
        spans.add(
          TextSpan(
            text: '$word$suffix',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Search for hashtag
                context.push('/search?q=%23$hashtag');
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: '$word$suffix', style: style));
      }
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans),
    );
  }
}
