import 'package:flutter/services.dart';

class ScreenshotPrevention {
  static const _channel = MethodChannel('karakana/screenshot');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enableScreenshotPrevention');
    } catch (_) {}
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disableScreenshotPrevention');
    } catch (_) {}
  }

  static Future<bool> isScreenCaptured() async {
    try {
      final val = await _channel.invokeMethod<bool>('isScreenCaptured');
      return val ?? false;
    } catch (_) {
      return false;
    }
  }
}
