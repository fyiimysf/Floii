import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';

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
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppDimensions.tinySpacing,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: AppColors.secondary,
                    size: AppDimensions.iconXL,
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
                const SizedBox(height: AppDimensions.sectionSpacing),
                Text(
                  context.tr('Faq'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q1'),
                    answer: context.tr('a1'),
                    step: 0),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q2'),
                    answer: context.tr('a2'),
                    step: 1),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q7'),
                    answer: context.tr('a7'),
                    step: 2),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q3'),
                    answer: context.tr('a3'),
                    step: 3),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q4'),
                    answer: context.tr('a4'),
                    step: 4),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q5'),
                    answer: context.tr('a5'),
                    step: 5),
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildFaqItem(context,
                    question: context.tr('q6'),
                    answer: context.tr('a6'),
                    step: 6),
                const SizedBox(height: AppDimensions.sectionSpacing),
                ClayCard(
                  entranceStep: 7,
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(AppDimensions.elementSpacing),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.contact_support,
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

  Widget _buildFaqItem(
    BuildContext context, {
    required String question,
    required String answer,
    required int step,
  }) {
    final theme = Theme.of(context);

    return ClayCard(
      entranceStep: step,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            question,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppDimensions.elementSpacing,
                top: AppDimensions.smallSpacing,
              ),
              child: Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
