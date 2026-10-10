import 'package:flutter/material.dart';
import '../../content/learn/learn_content.dart';
import '../../models/learn_topic.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';

/// Index of the Learn page: one row per article, each opening the topic page.
///
/// Rows sit directly on the page background and are separated by spacers, so
/// the list reads as a plain index rather than a stack of cards.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

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
                  Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.secondary,
                    size: AppDimensions.iconMedium,
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      context.tr('learn'),
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
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.tinySpacing,
                  ),
                  child: Text(
                    context.tr('learnIntro'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                for (var i = 0; i < learnTopics.length; i++) ...[
                  if (i > 0)
                    const SizedBox(height: AppDimensions.elementSpacing),
                  _buildTopicRow(context, learnTopics[i], languageCode),
                ],
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicRow(
    BuildContext context,
    LearnTopic topic,
    String languageCode,
  ) {
    final theme = Theme.of(context);
    final article = LearnContent.of(topic.id, languageCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          '/learn/topic',
          arguments: topic,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.smallSpacing + 2,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.smallSpacing + 2),
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(
                  topic.icon,
                  color: topic.color,
                  size: AppDimensions.iconMedium,
                ),
              ),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article?.title ?? topic.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      article?.caption ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.smallSpacing),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
