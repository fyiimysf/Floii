import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import 'calendar_year_view.dart';
import 'package:hugeicons/hugeicons.dart';

/// Pushed `/calendar` route: same whole-year calendar as the Calendar tab,
/// wrapped in an app bar with an automatic back button.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendar03,
              color: AppColors.primary,
              size: AppDimensions.iconXL,
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
            Text(context.tr('calendar')),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: const CycleYearView(),
    );
  }
}