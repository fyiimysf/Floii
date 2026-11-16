import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../widgets/common/cards.dart';

/// The "set up your cycle" step.
///
/// Purely presentational: the parent owns the chosen date and lengths so the
/// values survive swiping back and forth, and all three controls report changes
/// straight back up.
class OnboardingSetup extends StatelessWidget {
  const OnboardingSetup({
    super.key,
    required this.lastPeriodStart,
    required this.periodLength,
    required this.cycleLength,
    required this.onDateChanged,
    required this.onPeriodLengthChanged,
    required this.onCycleLengthChanged,
  });

  final DateTime lastPeriodStart;
  final int periodLength;
  final int cycleLength;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<int> onPeriodLengthChanged;
  final ValueChanged<int> onCycleLengthChanged;

  DateTime get _nextPeriod =>
      lastPeriodStart.add(Duration(days: cycleLength));

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
          context.tr('setupTitle'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Text(
          context.tr('setupSubtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        _Section(
          icon: Icons.calendar_month_rounded,
          question: context.tr('lastPeriodQuestion'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DayPicker(
                selected: lastPeriodStart,
                onSelected: onDateChanged,
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Align(
                alignment: AlignmentDirectional.center,
                child: TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(context.tr('changeDate')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        _Section(
          icon: Icons.water_drop_rounded,
          question: context.tr('periodLengthQuestion'),
          trailing: Text(
            '$periodLength ${context.tr('days')}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Slider(
            value: periodLength.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            label: '$periodLength',
            onChanged: (value) => onPeriodLengthChanged(value.round()),
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        _Section(
          icon: Icons.autorenew_rounded,
          question: context.tr('cycleLengthQuestion'),
          trailing: Text(
            '$cycleLength ${context.tr('days')}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Slider(
            value: cycleLength.toDouble(),
            min: 20,
            max: 45,
            divisions: 25,
            label: '$cycleLength',
            onChanged: (value) => onCycleLengthChanged(value.round()),
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        _PreviewStrip(
          text: context.trArgs('nextPeriodPreview', {
            'date': DateFormat('MMM d').format(_nextPeriod),
          }),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: lastPeriodStart,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: context.tr('lastPeriodQuestion'),
    );
    if (picked != null) onDateChanged(DateTime(picked.year, picked.month, picked.day));
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.question,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String question;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.smallSpacing),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.smallSpacing),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppDimensions.smallSpacing),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppDimensions.elementSpacing),
          child,
        ],
      ),
    );
  }
}

/// Two weeks of tappable days ending today, so the most likely answer is one
/// tap away; anything older goes through the platform date picker.
class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onSelected});

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 13));

    return Wrap(
      spacing: AppDimensions.smallSpacing,
      runSpacing: AppDimensions.smallSpacing,
      children: [
        for (var i = 0; i < 14; i++)
          _DayChip(
            date: start.add(Duration(days: i)),
            selected: _isSameDay(start.add(Duration(days: i)), selected),
            onTap: () => onSelected(start.add(Duration(days: i))),
          ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDimensions.durationFast,
          curve: Curves.easeOut,
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.smallSpacing),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date)[0],
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded,
              size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimensions.smallSpacing),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
