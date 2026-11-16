import 'package:flutter/material.dart';

import '../../models/legal_document.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/learn_section_block.dart';

/// Full text of a legal document (privacy policy, terms & conditions).
///
/// Deliberately mirrors [LearnTopicScreen]: the same pinned icon-and-title app
/// bar, the same accent-bar section blocks and the same continuous-document
/// layout, so legal copy reads as part of the same reference material.
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocument document;

  /// Localized title shown in the app bar.
  final String title;

  final IconData icon;
  final Color accent;

  /// When this document was last revised, e.g. "February 2026".
  final String lastUpdated;

  const LegalDocumentScreen({
    super.key,
    required this.document,
    required this.title,
    required this.icon,
    required this.accent,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 70,
            collapsedHeight: 70,
            toolbarHeight: 70,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppDimensions.tinySpacing,
                children: [
                  Icon(icon, color: accent, size: AppDimensions.iconMedium),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPadding,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.elementSpacing),
                Text(
                  '${context.tr('lastUpdated')} · $lastUpdated',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  document.intro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                for (final section in document.sections) ...[
                  const SizedBox(height: AppDimensions.sectionSpacing),
                  LearnSectionBlock(
                    heading: section.heading,
                    accent: accent,
                    paragraphs: section.paragraphs,
                  ),
                ],
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
