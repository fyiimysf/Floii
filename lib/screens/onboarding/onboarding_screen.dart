import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/cycle/period_log_service.dart';
import '../../services/localization/language_service.dart';
import '../../services/storage/storage_service.dart';
import '../../services/widget/home_widget_service.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import '../../widgets/common/cards.dart';
import '../../widgets/common/entrance.dart';
import 'widgets/cycle_ring.dart';
import 'widgets/onboarding_features.dart';
import 'widgets/onboarding_setup.dart';

/// The first thing a new user sees: a short welcome, a tappable feature tour,
/// a two-control cycle setup, and a summary that reflects the answers.
///
/// The date and lengths live here rather than in the setup widget so they
/// survive swiping away and back, and they are only written to storage at the
/// very end so abandoning the flow leaves nothing behind.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 4;

  final PageController _pageController = PageController();
  final LanguageService _languageService = LanguageService();
  final StorageService _storage = StorageService();

  int _currentPage = 0;
  String _selectedLanguage = 'en';

  late DateTime _lastPeriodStart;
  late int _periodLength;
  late int _cycleLength;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languageService.currentLocale.languageCode;
    _lastPeriodStart = DateTime.now();
    _periodLength = _storage.getMenstrualDays();
    _cycleLength = _storage.getCycleLength();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextPage() {
    if (_currentPage < _pageCount - 1) {
      _goTo(_currentPage + 1);
    } else {
      _finish(saveSetup: true);
    }
  }

  Future<void> _finish({required bool saveSetup}) async {
    if (saveSetup && _storage.getPeriodDays().isEmpty) {
      await _storage.setMenstrualDays(_periodLength);
      await _storage.setCycleLength(_cycleLength);
      PeriodLogService().markRange(_lastPeriodStart, _periodLength);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/');
    unawaited(
      HomeWidgetService().update().catchError((Object error) {}),
    );
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSelectionModal(
        selectedLanguage: _selectedLanguage,
        onLanguageSelected: (code) {
          setState(() => _selectedLanguage = code);
          _languageService.setLanguage(code);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              showBack: _currentPage > 0,
              onBack: () => _goTo(_currentPage - 1),
              languageCode: _selectedLanguage,
              onLanguage: _showLanguageModal,
            ),
            _ProgressBar(current: _currentPage, count: _pageCount),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    EntranceOnActivate(
                      isActive: _currentPage == i,
                      child: _page(i),
                    ),
                ],
              ),
            ),
            _BottomBar(
              label: _currentPage == _pageCount - 1
                  ? context.tr('getStarted')
                  : context.tr('continueBtn'),
              showSkip: _currentPage < _pageCount - 1,
              onContinue: _nextPage,
              onSkip: () => _finish(saveSetup: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(int index) {
    switch (index) {
      case 0:
        return const _WelcomePage();
      case 1:
        return const OnboardingFeatures();
      case 2:
        return OnboardingSetup(
          lastPeriodStart: _lastPeriodStart,
          periodLength: _periodLength,
          cycleLength: _cycleLength,
          onDateChanged: (date) => setState(() => _lastPeriodStart = date),
          onPeriodLengthChanged: (days) =>
              setState(() => _periodLength = days),
          onCycleLengthChanged: (days) => setState(() => _cycleLength = days),
        );
      default:
        return _ReadyPage(
          lastPeriodStart: _lastPeriodStart,
          periodLength: _periodLength,
          cycleLength: _cycleLength,
        );
    }
  }
}

/// Back affordance on the left, the language switch on the right. No app bar,
/// so the onboarding keeps its own frame instead of inheriting the tab chrome.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showBack,
    required this.onBack,
    required this.languageCode,
    required this.onLanguage,
  });

  final bool showBack;
  final VoidCallback onBack;
  final String languageCode;
  final VoidCallback onLanguage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.smallSpacing,
        AppDimensions.smallSpacing,
        AppDimensions.screenPadding,
        0,
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: showBack ? 1 : 0,
            duration: AppDimensions.durationNormal,
            child: IgnorePointer(
              ignoring: !showBack,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onLanguage,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.elementSpacing,
                vertical: AppDimensions.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: AppDimensions.smallSpacing),
                  Text(
                    languageCode.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Four segments that fill as the flow advances, so the length of the journey
/// is always visible.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.count});

  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.elementSpacing,
        AppDimensions.screenPadding,
        AppDimensions.smallSpacing,
      ),
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  end: i == count - 1 ? 0 : AppDimensions.smallSpacing,
                ),
                child: AnimatedContainer(
                  duration: AppDimensions.durationNormal,
                  curve: Curves.easeOut,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? AppColors.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.showSkip,
    required this.onContinue,
    required this.onSkip,
  });

  final String label;
  final bool showSkip;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.smallSpacing,
        AppDimensions.screenPadding,
        AppDimensions.elementSpacing,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: AppDimensions.fontXL,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDimensions.durationNormal,
            curve: Curves.easeOut,
            child: showSkip
                ? TextButton(
                    key: const ValueKey('skip_button'),
                    onPressed: onSkip,
                    child: Text(
                      context.tr('skip'),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : const SizedBox(height: AppDimensions.elementSpacing),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CenteredScroll(
      children: [
        const CycleRingIllustration(),
        const SizedBox(height: AppDimensions.sectionSpacing * 1.5),
        Text(
          context.tr('appName'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 40,
          ),
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Text(
          context.tr('appTagline'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppDimensions.elementSpacing),
        Text(
          context.tr('onboardingWelcomeDesc'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.55,
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        const _PrivacyNote(),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user_rounded,
                size: 16, color: AppColors.fertile),
            const SizedBox(width: AppDimensions.smallSpacing),
            Text(
              context.tr('onboardingPrivateTitle'),
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.fertile,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.tinySpacing),
        Text(
          context.tr('onboardingPrivateSubtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.lastPeriodStart,
    required this.periodLength,
    required this.cycleLength,
  });

  final DateTime lastPeriodStart;
  final int periodLength;
  final int cycleLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextPeriod = lastPeriodStart.add(Duration(days: cycleLength));
    final format = DateFormat('MMM d');

    return _CenteredScroll(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: AppColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        Text(
          context.tr('allSet'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppDimensions.smallSpacing),
        Text(
          context.tr('readyToStart'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppDimensions.sectionSpacing),
        ClayCard(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Column(
            children: [
              _SummaryRow(
                icon: Icons.event_rounded,
                color: AppColors.period,
                label: context.tr('readyLastPeriod'),
                value: format.format(lastPeriodStart),
              ),
              const _SummaryDivider(),
              _SummaryRow(
                icon: Icons.event_available_rounded,
                color: AppColors.ovulation,
                label: context.tr('readyNextPeriod'),
                value: format.format(nextPeriod),
              ),
              const _SummaryDivider(),
              _SummaryRow(
                icon: Icons.water_drop_rounded,
                color: AppColors.primary,
                label: context.tr('readyPeriodLength'),
                value: '$periodLength ${context.tr('days')}',
              ),
              const _SummaryDivider(),
              _SummaryRow(
                icon: Icons.autorenew_rounded,
                color: AppColors.fertile,
                label: context.tr('readyCycleLength'),
                value: '$cycleLength ${context.tr('days')}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.smallSpacing),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppDimensions.elementSpacing),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.elementSpacing),
      child: Container(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      ),
    );
  }
}

/// Vertically centred column that still scrolls on short screens.
class _CenteredScroll extends StatelessWidget {
  const _CenteredScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPadding,
          vertical: AppDimensions.elementSpacing,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - AppDimensions.elementSpacing * 2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _LanguageSelectionModal extends StatelessWidget {
  const _LanguageSelectionModal({
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  final String selectedLanguage;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageService = LanguageService();
    final surface = theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppDimensions.elementSpacing),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.tr('chooseLanguage'),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.screenPadding),
                itemCount: languageService.languages.length,
                itemBuilder: (context, index) {
                  final entry =
                      languageService.languages.entries.toList()[index];
                  final code = entry.key;
                  final name = entry.value['name']!;
                  final nativeName = entry.value['nativeName']!;
                  final isSelected = selectedLanguage == code;

                  return Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.smallSpacing),
                    child: GestureDetector(
                      onTap: () => onLanguageSelected(code),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding:
                            const EdgeInsets.all(AppDimensions.elementSpacing),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMedium),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.35)
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.06),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMedium),
                              ),
                              child: Center(
                                child: Text(
                                  code.toUpperCase(),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
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
                                    nativeName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimensions.elementSpacing),
          ],
        ),
      ),
    );
  }
}
