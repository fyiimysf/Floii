import 'package:floi/utils/extensions/localization_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/enums.dart';
import '../../../services/storage/storage_service.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/dimensions.dart';
import '../../../utils/extensions/date_extensions.dart';
import '../../../widgets/common/cards.dart';
import 'mood_picker_sheet.dart';

class PeriodEditorDialog extends StatefulWidget {
  final DateTime initialDate;
  final int defaultMenstrualDays;
  final Function(DateTime startDate, int duration) onSave;
  final Function(DateTime startDate) onClear;

  const PeriodEditorDialog({
    super.key,
    required this.initialDate,
    required this.defaultMenstrualDays,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<PeriodEditorDialog> createState() => _PeriodEditorDialogState();
}

class _PeriodEditorDialogState extends State<PeriodEditorDialog> {
  late DateTime startDate;
  late DateTime endDate;
  late int menstrualDays;

  @override
  void initState() {
    super.initState();
    startDate = widget.initialDate;
    menstrualDays = widget.defaultMenstrualDays.clamp(2, 8);
    endDate = startDate.addDays(menstrualDays - 1);
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
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
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
          _buildPeriodPreview(),
          const SizedBox(height: AppDimensions.elementSpacing),
          _buildDateRangeButton(),
          const SizedBox(height: AppDimensions.elementSpacing),
          _buildStepperControl(),
          const SizedBox(height: AppDimensions.smallSpacing),
          _buildMoodRow(),
          const SizedBox(height: AppDimensions.sectionSpacing),
          _buildActionButtons(),
          const SizedBox(height: AppDimensions.elementSpacing),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ClayButton(
          onTap: () {
            setState(() {
              startDate = startDate.subtractDays(1);
              endDate = endDate.subtractDays(1);
            });
          },
          padding: const EdgeInsets.all(AppDimensions.smallSpacing),
          child: Icon(
            Icons.chevron_left,
            color: AppColors.primary,
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
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
                  context.tr('editPeriod'),
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
                '${DateFormat('MMM dd').format(startDate)} - '
                '${DateFormat('MMM dd').format(startDate.addDays(menstrualDays - 1))}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        ClayButton(
          onTap: () {
            setState(() {
              startDate = startDate.addDays(1);
              endDate = endDate.addDays(1);
            });
          },
          padding: const EdgeInsets.all(AppDimensions.smallSpacing),
          child: Icon(
            Icons.chevron_right,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodPreview() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final circles = List.generate(menstrualDays, (index) {
      final day = startDate.addDays(index);
      return Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.period.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.period),
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: AppColors.period,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    });

    return ClayCard(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Column(
        children: [
          Text(
            '${DateFormat('MMM dd').format(startDate)} – ${DateFormat('MMM dd').format(endDate)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Text(
            '$menstrualDays ${context.tr('days')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.smallSpacing),
          Wrap(
            spacing: AppDimensions.smallSpacing,
            runSpacing: AppDimensions.smallSpacing,
            alignment: WrapAlignment.center,
            children: circles,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month_rounded),
        label: Text(context.tr('chooseDate')),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.elementSpacing),
        ),
        onPressed: _pickDateRange,
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _PeriodRangeDialog(
        initialStart: startDate,
        initialEnd: endDate,
      ),
    );
    if (picked == null) return;

    const maxDays = 8;
    DateTime newStart = picked.start;
    DateTime newEnd = picked.end;
    final days = newEnd.difference(newStart).inDays + 1;
    if (days > maxDays) {
      newEnd = newStart.add(const Duration(days: maxDays - 1));
    }
    if (newEnd.difference(newStart).inDays + 1 < 2) {
      newEnd = newStart.add(const Duration(days: 1));
    }

    setState(() {
      startDate = newStart;
      endDate = newEnd;
      menstrualDays = endDate.difference(startDate).inDays + 1;
    });
  }

  Widget _buildStepperControl() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClayCard(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.elementSpacing,
        vertical: AppDimensions.smallSpacing,
      ),
      child: Row(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayButton(
                onTap: () {
                  if (menstrualDays > 2) {
                    setState(() {
                      menstrualDays -= 1;
                      endDate = endDate.subtract(const Duration(days: 1));
                    });
                  }
                },
                padding: const EdgeInsets.all(AppDimensions.smallSpacing),
                child: Icon(Icons.remove, color: AppColors.primary),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.elementSpacing),
                child: Text(
                  '$menstrualDays',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              ClayButton(
                onTap: () {
                  if (menstrualDays < 8) {
                    setState(() {
                      menstrualDays += 1;
                      endDate = endDate.add(const Duration(days: 1));
                    });
                  }
                },
                padding: const EdgeInsets.all(AppDimensions.smallSpacing),
                child: Icon(Icons.add, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodRow() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storage = StorageService();
    final currentMood = storage.getMoodForDate(startDate);

    return ClayCard(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AppDimensions.elementSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mood,
            size: AppDimensions.iconSmall,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppDimensions.smallSpacing),
          Text(
            context.tr('mood'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          if (currentMood != null) ...[
            Icon(
              currentMood.icon,
              size: 28,
              color: AppColors.secondary,
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
          ],
          ClayButton(
            onTap: () => _pickMood(currentMood),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.elementSpacing,
              vertical: AppDimensions.smallSpacing,
            ),
            color: AppColors.secondary.withValues(alpha: 0.15),
            child: Text(
              currentMood == null
                  ? context.tr('addMood')
                  : context.tr('changeMood'),
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMood(Mood? current) async {
    final mood = await showModalBottomSheet<Mood>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodPickerSheet(selected: current),
    );
    if (mood != null) {
      await StorageService().setMoodForDate(startDate, mood);
      if (mounted) setState(() {});
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ClayButton(
            onTap: () {
              widget.onClear(startDate);
              Navigator.pop(context);
            },
            color: AppColors.error.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 22,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr('clear'),
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.elementSpacing),
        Expanded(
          flex: 1,
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
              widget.onSave(startDate, menstrualDays);
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

}


/// A small, centered calendar modal for picking a period range by tapping
/// the first and last day. Days in between are highlighted automatically.
class _PeriodRangeDialog extends StatefulWidget {
  const _PeriodRangeDialog({
    required this.initialStart,
    required this.initialEnd,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  @override
  State<_PeriodRangeDialog> createState() => _PeriodRangeDialogState();
}

class _PeriodRangeDialogState extends State<_PeriodRangeDialog> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
    _month = DateTime(widget.initialStart.year, widget.initialStart.month);
  }

  void _onDayTap(DateTime day) {
    if (day.isAfter(DateTime.now())) return;
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = day;
        _end = null;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start;
          _start = day;
        } else {
          _end = day;
        }
      }
      _month = DateTime(day.year, day.month);
    });
  }

  bool _inRange(DateTime day) {
    if (_start == null) return false;
    final end = _end ?? _start!;
    final a = _start!.isBefore(end) ? _start! : end;
    final b = _start!.isBefore(end) ? end : _start!;
    return !day.isBefore(a) && !day.isAfter(b);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth = DateTime(_month.year, _month.month);
    final firstWeekday = firstOfMonth.weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    String selectedLabel = 'Tap the first day';
    if (_start != null && _end != null) {
      final days = _end!.difference(_start!).inDays + 1;
      selectedLabel = '${DateFormat('MMM dd').format(_start!)} – '
          '${DateFormat('MMM dd').format(_end!)}  ($days days)';
    } else if (_start != null) {
      selectedLabel = 'Now tap the last day';
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month - 1);
                    }),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_month),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _month = DateTime(_month.year, _month.month + 1);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map((d) => SizedBox(
                          width: 36,
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: cellCount,
                itemBuilder: (context, index) {
                  final dayNumber = index - firstWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final day = DateTime(_month.year, _month.month, dayNumber);
                  final isFuture = day.isAfter(DateTime.now());
                  final isStart = _start != null &&
                      day.year == _start!.year &&
                      day.month == _start!.month &&
                      day.day == _start!.day;
                  final isEnd = _end != null &&
                      day.year == _end!.year &&
                      day.month == _end!.month &&
                      day.day == _end!.day;
                  final inRange = _inRange(day);

                  Color? bg;
                  if (isStart || isEnd) {
                    bg = AppColors.period;
                  } else if (inRange) {
                    bg = AppColors.period.withValues(alpha: 0.18);
                  }

                  return GestureDetector(
                    onTap: isFuture ? null : () => _onDayTap(day),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                        border: isStart || isEnd
                            ? Border.all(color: AppColors.period, width: 2)
                            : null,
                      ),
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: isFuture
                              ? Colors.grey.withValues(alpha: 0.4)
                              : (isStart || isEnd)
                                  ? Colors.white
                                  : inRange
                                      ? AppColors.period
                                      : theme.colorScheme.onSurface,
                          fontWeight: isStart || isEnd
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Text(
                selectedLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Row(
                children: [
                  Expanded(
                    child: ClayButton(
                      onTap: () => Navigator.pop(context),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: Text(
                        context.tr('cancel'),
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.elementSpacing),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _start == null
                          ? null
                          : () {
                              final end = _end ?? _start!;
                              Navigator.pop(
                                context,
                                DateTimeRange(start: _start!, end: end),
                              );
                            },
                      child: Text(context.tr('save')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
