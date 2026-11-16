import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../widgets/common/cards.dart';

/// The tour step: four features that unfold in place as you tap them, so the
/// page can be explored rather than only scrolled past.
class OnboardingFeatures extends StatefulWidget {
  const OnboardingFeatures({super.key});

  @override
  State<OnboardingFeatures> createState() => _OnboardingFeaturesState();
}

class _OnboardingFeaturesState extends State<OnboardingFeatures> {
  int _open = 0;

  static const List<List<String>> _features = [
    ['featureTracking', 'featureTrackingDesc'],
    ['featurePrediction', 'featurePredictionDesc'],
    ['featureInsights', 'featureInsightsDesc'],
    ['featurePrivacy', 'featurePrivacyDesc'],
  ];

  static const List<IconData> _icons = [
    Icons.edit_calendar_rounded,
    Icons.auto_awesome_rounded,
    Icons.insights_rounded,
    Icons.lock_outline_rounded,
  ];

  static const List<Color> _colors = [
    AppColors.period,
    AppColors.ovulation,
    AppColors.primary,
    AppColors.fertile,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.smallSpacing,
        AppDimensions.screenPadding,
        AppDimensions.sectionSpacing,
      ),
      children: [
        Text(
          context.tr('keyFeatures'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Text(
          context.tr('onboardingTourCaption'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        for (var i = 0; i < _features.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.elementSpacing),
            child: _FeatureTile(
              icon: _icons[i],
              color: _colors[i],
              title: context.tr(_features[i][0]),
              description: context.tr(_features[i][1]),
              open: _open == i,
              onTap: () => setState(() => _open = _open == i ? -1 : i),
            ),
          ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.open,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      onTap: onTap,
      color: open ? color.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: AppDimensions.durationFast,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: open ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconMedium),
              ),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: open ? color : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: AppDimensions.durationNormal,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                top: AppDimensions.elementSpacing,
                left: 2,
              ),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  height: 1.45,
                ),
              ),
            ),
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: AppDimensions.durationNormal,
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}
