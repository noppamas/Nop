import 'package:flutter/services.dart';

/// Small bridge to the native macOS window (see `MainFlutterWindow.swift`).
///
/// Every call is a no-op outside the macOS Runner, for example in widget
/// tests.
class NativeWindow {
  const NativeWindow._();

  static const MethodChannel _channel = MethodChannel(
    'json_better_editor/window',
  );

  /// Width reserved on the left of the title-bar row for the macOS window
  /// controls (close, minimize, zoom).
  static const double windowControlsInset = 88;

  /// Height of the title-bar row the toolbar shares with the window
  /// controls. Matches the unified NSToolbar style set up natively.
  static const double titleBarHeight = 52;

  /// Reads the native window title. Returns null outside the macOS Runner.
  static Future<String?> getTitle() async {
    try {
      return await _channel.invokeMethod<String>('getTitle');
    } on MissingPluginException {
      return null;
    }
  }

  /// Sets the native window title (Window menu, Mission Control).
  static Future<void> setTitle(String title) async {
    try {
      await _channel.invokeMethod<void>('setTitle', title);
    } on MissingPluginException {
      // Not running inside the macOS Runner.
    }
  }

  /// Starts moving the window with the current mouse drag, as the native
  /// title bar would.
  static Future<void> startDrag() async {
    try {
      await _channel.invokeMethod<void>('startDrag');
    } on MissingPluginException {
      // Not running inside the macOS Runner.
    }
  }

  /// Zooms the window, as a double-click on the native title bar would.
  static Future<void> zoom() async {
    try {
      await _channel.invokeMethod<void>('zoom');
    } on MissingPluginException {
      // Not running inside the macOS Runner.
    }
  }

  /// Returns the window controls' frame in Flutter coordinates
  /// (`{left, top, right, bottom}`), or null outside the macOS Runner.
  static Future<Rect?> windowControlsFrame() async {
    try {
      final frame = await _channel.invokeMapMethod<String, double>(
        'windowControlsFrame',
      );
      if (frame == null) return null;
      return Rect.fromLTRB(
        frame['left']!,
        frame['top']!,
        frame['right']!,
        frame['bottom']!,
      );
    } on MissingPluginException {
      return null;
    }
  }
}
