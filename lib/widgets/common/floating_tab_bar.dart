import 'package:flutter/material.dart';
import '../../utils/constants/dimensions.dart';

/// Slim, pinned header for the bottom-nav tab pages.
///
/// A single toolbar row: an optional leading group (back button when the page
/// was pushed, then the text action) and the page title flush against the
/// trailing edge. No icons, no expanding hero area.
class FloatingTabBar extends StatelessWidget {
  final String title;
  final Color accentColor;
  final bool showAction;
  final VoidCallback? onAction;
  final String? actionLabel;
  final String? actionTooltip;

  const FloatingTabBar({
    super.key,
    required this.title,
    required this.accentColor,
    this.showAction = true,
    this.onAction,
    this.actionLabel,
    this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    final hasAction = showAction && onAction != null && actionLabel != null;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SliverAppBar(
        pinned: true,
        floating: true,
        snap: false,
        primary: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        surfaceTintColor: Colors.transparent,
        backgroundColor: theme.colorScheme.surface,
        toolbarHeight: kToolbarHeight,
        title: Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: AppDimensions.screenPadding),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (hasAction || canPop)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    end: AppDimensions.screenPadding),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAction)
                      _ActionButton(
                        label: actionLabel ?? '',
                        accentColor: accentColor,
                        tooltip: actionTooltip,
                        onPressed: onAction,
                      ),
                    if (canPop) const _BackButton(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Labeled call-to-action in the leading toolbar area. Flat (no fill),
/// text-only, so it stays quiet next to the right-aligned page title.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.accentColor,
    this.tooltip,
    this.onPressed,
  });

  final String label;
  final Color accentColor;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Styled back button shown only when the page was pushed.
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_ios,
          color: theme.colorScheme.onSurface,
          size: AppDimensions.iconMedium,
        ),
      ),
    );
  }
}