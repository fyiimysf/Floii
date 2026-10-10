import 'package:flutter/material.dart';
import '../../utils/constants/dimensions.dart';

/// Pinned top bar for bottom-nav tab pages. Matches the existing
/// pushed-page [SliverAppBar] style (pinned, no flex, centered
/// [FlexibleSpaceBar]) while adding an optional leading icon badge and
/// trailing action.
///
/// Call [context] cannotPop as `canPop=false` for tab pages to avoid a
/// back-button showing (the shell handles back via the nav bar).
class TabSliverHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  final String? actionTooltip;

  const TabSliverHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    this.onAction,
    this.actionIcon,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      backgroundColor: theme.colorScheme.surface,
      leading: const SizedBox.shrink(),
      leadingWidth: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppDimensions.smallSpacing,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.tinySpacing),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (onAction != null && actionIcon != null)
          Padding(
            padding: const EdgeInsets.only(
              right: AppDimensions.screenPadding,
            ),
            child: Tooltip(
              message: actionTooltip ?? '',
              child: IconButton(
                onPressed: onAction,
                icon: Icon(actionIcon!, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.08),
                  foregroundColor: accentColor,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: AppDimensions.screenPadding),
      ],
    );
  }
}
