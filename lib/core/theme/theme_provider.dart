import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

/// Centralized theme state: owns the active [ThemeMode], persists it, and
/// keeps [AppColors]'s effective brightness in sync so ad-hoc color/style
/// call sites (that don't go through `Theme.of(context)`) stay correct.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'app_theme_mode';
  // Key used by the old (removed) ThemeProvider; migrated on first load so a
  // preference saved before the rebuild doesn't get silently dropped.
  static const _legacyIsDarkKey = 'isDarkMode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDark => AppColors.isDark;

  /// Flips between light and dark. [ThemeMode.system] toggles relative to
  /// whatever brightness is currently resolved, rather than jumping to a
  /// fixed mode.
  Future<void> toggleTheme() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      _themeMode = _decode(stored);
    } else if (prefs.containsKey(_legacyIsDarkKey)) {
      final legacyIsDark = prefs.getBool(_legacyIsDarkKey) ?? false;
      _themeMode = legacyIsDark ? ThemeMode.dark : ThemeMode.light;
      await prefs.setString(_prefsKey, _encode(_themeMode));
      await prefs.remove(_legacyIsDarkKey);
    }
    _syncAppColorsBrightness();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    _syncAppColorsBrightness();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _encode(mode));
  }

  /// Forwarded from [WidgetsBindingObserver.didChangePlatformBrightness] so
  /// [ThemeMode.system] tracks OS changes made while the app is running.
  void handlePlatformBrightnessChanged(Brightness platformBrightness) {
    if (_themeMode != ThemeMode.system) return;
    AppColors.setBrightness(platformBrightness);
    notifyListeners();
  }

  void _syncAppColorsBrightness() {
    final effective = switch (_themeMode) {
      ThemeMode.system => PlatformDispatcher.instance.platformBrightness,
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };
    AppColors.setBrightness(effective);
  }

  static ThemeMode _decode(String value) => ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.light,
      );

  static String _encode(ThemeMode mode) => mode.name;
}
