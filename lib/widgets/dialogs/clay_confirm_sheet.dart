import 'package:flutter/material.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import 'clay_dialog.dart';

/// Shared confirm-action bottom sheet used across screens (start a period,
/// accept a prediction, log through the add-cycle FAB, ...).
class ClayConfirmSheet {
  /// Shows a clay-styled confirmation bottom sheet. [onConfirm] runs after
  /// the sheet has been dismissed.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color iconColor,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);

    return showModalBottomSheet(
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
                Container(
                  padding: const EdgeInsets.all(AppDimensions.elementSpacing),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: AppDimensions.iconXL,
                  ),
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.smallSpacing),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppDimensions.sectionSpacing),
                ClayDialogActions(
                  cancelLabel: context.tr('cancel'),
                  confirmLabel: confirmText,
                  confirmColor: iconColor.withValues(alpha: 0.1),
                  confirmTextColor: iconColor,
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
