import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';

/// Help & FAQ: the questions users ask most, grouped into Learn-style sections,
/// with a closing card that routes to Send Feedback.
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

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
                  const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.secondary,
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      context.tr('helpAndFaq'),
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
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.elementSpacing),
                Text(
                  context.tr('faqIntro'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildGroup(
                  context,
                  title: context.tr('faqGettingStarted'),
                  accent: AppColors.primary,
                  entranceStep: 0,
                  items: [
                    (context.tr('q1'), context.tr('a1')),
                  ],
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildGroup(
                  context,
                  title: context.tr('faqTracking'),
                  accent: AppColors.secondary,
                  entranceStep: 1,
                  items: [
                    (context.tr('q2'), context.tr('a2')),
                    (context.tr('q7'), context.tr('a7')),
                    (context.tr('q3'), context.tr('a3')),
                  ],
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildGroup(
                  context,
                  title: context.tr('faqDataPrivacy'),
                  accent: AppColors.mint,
                  entranceStep: 2,
                  items: [
                    (context.tr('q5'), context.tr('a5')),
                    (context.tr('q4'), context.tr('a4')),
                    (context.tr('q6'), context.tr('a6')),
                  ],
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                ClayCard(
                  entranceStep: 3,
                  color: AppColors.primary.withValues(alpha: 0.05),
                  onTap: () => Navigator.pushNamed(context, '/feedback'),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(AppDimensions.elementSpacing),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.contact_support_outlined,
                          color: AppColors.primary,
                          size: AppDimensions.iconMedium,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.elementSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('stillNeedHelp'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.smallSpacing),
                            Text(
                              context.tr('contact'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// A titled group of accordion questions. The heading echoes the Learn
  /// section style so the page shares the same visual language.
  Widget _buildGroup(
    BuildContext context, {
    required String title,
    required Color accent,
    required int entranceStep,
    required List<(String, String)> items,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing + 2),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        ClayCard(
          entranceStep: entranceStep,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.elementSpacing,
            vertical: AppDimensions.smallSpacing,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 0,
                      color:
                          theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  _buildFaqItem(context, items[i].$1, items[i].$2, accent),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    String question,
    String answer,
    Color accent,
  ) {
    final theme = Theme.of(context);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          bottom: AppDimensions.elementSpacing,
        ),
        iconColor: accent,
        collapsedIconColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        title: Text(
          question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
