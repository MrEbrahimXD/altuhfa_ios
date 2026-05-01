import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/accent_palette.dart';

class AppIconService {
  static const MethodChannel _channel = MethodChannel('altuhfa/app_icon');

  static Future<void> syncWithAccent(
    Color color, {
    bool closeAfterSync = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('setLauncherIcon', {
        'alias': AccentPalette.androidAliasForColor(color),
        'aliases': AccentPalette.androidAliases,
        'closeApp': closeAfterSync,
      });
    } on PlatformException {
      // Ignore failures on unsupported launchers/devices.
    } on MissingPluginException {
      // Native handler not registered yet.
    }
  }
}
