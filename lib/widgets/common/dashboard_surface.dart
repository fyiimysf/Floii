import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/responsive.dart';

/// One continuous dashboard surface: every section lives on a single full-bleed
/// card instead of a stack of separate floating cards.
///
/// Square-cornered and borderless so the sections read as one panel rather than
/// as several cards that happen to be near each other.
class DashboardSurface extends StatelessWidget {
  final List<Widget> children;

  const DashboardSurface({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.zero,
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: AppColors.clayShadow.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
        border: Border.all(
          color: Colors.transparent,
          width: AppDimensions.borderThin,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Hairline between two sections. Inset by the same amount as the sections so
/// it never runs into the panel edge.
class DashboardSectionDivider extends StatelessWidget {
  const DashboardSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dashboardSectionInset(context),
        vertical: AppDimensions.smallSpacing,
      ),
      child: Container(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
      ),
    );
  }
}

/// Padding around one section inside a [DashboardSurface].
Widget dashboardSectionBlock(BuildContext context, Widget child) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: dashboardSectionInset(context),
      vertical: context.scaleLength(AppDimensions.elementSpacing),
    ),
    child: child,
  );
}

/// Horizontal inset between the dashboard surface and each section. Tightened on
/// narrow screens so the content keeps enough width to stop clipping labels.
double dashboardSectionInset(BuildContext context) =>
    context.scaleLength(AppDimensions.cardPadding, min: 0.7);
