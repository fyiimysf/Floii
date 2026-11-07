import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:url_launcher/url_launcher.dart';

import 'constants/app_config.dart';

/// Whether the current web session runs on an iOS device, where an Android APK
/// can't be installed.
bool get isIosWeb =>
    kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Opens the Android APK download for the current build.
Future<void> launchApkDownload() async {
  try {
    await launchUrl(
      AppConfig.apkDownloadUri,
      webOnlyWindowName: '_self',
    );
  } catch (e) {
    debugPrint('[Floii] Failed to open APK download: $e');
  }
}
