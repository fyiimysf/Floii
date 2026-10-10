import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:floi/utils/extensions/localization_extension.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/date_extensions.dart';
import '../../../widgets/common/cards.dart';

/// Start-date picker for adding a cycle. The start date is chosen with an
/// effectively infinite vertical date wheel (the day indices wrap modulo a
/// 2000–2100 century, repeated across many cycles), so it can be scrolled
/// months or years in either direction. Duration is picked with the same
/// 5/6/7-day chips as the period editor and saved via [onSave].
class ChooseDateSheet extends StatefulWidget {
  final DateTime initialDate;
  final int defaultMenstrualDays;
  final void Function(DateTime startDate, int duration) onSave;

  const ChooseDateSheet({
    super.key,
    required this.initialDate,
    required this.defaultMenstrualDays,
    required this.onSave,
  });

  @override
  State<ChooseDateSheet> createState() => _ChooseDateSheetState();
}

class _ChooseDateSheetState extends State<ChooseDateSheet> {
  static final DateTime _cycleStart = DateTime(2000, 1, 1);
  static final DateTime _cycleEnd = DateTime(2100, 1, 1);
  static final int _cycleLength = _cycleEnd.difference(_cycleStart).inDays;
  static const int _cyclesBelow = 15;
  static const int _cyclesTotal = 31;

  late final int _itemCount = _cycleLength * _cyclesTotal;
  late final FixedExtentScrollController _controller;
  late DateTime selectedDate;
  late int menstrualDays;

  int _indexForDate(DateTime date) {
    final offset = date.difference(_cycleStart).inDays;
    return offset + _cyclesBelow * _cycleLength;
  }

  DateTime _dateForIndex(int index) {
    final wrapped = ((index % _cycleLength) + _cycleLength) % _cycleLength;
    return _cycleStart.add(Duration(days: wrapped));
  }

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    menstrualDays = widget.defaultMenstrualDays;
    _controller = FixedExtentScrollController(
      initialItem: _indexForDate(widget.initialDate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
      ),
      padding: const EdgeInsets.only(top: AppDimensions.elementSpacing),
      child: SafeArea(
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
            _buildHeader(),
            const SizedBox(height: AppDimensions.elementSpacing),
            _buildDateWheel(),
            const SizedBox(height: AppDimensions.elementSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPadding),
              child: _buildDurationControl(),
            ),
            const SizedBox(height: AppDimensions.sectionSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.cardPadding),
              child: _buildActionButtons(),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.smallSpacing),
              decoration: BoxDecoration(
                color: AppColors.period.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                color: AppColors.period,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            Text(
              context.tr('chooseDate'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        ClayCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.elementSpacing,
            vertical: AppDimensions.smallSpacing,
          ),
          child: Text(
            '${intl.DateFormat('MMM dd').format(selectedDate)} - '
            '${intl.DateFormat('MMM dd').format(selectedDate.addDays(menstrualDays - 1))}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateWheel() {
    final theme = Theme.of(context);

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 52,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 2.0,
            squeeze: 0.95,
            overAndUnderCenterOpacity: 0.3,
            onSelectedItemChanged: (index) {
              setState(() => selectedDate = _dateForIndex(index));
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _itemCount,
              builder: (context, index) => _buildDateRow(index),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 48,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(int index) {
    final theme = Theme.of(context);
    final date = _dateForIndex(index);
    final isToday = date.isToday();
    final isSelected = date.isSameDate(selectedDate);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.elementSpacing),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.elementSpacing,
          vertical: AppDimensions.smallSpacing,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.period.withValues(alpha: 0.15)
              : isToday
                  ? AppColors.today.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: isToday
              ? Border.all(
                  color: AppColors.today.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${date.day}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimensions.fontXL,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? AppColors.period
                      : isToday
                          ? AppColors.today
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            Text(
              '${intl.DateFormat('EEE').format(date)}, ${intl.DateFormat('MMM').format(date)} ${date.year}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.period
                    : isToday
                        ? AppColors.today
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationControl() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClayCard(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: AppDimensions.iconSmall,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Text(
            context.tr('duration'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          ...List.generate(3, (index) {
            final days = 5 + index;
            final isSelected = menstrualDays == days;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    menstrualDays = days;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.elementSpacing,
                    vertical: AppDimensions.smallSpacing,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : theme.colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    boxShadow: isDark
                        ? []
                        : isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  blurRadius: 3,
                                  offset: const Offset(-2, -2),
                                ),
                                BoxShadow(
                                  color: AppColors.clayShadow
                                      .withValues(alpha: 0.3),
                                  blurRadius: 3,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                  ),
                  child: Text(
                    '$days',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 24),
            label: Text(
              context.tr('save'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.elementSpacing),
            ),
            onPressed: () {
              widget.onSave(selectedDate, menstrualDays);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
