import 'package:flutter/material.dart';

/// Theme-aware color facade. Every member is a getter (never a compile-time
/// constant) so it can switch between [AppColorsLight] and [AppColorsDark]
/// as the active brightness changes — never wrap a value from this class in
/// a `const` widget, or it will freeze at the brightness it first built with.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;

  /// Set by [ThemeProvider] whenever the effective app brightness changes.
  static void setBrightness(Brightness brightness) => _brightness = brightness;

  static bool get isDark => _brightness == Brightness.dark;

  // Brand Primaries (constant across themes)
  static Color get primary => const Color(0xFFE87722);
  static Color get primaryDark => const Color(0xFF3D1800);
  static Color get primaryLight => const Color(0xFFF5E6D8);
  static Color get primaryMid => const Color(0xFFFFA726);

  // Surfaces
  static Color get background =>
      isDark ? AppColorsDark.background : AppColorsLight.background;
  static Color get surface =>
      isDark ? AppColorsDark.surface : AppColorsLight.surface;
  static Color get surfaceWarm =>
      isDark ? AppColorsDark.surfaceWarm : AppColorsLight.surfaceWarm;
  static Color get cardShadow =>
      isDark ? AppColorsDark.cardShadow : AppColorsLight.cardShadow;

  // Gradients (constant — used as decorative brand artwork in both themes)
  static List<Color> get headerGradient => const [
        Color(0xFF3D1800),
        Color(0xFF7B3A10),
        Color(0xFFE87722),
      ];
  static List<Color> get ctaGradient => const [
        Color(0xFFE87722),
        Color(0xFFFFA726),
      ];
  static List<Color> get cardGradient => const [
        Color(0xFF3D1800),
        Color(0xFF7B3A10),
      ];
  static List<Color> get zanaGradient => const [
        Color(0xFF1A0A00),
        Color(0xFF3D1800),
        Color(0xFF7B3A10),
      ];

  // Status
  static Color get success => const Color(0xFFE87722);
  static Color get successLight =>
      isDark ? AppColorsDark.successLight : AppColorsLight.successLight;
  static Color get profit => const Color(0xFF2E7D32);
  static Color get error => isDark ? AppColorsDark.error : AppColorsLight.error;
  static Color get errorLight =>
      isDark ? AppColorsDark.errorLight : AppColorsLight.errorLight;
  static Color get warning => const Color(0xFFE87722);
  static Color get warningLight =>
      isDark ? AppColorsDark.warningLight : AppColorsLight.warningLight;
  static Color get info => const Color(0xFF3D1800);
  static Color get infoLight =>
      isDark ? AppColorsDark.infoLight : AppColorsLight.infoLight;

  // Text
  static Color get textPrimary =>
      isDark ? AppColorsDark.textPrimary : AppColorsLight.textPrimary;
  static Color get textSecondary =>
      isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary;
  static Color get textTertiary =>
      isDark ? AppColorsDark.textTertiary : AppColorsLight.textTertiary;
  static Color get textOnPrimary => const Color(0xFFFFFFFF);
  static Color get textOnDark => const Color(0xFFFFFFFF);
  static Color get textHint =>
      isDark ? AppColorsDark.textHint : AppColorsLight.textHint;

  // Borders
  static Color get border =>
      isDark ? AppColorsDark.border : AppColorsLight.border;
  static Color get divider =>
      isDark ? AppColorsDark.divider : AppColorsLight.divider;
  static Color get inputBorder =>
      isDark ? AppColorsDark.inputBorder : AppColorsLight.inputBorder;

  // Zana (constant — Zana module keeps a fixed dark brand surface)
  static Color get zanaPrimary => const Color(0xFF3D1800);
  static Color get zanaLive => const Color(0xFFE87722);
  static Color get zanaSoon => const Color(0xFFE87722);
  static Color get zanaComingSoon => const Color(0xFF9E8070);
}

/// Concrete light-mode surface palette. Consumed by [AppColors] and by
/// [AppTheme.light] so both stay in sync from a single source of truth.
class AppColorsLight {
  AppColorsLight._();

  static const background = Color(0xFFFFF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFF0E6);
  static const cardShadow = Color(0x1AE87722);
  static const successLight = Color(0xFFF5E6D8);
  static const error = Color(0xFFB71C1C);
  static const errorLight = Color(0xFFFFEBEE);
  static const warningLight = Color(0xFFFFF0E6);
  static const infoLight = Color(0xFFF5E6D8);
  static const textPrimary = Color(0xFF1A0A00);
  static const textSecondary = Color(0xFF5C3D2E);
  static const textTertiary = Color(0xFF9E8070);
  static const textHint = Color(0xFFBDA99C);
  static const border = Color(0xFFE8D5C8);
  static const divider = Color(0xFFF0E4DA);
  static const inputBorder = Color(0xFFD4B8A8);
}

/// Concrete dark-mode surface palette. Consumed by [AppColors] and by
/// [AppTheme.dark] so both stay in sync from a single source of truth.
class AppColorsDark {
  AppColorsDark._();

  static const background = Color(0xFF14100D);
  static const surface = Color(0xFF211810);
  static const surfaceWarm = Color(0xFF2A1D12);
  static const cardShadow = Color(0x40000000);
  static const successLight = Color(0xFF33210F);
  static const error = Color(0xFFFF6659);
  static const errorLight = Color(0xFF3D1515);
  static const warningLight = Color(0xFF33210F);
  static const infoLight = Color(0xFF2A1F16);
  static const textPrimary = Color(0xFFF5EDE6);
  static const textSecondary = Color(0xFFD8C4B8);
  static const textTertiary = Color(0xFFA88F7D);
  static const textHint = Color(0xFF7A6656);
  static const border = Color(0xFF3D2E22);
  static const divider = Color(0xFF2E2117);
  static const inputBorder = Color(0xFF4A3728);
}
