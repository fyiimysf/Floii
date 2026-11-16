import 'package:flutter/material.dart';
import '../../utils/constants/dimensions.dart';
import '../common/cards.dart';

/// A clay-styled dialog that holds its shape on small screens and at large text
/// sizes.
///
/// Flutter's [Dialog] insets its child by 40px on each side and then hands it an
/// unbounded width, so body copy wraps far earlier than the screen has any
/// reason to make it. This keeps a comfortable margin, caps the panel at a
/// readable width instead of letting it stretch edge to edge, and scrolls rather
/// than overflowing once the content grows tall.
class ClayDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ClayDialog({
    super.key,
    required this.child,
    this.maxWidth = 420,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppDimensions.elementSpacing,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClayCard(
          padding: padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }
}

/// The cancel/confirm pair used by the app's dialogs and confirm sheets.
///
/// Labels shrink to fit instead of wrapping. A wrapped label gives the two
/// buttons different heights and reads as a layout fault even on a row with
/// room to spare, which is what long translations and large text sizes cause.
class ClayDialogActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final Color? confirmTextColor;
  final bool destructive;

  const ClayDialogActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    required this.confirmLabel,
    required this.cancelLabel,
    this.confirmColor,
    this.confirmTextColor,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cancelBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : theme.colorScheme.surfaceContainerHighest;
    final confirmBg = confirmColor ??
        (destructive
            ? theme.colorScheme.error.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.12));
    final confirmFg =
        confirmTextColor ?? (destructive ? theme.colorScheme.error : null);

    // Plain Row alignment on purpose: stretch needs a bounded height, which the
    // scrollable dialogs do not provide. Both labels are a single line, so the
    // buttons come out the same height anyway.
    return Row(
      children: [
        Expanded(
          child: ClayButton(
            onTap: onCancel,
            color: cancelBg,
            padding: _buttonPadding,
            child: _ActionLabel(
              text: cancelLabel,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.elementSpacing),
        Expanded(
          child: ClayButton(
            onTap: onConfirm,
            color: confirmBg,
            padding: _buttonPadding,
            child: _ActionLabel(
              text: confirmLabel,
              color: confirmFg,
              weight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Tighter than [ClayButton]'s default, which otherwise spends 20px on each
  /// side and squeezes the label into a second line.
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    horizontal: AppDimensions.elementSpacing,
    vertical: AppDimensions.elementSpacing,
  );
}

/// One line of button text, scaled down to fit the button rather than wrapped.
class _ActionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight weight;

  const _ActionLabel({
    required this.text,
    this.color,
    this.weight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: weight,
          color: color ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
