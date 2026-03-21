import 'package:flutter/services.dart';

class SecureScreenService {
  static const MethodChannel _channel = MethodChannel(
    'xionghou/secure_screen',
  );

  static Future<void> setProtected(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setProtected', {
        'enabled': enabled,
      });
    } catch (_) {
      // Best effort only. Android can enforce; iOS may no-op.
    }
  }
}
