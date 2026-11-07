// lib/utils/constants/app_config.dart

/// Build-time configuration shared by the Android and web targets.
class AppConfig {
  const AppConfig._();

  /// Absolute URL for the Android APK.
  ///
  /// Override when building the web app with:
  ///   flutter build web --dart-define=APK_URL=https://example.com/floii.apk
  static const String _apkUrlOverride =
      String.fromEnvironment('APK_URL', defaultValue: '');

  /// Default APK location: the newest GitHub Release asset.
  ///
  /// Cloudflare Pages rejects files over 25 MiB, so the APK can't sit next to
  /// the web build; a Release asset has no such limit. The uploaded asset must
  /// be named `floii.apk` to match this URL.
  static const String _defaultApkUrl =
      'https://github.com/fyiimysf/Floii/releases/latest/download/floii.apk';

  /// Where the "Download for Android" banner points.
  static Uri get apkDownloadUri => Uri.parse(
        _apkUrlOverride.isNotEmpty ? _apkUrlOverride : _defaultApkUrl,
      );
}
