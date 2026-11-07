import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/apk_download.dart';
import '../../utils/constants/colors.dart';
import '../../utils/constants/dimensions.dart';
import '../../utils/extensions/localization_extension.dart';

/// A slim, dismissible call-to-action pinned above the app on the web build,
/// nudging visitors to install the Android app instead of using the web
/// version.
///
/// Renders nothing on non-web platforms, so the Android build is untouched.
class DownloadApkBanner extends StatefulWidget {
  const DownloadApkBanner({super.key});

  static const String _dismissedPrefsKey = 'web_apk_banner_dismissed';

  /// Wraps [child] with the banner on web; returns it untouched elsewhere.
  static Widget wrap(Widget? child) {
    if (child == null) return const SizedBox.shrink();
    if (!kIsWeb) return child;
    return Column(
      children: [
        const DownloadApkBanner(),
        Expanded(child: child),
      ],
    );
  }

  @override
  State<DownloadApkBanner> createState() => _DownloadApkBannerState();
}

class _DownloadApkBannerState extends State<DownloadApkBanner> {
  // Starts hidden so an already-dismissed return visitor sees no flash before
  // the stored preference loads.
  bool _dismissed = true;

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _dismissed = prefs.getBool(DownloadApkBanner._dismissedPrefsKey) ?? false;
    });
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DownloadApkBanner._dismissedPrefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final ios = isIosWeb;
    final title = ios
        ? context.tr('iosBannerTitle')
        : context.tr('getAndroidApp');
    final subtitle = ios
        ? context.tr('iosBannerSubtitle')
        : context.tr('webBannerSubtitle');

    return Material(
      color: theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The subtitle is secondary, so it only appears when there is
              // room; on iOS it carries the whole message and always shows.
              final showSubtitle = ios || constraints.maxWidth >= 600;
              // The text label is the only flexible part, so on a phone-width
              // banner it collapses to an icon to keep the row from overflowing
              // (long words like the German "Herunterladen" are the culprit).
              final compact = constraints.maxWidth < 360;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.screenPadding,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ios ? Icons.phone_iphone : Icons.android,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (showSubtitle)
                            Text(
                              subtitle,
                              maxLines: ios ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!ios)
                      if (compact)
                        IconButton(
                          onPressed: launchApkDownload,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                          icon: const Icon(Icons.download_rounded),
                        )
                      else
                        TextButton(
                          onPressed: launchApkDownload,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: Text(
                            context.tr('downloadApk'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                    // No [IconButton.tooltip] here: the banner sits above the
                    // Navigator, so there is no Overlay for a Tooltip to attach
                    // to. [Semantics] gives the same accessible label instead.
                    Semantics(
                      button: true,
                      label: MaterialLocalizations.of(context).closeButtonTooltip,
                      child: IconButton(
                        onPressed: _dismiss,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        iconSize: 18,
                        icon: Icon(
                          Icons.close,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
