import 'package:flutter/material.dart';

import '../../utils/apk_download.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';
import 'cards.dart';

/// Web-only call-to-action shown at the top of Settings that nudges visitors
/// toward the Android app.
///
/// iOS can't install an APK, so those visitors get the "coming soon" message
/// with no button.
class DownloadApkCard extends StatelessWidget {
  const DownloadApkCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ios = isIosWeb;

    Widget leading() => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Icon(
            ios ? Icons.phone_iphone : Icons.android,
            color: AppColors.primary,
            size: AppDimensions.iconMedium,
          ),
        );

    Widget texts() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ios ? context.tr('iosBannerTitle') : context.tr('getAndroidApp'),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              ios
                  ? context.tr('iosBannerSubtitle')
                  : context.tr('webBannerSubtitle'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );

    Widget button() => FilledButton(
          onPressed: launchApkDownload,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(
            context.tr('downloadApk'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );

    return ClayCard(
      entranceStep: 0,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // iOS has no button, so the content always fits beside the icon.
          if (ios) {
            return Row(
              children: [
                leading(),
                const SizedBox(width: AppDimensions.elementSpacing),
                Expanded(child: texts()),
              ],
            );
          }

          // On a narrow card the button drops to its own full-width row so the
          // long German label can't force the button off the edge.
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    leading(),
                    const SizedBox(width: AppDimensions.elementSpacing),
                    Expanded(child: texts()),
                  ],
                ),
                const SizedBox(height: AppDimensions.elementSpacing),
                button(),
              ],
            );
          }

          return Row(
            children: [
              leading(),
              const SizedBox(width: AppDimensions.elementSpacing),
              Expanded(child: texts()),
              const SizedBox(width: AppDimensions.elementSpacing),
              button(),
            ],
          );
        },
      ),
    );
  }
}
