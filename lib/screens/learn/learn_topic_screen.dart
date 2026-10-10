import 'package:flutter/material.dart';
import '../../content/learn/learn_article.dart';
import '../../content/learn/learn_content.dart';
import '../../models/learn_topic.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../utils/learn_markup.dart';
import '../../widgets/common/cards.dart';

/// Full text of a single Learn article. Reached from [LearnScreen].
class LearnTopicScreen extends StatelessWidget {
  final LearnTopic topic;

  const LearnTopicScreen({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final article = LearnContent.of(topic.id, languageCode);

    if (article == null) {
      // Every id in `learnTopics` has an English article, so this is only
      // reachable if the two catalogues drift apart.
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('learn'))),
        body: Center(child: Text(context.tr('learnUnavailable'))),
      );
    }

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
                  Icon(topic.icon,
                      color: topic.color, size: AppDimensions.iconMedium),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Flexible(
                    child: Text(
                      article.title,
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

                // The opening summary is laid out like a section rather than a
                // card, so the page reads as one continuous document.
                _SectionBlock(
                  heading: context.tr('learnInShort'),
                  accent: topic.color,
                  body: article.summary,
                ),

                if (article.facts != null) ...[
                  const SizedBox(height: AppDimensions.elementSpacing),
                  _QuickInfo(facts: article.facts!, accent: topic.color),
                ],

                for (final section in article.sections) ...[
                  const SizedBox(height: AppDimensions.sectionSpacing),
                  _SectionBlock(
                    heading: section.heading,
                    accent: topic.color,
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

/// A heading marked by a short accent bar, followed by its body text. Shared
/// by the opening summary and by every article section so they look alike.
class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.heading,
    required this.accent,
    this.body,
    this.paragraphs = const [],
  });

  final String heading;
  final Color accent;

  /// Single-paragraph body, used by the opening summary.
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

/// Collapsible "Quick Info" panel holding the key figures for a topic.
///
/// Each row is one line: a bold label, then the figure in italics, separated
/// from the next row by a hairline. Expanded by default so the figures are
/// visible straight away, then collapsible for readers who only want the prose.
class _QuickInfo extends StatefulWidget {
  const _QuickInfo({required this.facts, required this.accent});

  final List<LearnFact> facts;
  final Color accent;

  @override
  State<_QuickInfo> createState() => _QuickInfoState();
}

class _QuickInfoState extends State<_QuickInfo> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accent;

    // Rounds the header's bottom corners only while the body is showing, so a
    // collapsed panel reads as one solid tinted bar instead of a clipped strip.
    final radius = BorderRadius.vertical(
      top: const Radius.circular(AppDimensions.radiusLarge),
      bottom: Radius.circular(
        _expanded ? 0 : AppDimensions.radiusLarge,
      ),
    );

    return ClayCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: radius,
              hoverColor: accent.withValues(alpha: 0.06),
              splashColor: accent.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: radius,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPadding,
                  vertical: AppDimensions.elementSpacing + 2,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: accent,
                      size: AppDimensions.iconMedium,
                    ),
                    const SizedBox(width: AppDimensions.smallSpacing + 2),
                    Expanded(
                      child: Text(
                        context.tr('learnQuickInfo'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppDimensions.durationNormal,
                      curve: Curves.easeInOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: accent.withValues(alpha: 0.75),
                        size: AppDimensions.iconMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // AnimatedSize rather than AnimatedCrossFade: the collapsed body is
          // removed from the tree, so screen readers skip it and finders and
          // hit testing do not see hidden content.
          AnimatedSize(
            duration: AppDimensions.durationNormal,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _buildFacts(context, theme)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildFacts(BuildContext context, ThemeData theme) {
    // One line per figure. The label is bold and the value italic so the two
    // halves are distinguishable at a glance without splitting them across
    // lines and losing the sentence.
    final labelStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w700,
      height: 1.4,
    );
    final valueStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
      fontStyle: FontStyle.italic,
      height: 1.4,
    );

    // Hairlines between rows keep a long list of figures scannable instead of
    // reading as one dense paragraph.
    final dividerColor = theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardPadding,
        vertical: AppDimensions.elementSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.facts.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.elementSpacing - 2,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: dividerColor,
                ),
              ),
            Text.rich(
              TextSpan(
                children: [
                  ...parseLearnSpans(
                    widget.facts[i].label,
                    base: labelStyle,
                    accent: widget.accent,
                  ),
                  TextSpan(text: ': ', style: labelStyle),
                  ...parseLearnSpans(
                    widget.facts[i].value,
                    base: valueStyle,
                    accent: widget.accent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
