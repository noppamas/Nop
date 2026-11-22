import 'package:flutter/services.dart';

/// Sets the native macOS window title.
///
/// Flutter does not forward its own title to the NSWindow, so the Runner
/// exposes a small method channel for it (see `MainFlutterWindow.swift`).
class WindowTitle {
  const WindowTitle._();

  static const MethodChannel _channel = MethodChannel(
    'json_better_editor/window',
  );

  /// Reads the native window title. Returns null outside the macOS Runner.
  static Future<String?> get() async {
    try {
      return await _channel.invokeMethod<String>('getTitle');
    } on MissingPluginException {
      return null;
    }
  }

  static Future<void> set(String title) async {
    try {
      await _channel.invokeMethod<void>('setTitle', title);
    } on MissingPluginException {
      // Not running inside the macOS Runner (for example in widget tests).
    }
  }
}
