import 'package:flutter/material.dart';

/// Minimal inline markup for Learn article copy.
///
/// Kept deliberately tiny so translators can type it by hand without learning
/// a markup language:
///
///  * `**bold**` renders bold.
///  * `_italic_` renders italic.
///  * `!!important!!` renders bold, tinted with the topic colour and given a
///    soft highlight, for the one or two things a reader should not miss.
///
/// Markers are not nested. Anything that does not match is left as literal
/// text, so an unbalanced marker degrades to plain prose instead of throwing.
final RegExp _learnMarkup = RegExp(r'\*\*(.+?)\*\*|_(.+?)_|!!(.+?)!!');

/// Splits [text] into styled spans according to [_learnMarkup].
///
/// [base] is the style plain runs inherit. [accent] tints `!!important!!`
/// runs so each topic keeps its own colour. Directionality is left to the
/// caller, so the same spans read correctly in left-to-right and
/// right-to-left locales.
List<TextSpan> parseLearnSpans(
  String text, {
  required TextStyle base,
  required Color accent,
}) {
  final spans = <TextSpan>[];
  var cursor = 0;

  for (final match in _learnMarkup.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(
        TextSpan(text: text.substring(cursor, match.start), style: base),
      );
    }

    final bold = match.group(1);
    final italic = match.group(2);
    final important = match.group(3);

    if (bold != null) {
      spans.add(
        TextSpan(
          text: bold,
          style: base.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    } else if (italic != null) {
      spans.add(
        TextSpan(
          text: italic,
          style: base.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (important != null) {
      spans.add(
        TextSpan(
          text: important,
          style: base.copyWith(
            fontWeight: FontWeight.w800,
            color: accent,
            backgroundColor: accent.withValues(alpha: 0.12),
          ),
        ),
      );
    }

    cursor = match.end;
  }

  if (cursor < text.length) {
    // Unmarked runs carry [base] too. Without it a plain run falls back to the
    // ambient DefaultTextStyle, silently discarding the caller's weight, colour
    // and height.
    spans.add(TextSpan(text: text.substring(cursor), style: base));
  }

  return spans;
}

/// [parseLearnSpans] as a widget, for the common one-off paragraph case.
Widget learnRichText(
  String text, {
  required TextStyle style,
  required Color accent,
  TextAlign? textAlign,
}) {
  return Text.rich(
    TextSpan(children: parseLearnSpans(text, base: style, accent: accent)),
    textAlign: textAlign,
  );
}
