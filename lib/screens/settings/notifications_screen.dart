import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/storage/storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/floating_tab_bar.dart';
import '../../widgets/common/top_toast.dart';

/// Dedicated, in-depth notification settings: the user decides exactly which
/// reminders they want (period, mood logging, ovulation date, phase change)
/// and when.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final StorageService _storage = StorageService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggle(
    Future<void> Function(bool enabled) persist,
    bool value,
  ) async {
    await persist(value);
    await NotificationService().syncReminder();
  }

  Future<void> _pickTime(
    int current,
    Future<void> Function(int minutes) persist,
  ) async {
    final initial = TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    await persist(picked.hour * 60 + picked.minute);
    await NotificationService().syncReminder();
    if (mounted) setState(() {});
  }

  Future<void> _sendTestNotification() async {
    await NotificationService().sendTestNotification();
    if (!mounted) return;
    showTopToast(
      context,
      message: context.tr('testNotificationSent'),
      icon: Icons.check_circle_outline,
      color: AppColors.success,
    );
  }

  Future<void> _sendTestAlarm() async {
    await NotificationService().scheduleTestAlarm();
    if (!mounted) return;
    showTopToast(
      context,
      message: context.tr('alarmScheduled'),
      icon: Icons.alarm_add,
      color: AppColors.secondary,
      duration: const Duration(seconds: 3),
    );
  }

  String _formatTime(int minutesSinceMidnight) {
    final time = TimeOfDay(
      hour: minutesSinceMidnight ~/ 60,
      minute: minutesSinceMidnight % 60,
    );
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            // 1. Keeps the bar stuck to the top when scrolling
            pinned: true,
            // expandedHeight: 20.0,
            backgroundColor:
                Theme.of(context).colorScheme.surface.withAlpha(180),
            elevation: 0,
            scrolledUnderElevation: 0,
            // backgroundColor: AppColors.cardDark.withAlpha(200),
            // actions: [
            //   IconButton(
            //     onPressed: _openTrends,
            //     icon: Icon(
            //       Icons.show_chart_rounded,
            //       color: AppColors.ovulation,
            //       size: 26,
            //     ),
            //   ),
            //   // IconButton(onPressed: _openYearPicker, icon: HugeIcon(icon:  HugeIcons.strokeRoundedCalendar03, color: AppColors.primary, size: 26,)),
            //   // TextButton(
            //   //     onPressed: _openTrends,
            //   //     child: Text(
            //   //       'Trends',
            //   //       style: TextStyle(color: AppColors.ovulation, fontSize: 16, fontWeight: FontWeight.w600),
            //   //     ))
            // ],
            // 2. Optional: Adjusts how content collapses under the status bar
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: FlexibleSpaceBar(
                    // centerTitle: true,
                    title: Text(
                      context.tr('notifications'),
                    ),
                    centerTitle: true,
                  )),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.elementSpacing),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.smallSpacing),
                  child: Text(
                    context.tr('notificationsIntro'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                ValueListenableBuilder<Box<int>>(
                  valueListenable: Hive.box<int>('settings').listenable(),
                  builder: (context, _, __) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context,
                            context.tr('periodReminder'), Icons.water_drop,
                            color: AppColors.period),
                        const SizedBox(height: AppDimensions.elementSpacing),
                        ClayCard(
                          entranceStep: 0,
                          child: Column(
                            children: [
                              _buildSettingTile(
                                context,
                                icon: Icons.notifications_active_outlined,
                                iconColor: AppColors.period,
                                title: context.tr('periodReminder'),
                                subtitle: context.tr('periodReminderSubtitle'),
                                isToggle: true,
                                value: _storage.getReminderEnabled(),
                                onTap: () => _toggle(
                                  _storage.setReminderEnabled,
                                  !_storage.getReminderEnabled(),
                                ),
                                onChanged: (val) => _toggle(
                                    _storage.setReminderEnabled, val as bool),
                              ),
                              _divider(theme),
                              _buildSettingTile(
                                context,
                                icon: Icons.schedule,
                                iconColor: AppColors.secondary,
                                title: context.tr('reminderTime'),
                                subtitle:
                                    _formatTime(_storage.getReminderTime()),
                                onTap: () => _pickTime(
                                    _storage.getReminderTime(), (m) async {
                                  await _storage.setReminderTime(m);
                                }),
                                onChanged: (e) {},
                              ),
                              _divider(theme),
                              _leadDaysRow(theme),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sectionSpacing),
                        _buildSectionHeader(
                            context, context.tr('moodReminder'), Icons.mood,
                            color: AppColors.secondary),
                        const SizedBox(height: AppDimensions.elementSpacing),
                        ClayCard(
                          entranceStep: 1,
                          child: Column(
                            children: [
                              _buildSettingTile(
                                context,
                                icon: Icons.mood,
                                iconColor: AppColors.secondary,
                                title: context.tr('moodReminder'),
                                subtitle: context.tr('moodReminderSubtitle'),
                                isToggle: true,
                                value: _storage.getMoodReminderEnabled(),
                                onTap: () => _toggle(
                                  _storage.setMoodReminderEnabled,
                                  !_storage.getMoodReminderEnabled(),
                                ),
                                onChanged: (val) => _toggle(
                                    _storage.setMoodReminderEnabled,
                                    val as bool),
                              ),
                              _divider(theme),
                              _buildSettingTile(
                                context,
                                icon: Icons.schedule,
                                iconColor: AppColors.secondary,
                                title: context.tr('reminderTime'),
                                subtitle:
                                    _formatTime(_storage.getMoodReminderTime()),
                                onTap: () => _pickTime(
                                    _storage.getMoodReminderTime(), (m) async {
                                  await _storage.setMoodReminderTime(m);
                                }),
                                onChanged: (e) {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sectionSpacing),
                        _buildSectionHeader(context,
                            context.tr('ovulationReminder'), Icons.wb_sunny,
                            color: AppColors.ovulationPhase),
                        const SizedBox(height: AppDimensions.elementSpacing),
                        ClayCard(
                          entranceStep: 2,
                          child: Column(
                            children: [
                              _buildSettingTile(
                                context,
                                icon: Icons.wb_sunny,
                                iconColor: AppColors.ovulationPhase,
                                title: context.tr('ovulationReminder'),
                                subtitle:
                                    context.tr('ovulationReminderSubtitle'),
                                isToggle: true,
                                value: _storage.getOvulationReminderEnabled(),
                                onTap: () => _toggle(
                                  _storage.setOvulationReminderEnabled,
                                  !_storage.getOvulationReminderEnabled(),
                                ),
                                onChanged: (val) => _toggle(
                                    _storage.setOvulationReminderEnabled,
                                    val as bool),
                              ),
                              _divider(theme),
                              _buildSettingTile(
                                context,
                                icon: Icons.schedule,
                                iconColor: AppColors.ovulationPhase,
                                title: context.tr('reminderTime'),
                                subtitle: _formatTime(
                                    _storage.getOvulationReminderTime()),
                                onTap: () => _pickTime(
                                    _storage.getOvulationReminderTime(),
                                    (m) async {
                                  await _storage.setOvulationReminderTime(m);
                                }),
                                onChanged: (e) {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sectionSpacing),
                        _buildSectionHeader(
                            context,
                            context.tr('phaseReminder'),
                            Icons.energy_savings_leaf,
                            color: AppColors.luteal),
                        const SizedBox(height: AppDimensions.elementSpacing),
                        ClayCard(
                          entranceStep: 3,
                          child: Column(
                            children: [
                              _buildSettingTile(
                                context,
                                icon: Icons.energy_savings_leaf,
                                iconColor: AppColors.luteal,
                                title: context.tr('phaseReminder'),
                                subtitle: context.tr('phaseReminderSubtitle'),
                                isToggle: true,
                                value: _storage.getPhaseReminderEnabled(),
                                onTap: () => _toggle(
                                  _storage.setPhaseReminderEnabled,
                                  !_storage.getPhaseReminderEnabled(),
                                ),
                                onChanged: (val) => _toggle(
                                    _storage.setPhaseReminderEnabled,
                                    val as bool),
                              ),
                              _divider(theme),
                              _buildSettingTile(
                                context,
                                icon: Icons.schedule,
                                iconColor: AppColors.luteal,
                                title: context.tr('reminderTime'),
                                subtitle: _formatTime(
                                    _storage.getPhaseReminderTime()),
                                onTap: () => _pickTime(
                                    _storage.getPhaseReminderTime(), (m) async {
                                  await _storage.setPhaseReminderTime(m);
                                }),
                                onChanged: (e) {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sectionSpacing),
                        _buildSectionHeader(context, context.tr('testing'),
                            Icons.science_outlined,
                            color: AppColors.primary),
                        const SizedBox(height: AppDimensions.elementSpacing),
                        ClayCard(
                          entranceStep: 4,
                          child: Column(
                            children: [
                              _buildSettingTile(
                                context,
                                icon: Icons.notifications_active_outlined,
                                iconColor: AppColors.primary,
                                title: context.tr('sendTestNotification'),
                                subtitle:
                                    context.tr('sendTestNotificationSubtitle'),
                                onTap: _sendTestNotification,
                                onChanged: (e) {},
                              ),
                              _divider(theme),
                              _buildSettingTile(
                                context,
                                icon: Icons.alarm_add,
                                iconColor: AppColors.period,
                                title: context.tr('scheduleTestAlarm'),
                                onTap: _sendTestAlarm,
                                onChanged: (e) {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                            height: AppDimensions.sectionSpacing * 2),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 0,
      color: theme.colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  Widget _leadDaysRow(ThemeData theme) {
    final leadDays = _storage.getPeriodLeadDays();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: AppDimensions.elementSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_bottom,
                color: AppColors.period,
                size: AppDimensions.iconMedium,
              ),
              const SizedBox(width: AppDimensions.smallSpacing),
              Expanded(
                child: Text(
                  context.tr('leadDays'),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                context.trArgs('leadDaysValue', {'days': leadDays}),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.period,
                ),
              ),
            ],
          ),
          Slider(
            value: leadDays.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            activeColor: AppColors.period,
            label: context.trArgs('leadDaysValue', {'days': leadDays}),
            onChanged: (value) {
              _storage.setPeriodLeadDays(value.round());
            },
            onChangeEnd: (value) {
              NotificationService().syncReminder();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      {Color? color}) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSmall,
          color: color ?? AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.smallSpacing),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color ?? theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? textColor,
    bool isToggle = false,
    bool value = false,
    required VoidCallback onTap,
    required Function(dynamic) onChanged,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: iconColor,
            size: AppDimensions.iconLarge,
          ),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      trailing: !isToggle
          ? Icon(
              Icons.chevron_right,
              color: textColor?.withValues(alpha: 0.5) ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.4),
            )
          : Switch(
              // Driven purely by the persisted value: the enclosing
              // ValueListenableBuilder rebuilds once the Hive write lands, so
              // flipping the value locally first would only make the switch
              // flicker back to its old state.
              value: value,
              onChanged: (val) => onChanged(val),
            ),
      onTap: onTap,
    );
  }
}
