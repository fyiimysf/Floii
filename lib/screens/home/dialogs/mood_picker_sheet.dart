import 'package:flutter/material.dart';
import '../../../models/enums.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/localization_extension.dart';
import '../../../utils/responsive.dart';

/// Modal for picking the mood of a day: a two-column grid of mood buttons with
/// the current pick highlighted, returned via `Navigator.pop` once saved.
class MoodPickerSheet extends StatefulWidget {
  final Mood? selected;

  const MoodPickerSheet({
    super.key,
    this.selected,
  });

  @override
  State<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<MoodPickerSheet> {
  late Mood? selectedMood;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        top: false,
        // Two wide columns plus the header still exceed a short phone with
        // large system text, so the sheet scrolls rather than overflowing.
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              // Keeps the two columns from stretching into full-width rows on
              // tablets and landscape.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    Row(
                      children: [
                        const Icon(
                          Icons.mood_outlined,
                          color: AppColors.secondary,
                          size: AppDimensions.iconMedium,
                        ),
                        const SizedBox(width: AppDimensions.smallSpacing),
                        Expanded(
                          child: Text(
                            context.tr('howFeelingToday'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // Two up and three down: the wider column is what makes
                      // each option a comfortable tap target.
                      crossAxisCount: 2,
                      mainAxisSpacing: AppDimensions.smallSpacing,
                      crossAxisSpacing: AppDimensions.smallSpacing,
                      childAspectRatio: 2.7,
                      children: [
                        for (final mood in Mood.values)
                          _buildMoodOption(context, mood),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.elementSpacing),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedMood);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppDimensions.buttonHeight),
                      ),
                      child: Text(
                        context.tr('save'),
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodOption(BuildContext context, Mood mood) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = selectedMood == mood;
    // The bubble shrinks with the screen so the grid keeps working on small
    // phones.
    final bubble = context.scaleLength(46, min: 0.8);
    final label = context.tr('mood_${mood.name}');
    final radius = BorderRadius.circular(AppDimensions.radiusMedium);

    return Semantics(
      key: ValueKey('moodTile-${mood.name}'),
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: isSelected ? 0.14 : 0.05)
            : isSelected
                ? AppColors.secondary.withValues(alpha: 0.12)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
        borderRadius: radius,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedMood = mood;
            });
          },
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : theme.colorScheme.outline.withValues(alpha: 0.15),
                width: isSelected ? AppDimensions.borderMedium : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: bubble,
                  height: bubble,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary.withValues(alpha: 0.18)
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mood.icon,
                    size: bubble * 0.6,
                    color: isSelected
                        ? AppColors.secondary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(width: AppDimensions.smallSpacing),
                Expanded(
                  // Scale down instead of wrapping onto a third line when the
                  // system text scale is large.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.secondary
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: AppDimensions.fontMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
