import 'package:flutter/material.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../widgets/common/cards.dart';

/// Inline page header used by bottom-nav tab pages, replacing the removed
/// top app bars: an icon badge followed by the page title. When the page has
/// been pushed onto the navigator (e.g. Trends opened from Insights) a leading
/// back button is shown automatically.
class PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback? onBack;

  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingColor = color ?? AppColors.primary;
    final showBack = onBack != null || Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.screenPadding,
        AppDimensions.sectionSpacing,
        AppDimensions.screenPadding,
        AppDimensions.elementSpacing,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            ClayButton(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              color: theme.colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(10),
              radius: AppDimensions.radiusCircular,
              child: Icon(
                Icons.arrow_back_ios,
                color: theme.colorScheme.onSurface,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(width: AppDimensions.smallSpacing),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: headingColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircular),
            ),
            child: Icon(
              icon,
              color: headingColor,
              size: AppDimensions.iconLarge,
            ),
          ),
          const SizedBox(width: AppDimensions.elementSpacing),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
