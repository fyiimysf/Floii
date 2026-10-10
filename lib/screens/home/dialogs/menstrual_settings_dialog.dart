import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../widgets/common/cards.dart';

class MenstrualSettingsDialog extends StatefulWidget {
  final int initialDays;
  final int initialCycleLength;
  final Function(int days, int cycleLength) onSave;

  const MenstrualSettingsDialog({
    super.key,
    required this.initialDays,
    this.initialCycleLength = 28,
    required this.onSave,
  });

  @override
  State<MenstrualSettingsDialog> createState() =>
      _MenstrualSettingsDialogState();
}

class _MenstrualSettingsDialogState extends State<MenstrualSettingsDialog> {
  late int selectedDays;
  late int selectedCycleLength;

  @override
  void initState() {
    super.initState();
    selectedDays = widget.initialDays;
    selectedCycleLength = widget.initialCycleLength;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: SafeArea(
        // The two pickers plus the buttons can outgrow a short screen once text
        // is scaled up, so the body scrolls instead of overflowing.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_suggest,
                  color: AppColors.primary,
                  size: AppDimensions.iconXL,
                ),
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Text(
                context.tr('welcomeTitle'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              Text(
                context.tr('menstrualDaysQuestion'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.sectionSpacing),
              ClayCard(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : theme.colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: AppDimensions.iconSmall,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppDimensions.smallSpacing),
                        Text(
                          '${context.tr('period')} ${context.tr('duration')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (index) {
                          final days = 3 + index;
                          final isSelected = selectedDays == days;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDays = days;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusSmall),
                                  boxShadow: isDark
                                      ? []
                                      : isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: AppColors.clayShadow
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 3,
                                                offset: const Offset(3, 3),
                                              ),
                                            ],
                                ),
                                child: Center(
                                  child: Text(
                                    '$days',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    Text(
                      '$selectedDays ${context.tr('days')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    Divider(
                      height: 1,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.repeat,
                          size: AppDimensions.iconSmall,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppDimensions.smallSpacing),
                        Text(
                          context.tr('cycleLength'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.smallSpacing),
                    Slider(
                      value: selectedCycleLength.toDouble(),
                      min: 21,
                      max: 40,
                      divisions: 19,
                      label: '$selectedCycleLength',
                      onChanged: (val) {
                        setState(() {
                          selectedCycleLength = val.round();
                        });
                      },
                    ),
                    Text(
                      '$selectedCycleLength ${context.tr('days')}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.sectionSpacing),
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      onTap: () => Navigator.pop(context),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : theme.colorScheme.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.smallSpacing,
                        vertical: AppDimensions.elementSpacing,
                      ),
                      child: _SingleLineLabel(
                        context.tr('cancel'),
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.elementSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 28),
                      label: _SingleLineLabel(
                        context.tr('save'),
                        fontSize: 19,
                        weight: FontWeight.w700,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.smallSpacing,
                          vertical: AppDimensions.elementSpacing,
                        ),
                      ),
                      onPressed: () {
                        widget.onSave(selectedDays, selectedCycleLength);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
            ],
          ),
        ),
      ),
    );
  }
}

/// Button text that shrinks to fit its button instead of wrapping onto a second
/// line, which would leave cancel and save at different heights.
class _SingleLineLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight weight;

  const _SingleLineLabel(
    this.text, {
    this.fontSize = 16,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: fontSize, fontWeight: weight),
      ),
    );
  }
}
