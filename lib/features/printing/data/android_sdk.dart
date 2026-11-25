import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// Android API level (`Build.VERSION.SDK_INT`), or null off Android.
///
/// Read once through the existing SPP method channel (see
/// `SppPrinterChannel.kt`) rather than adding device_info_plus, then cached.
/// Returns null if the bridge fails, which callers treat like Android 12+:
/// location is never requested.
class AndroidSdk {
  AndroidSdk._();

  static const _methods = MethodChannel('pos_app/spp_printer');
  static Future<int?>? _cached;

  static Future<int?> sdkInt() => _cached ??= _read();

  static Future<int?> _read() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _methods.invokeMethod<int>('sdkInt');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
