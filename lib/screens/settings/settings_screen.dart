import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/cycle_models.dart';
import '../../services/localization/language_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/storage/backup_service.dart';
import '../../services/storage/storage_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/dialogs/clay_dialog.dart';
import '../../widgets/common/floating_tab_bar.dart';
import '../../widgets/common/hold_to_confirm.dart';
import '../home/dialogs/menstrual_settings_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final LanguageService _languageService = LanguageService();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _showPeriodSettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MenstrualSettingsDialog(
        initialDays: _storage.getMenstrualDays(),
        initialCycleLength: _storage.getCycleLength(),
        onSave: (days, cycleLength) {
          _storage.setMenstrualDays(days);
          _storage.setCycleLength(cycleLength);
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _exportBackup() async {
    final jsonStr = BackupService().buildBackup();
    final defaultName =
        'floii-backup-${DateFormat('yyyyMMdd').format(DateTime.now())}.json';

    final uri = await FilePicker.saveFile(
      dialogTitle: context.tr('exportBackup'),
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(jsonStr)),
    );

    if (uri == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          // Without this the bar falls back to colorScheme.inverseSurface,
          // which is near-white here and left the white text invisible.
          backgroundColor: AppColors.success.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDimensions.screenPadding),
          content: Row(
            children: [
              const Icon(Icons.backup_outlined, color: Colors.white),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(
                child: Text(
                  context.tr('backupExported'),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _importBackup() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null) return;

    final content = await file.xFile.readAsString();

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return ClayDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_alt,
                  color: AppColors.warning,
                  size: AppDimensions.iconXL,
                ),
              ),
              const SizedBox(height: AppDimensions.elementSpacing),
              Text(
                context.tr('importBackupConfirmTitle'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppDimensions.smallSpacing),
              Text(
                context.tr('importBackupConfirmMessage'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.sectionSpacing),
              ClayDialogActions(
                cancelLabel: context.tr('cancel'),
                confirmLabel: context.tr('import'),
                confirmColor: AppColors.warning.withValues(alpha: 0.12),
                confirmTextColor: AppColors.warning,
                onCancel: () => Navigator.pop(context, false),
                onConfirm: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      final count = await BackupService().importBackup(content);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            backgroundColor: AppColors.success.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppDimensions.screenPadding),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(
                  child: Text(
                    context.trArgs('backupImported', {'count': count}),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            backgroundColor: AppColors.error.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(AppDimensions.screenPadding),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(
                  child: Text(
                    context.tr('importFailed'),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Runs a cleanup step detached from the UI. Nothing here can hold up the
  /// reset, so failures only ever get logged.
  Future<void> _bestEffort(String what, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[Floii] Reset could not $what: $e');
    }
  }

  Future<void> _deleteAllData() async {
    // Onboarding reads this flag as it starts, so it is written first and
    // nothing is allowed to stand in its way.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', false);
      await prefs.remove('onboarding_dark_mode');
    } catch (e) {
      debugPrint('[Floii] Reset could not clear the onboarding flag: $e');
    }

    // Clearing drops the boxes from memory straight away; only the disk flush
    // and the alarm cancellation are slow, so neither one is waited on. They
    // settle long before the user finishes onboarding. Awaiting them here is
    // what used to strand people on this screen: a wedged notification plugin
    // meant the completed bar sat there forever and nothing happened.
    unawaited(_bestEffort('clear stored data', _storage.clearAllData));

    // Disarm the OS alarms too: the reset also wipes the reminder toggles, so
    // leaving the alarms armed would keep reminding the user about data that
    // no longer exists.
    unawaited(_bestEffort(
        'cancel reminders', NotificationService().cancelAllReminders));

    if (mounted) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          backgroundColor: AppColors.error.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppDimensions.screenPadding),
          content: Row(
            children: [
              const Icon(Icons.delete_outline, color: Colors.white),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(
                child: Text(
                  context.tr('allDataDeleted'),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // The snackbar lives on this route, so let it be seen before leaving.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/onboarding', (route) => false);
        }
      });
    }
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        child: SafeArea(
          // Scrollable so a tall list or a large text scale scrolls instead of
          // overflowing the sheet.
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
                Text(
                  context.tr('language'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  context.tr('chooseLanguage'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                ..._languageService.languages.entries.map((entry) {
                  final code = entry.key;
                  final names = entry.value;
                  final isSelected =
                      _languageService.currentLocale.languageCode == code;

                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.smallSpacing),
                    child: ClayButton(
                      onTap: () async {
                        await _languageService.setLanguage(code);
                        if (context.mounted) {
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : theme.colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                code.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: isSelected
                                      ? AppColors.primary
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.elementSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  names['nativeName']!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                Text(
                                  names['name']!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: AppDimensions.iconMedium,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppDimensions.elementSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // FloatingTabBar(
          //   title: context.tr('settings'),
          //   accentColor: AppColors.primary,
          //   showAction: false,
          // ),
          SliverAppBar(
            // 1. Keeps the bar stuck to the top when scrolling
            pinned: true,
            expandedHeight: 70.0,
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
                      context.tr('settings'),
                    ),
                    centerTitle: true,
                  )),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.elementSpacing),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppDimensions.elementSpacing),
                _buildSectionHeader(context, context.tr('general'), Icons.tune),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 0,
                  child: Column(
                    children: [
                      ValueListenableBuilder<Box<Options>>(
                        valueListenable:
                            Hive.box<Options>('options').listenable(),
                        builder: (context, box, _) {
                          final options =
                              box.get('theme') ?? Options(darkMode: true);
                          return _buildSettingTile(
                            context,
                            icon: Icons.color_lens,
                            iconColor: AppColors.peach,
                            title: context.tr('theme'),
                            subtitle: options.darkMode
                                ? context.tr('dark')
                                : context.tr('light'),
                            onTap: () {},
                            onChanged: (val) async {
                              options.darkMode = val;
                              await box.put('theme', options);
                            },
                            isToggle: true,
                            value: options.darkMode,
                          );
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      _buildSettingTile(context,
                          icon: Icons.language,
                          iconColor: AppColors.mint,
                          title: context.tr('language'),
                          subtitle: _languageService.getLanguageName(
                              _languageService.currentLocale.languageCode),
                          onTap: _showLanguageDialog,
                          onChanged: (e) {}),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      _buildSettingTile(context,
                          icon: Icons.tune,
                          iconColor: AppColors.period,
                          title: context.tr('periodSettings'),
                          subtitle: context.trArgs('periodLengthSubtitle', {
                            'period': _storage.getMenstrualDays(),
                            'cycle': _storage.getCycleLength(),
                          }),
                          onTap: _showPeriodSettings,
                          onChanged: (e) {}),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      _buildSettingTile(context,
                          icon: Icons.waving_hand,
                          iconColor: AppColors.secondaryLight,
                          title: context.tr('viewOnboarding'),
                          subtitle: context.tr('viewOnboardingSubtitle'),
                          onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('has_completed_onboarding', false);
                        if (context.mounted) {
                          Navigator.of(context).pushReplacementNamed('/');
                        }
                      }, onChanged: (e) {}),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionHeader(context, context.tr('notifications'),
                    Icons.notifications_active_rounded,
                    color: AppColors.primaryLight),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 1,
                  child: _buildSettingTile(context,
                      icon: Icons.notifications_active_outlined,
                      iconColor: AppColors.period,
                      title: context.tr('notifications'),
                      subtitle: context.tr('notificationSettingsSubtitle'),
                      onTap: () =>
                          Navigator.pushNamed(context, '/notifications'),
                      onChanged: (e) {}),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionHeader(
                    context, context.tr('support'), Icons.support),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 2,
                  child: Column(
                    children: [
                      _buildSettingTile(context,
                          icon: Icons.help_outline,
                          iconColor: AppColors.secondary,
                          title: context.tr('helpAndFaq'),
                          onTap: () =>
                              Navigator.pushNamed(context, '/help-faq'),
                          onChanged: (e) {}),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      _buildSettingTile(context,
                          icon: Icons.feedback_outlined,
                          iconColor: AppColors.ovulation,
                          title: context.tr('sendFeedback'),
                          onTap: () =>
                              Navigator.pushNamed(context, '/feedback'),
                          onChanged: (e) {}),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      _buildSettingTile(context,
                          icon: Icons.info_outline,
                          iconColor: AppColors.secondary,
                          title: context.tr('about'),
                          onTap: () => Navigator.pushNamed(context, '/about'),
                          onChanged: (e) {}),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionHeader(context, context.tr('data'), Icons.storage,
                    color: AppColors.secondary),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 3,
                  child: Column(
                    children: [
                      _buildSettingTile(context,
                          icon: Icons.upload_outlined,
                          iconColor: AppColors.secondary,
                          title: context.tr('exportBackup'),
                          subtitle: context.tr('exportBackupSubtitle'),
                          onTap: _exportBackup,
                          onChanged: (e) {}),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      Divider(
                        height: 1,
                        indent: 0,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: AppDimensions.elementSpacing),
                      _buildSettingTile(context,
                          icon: Icons.download_outlined,
                          iconColor: AppColors.mint,
                          title: context.tr('importBackup'),
                          subtitle: context.tr('importBackupSubtitle'),
                          onTap: _importBackup,
                          onChanged: (e) {}),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                _buildSectionHeader(
                    context, context.tr('dangerZone'), Icons.warning_amber,
                    color: AppColors.error),
                const SizedBox(height: AppDimensions.elementSpacing),
                ClayCard(
                  entranceStep: 4,
                  color: AppColors.error.withValues(alpha: 0.05),
                  child: _buildSettingTile(context,
                      icon: Icons.delete_forever,
                      iconColor: AppColors.error,
                      // The title is the instruction: there is no dialog left to
                      // explain that this one has to be held.
                      title: context.tr('holdToDeleteData'),
                      // The title says how, so the subtext has to say what.
                      subtitle: Text(
                        context.tr('factoryResetDescription'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error.withValues(alpha: 0.75),
                        ),
                      ),
                      textColor: AppColors.error,
                      onTap: () {},
                      onHoldConfirmed: _deleteAllData,
                      // Long enough to be deliberate, short enough not to feel
                      // broken. The buzzing accelerates as it fills.
                      holdDuration: const Duration(milliseconds: 1200),
                      onChanged: (e) {}),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing * 2),
                Center(
                  child: Text(
                    '${context.tr('version')} 1.0.0',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
              ]),
            ),
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
    Object? subtitle,
    Color? textColor,
    bool isToggle = false,
    bool value = false,
    required VoidCallback onTap,
    required Function(dynamic) onChanged,
    Duration? holdDuration,
    VoidCallback? onHoldConfirmed,
  }) {
    final theme = Theme.of(context);

    final tile = ListTile(
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
          ? subtitle is Widget
              ? subtitle
              : Text(
                  subtitle as String,
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
              value: value,
              onChanged: (val) => {
                    onChanged(val),
                    setState(() {
                      value = val;
                    })
                  }),
      // A held tile is confirmed by the gesture itself, so it must not also
      // react to an ordinary tap.
      onTap: onHoldConfirmed == null ? onTap : null,
    );

    if (onHoldConfirmed == null) return tile;

    return HoldToConfirm(
      duration: holdDuration ?? const Duration(milliseconds: 500),
      color: textColor ?? AppColors.error,
      onConfirmed: onHoldConfirmed,
      child: tile,
    );
  }
}
