import 'package:flutter/material.dart';

import '../../utils/constants/dimensions.dart';
import '../../utils/learn_markup.dart';

/// A heading marked by a short accent bar, followed by its body text.
///
/// Shared by Learn articles and the legal pages so both read as one continuous
/// document rather than a stack of cards. [body] holds a single paragraph (the
/// opening summary); [paragraphs] holds the multiple blocks of a full section.
class LearnSectionBlock extends StatelessWidget {
  const LearnSectionBlock({
    super.key,
    required this.heading,
    required this.accent,
    this.body,
    this.paragraphs = const [],
  });

  final String heading;
  final Color accent;

  /// Single-paragraph body, used by an opening summary.
  final String? body;

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
      height: 1.5,
    );

    final lines = body != null ? <String>[body!] : paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 18,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing + 2),
            Expanded(
              child: Text(
                heading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: AppDimensions.smallSpacing),
                learnRichText(lines[i], style: bodyStyle, accent: accent),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
