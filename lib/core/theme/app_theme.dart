import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
// App Colors
// ─────────────────────────────────────────────

/// Central color palette for Karakana by Kreative Karakana.
///
/// Always reference these constants instead of inline hex values so that
/// a brand-color update only needs to happen in one place.
class AppColors {
  AppColors._();

  /// Primary brand orange — used for buttons, icons, and active states.
  static final Color primary = Color(0xFFC4620A);

  /// Dark brown — used for headings, app bar text, and dark backgrounds.
  static final Color dark = Color(0xFF3B1A08);

  /// Light orange tint — used as form field fill and card backgrounds.
  static final Color lightOrange = Color(0xFFF5E6D8);

  /// Mid orange — used for secondary accents and illustration highlights.
  static final Color midOrange = Color(0xFFE8A96A);

  /// Pure white — used for text on dark/orange surfaces and backgrounds.
  static final Color white = Color(0xFFFFFFFF);

  /// Medium grey — used for body text, subtitles, and placeholder text.
  static final Color grey = Color(0xFF666666);

  /// Light grey — used for dividers, subtle backgrounds, and disabled states.
  static final Color lightGrey = Color(0xFFF7F7F7);

  /// Error red — used for validation messages and destructive actions.
  static final Color error = Color(0xFFC62828);

  /// Success green — used for confirmation messages and success states.
  static final Color success = Color(0xFF2E7D32);
}

// ─────────────────────────────────────────────
// App Theme
// ─────────────────────────────────────────────

/// Provides the single [ThemeData] used throughout the Karakana app.
///
/// Typography: Poppins (headings/labels) + Inter (body/captions).
/// Pass [AppTheme.theme] to [MaterialApp.theme] in `main.dart`.
class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      // ── Color scheme ────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        error: AppColors.error,
      ),

      scaffoldBackgroundColor: AppColors.white,

      // ── Typography ──────────────────────────
      // Headings and titles use Poppins; body and captions use Inter.
      textTheme: TextTheme(
        // Display — large marketing / hero text (Poppins)
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.dark,
        ),

        // Headline — screen titles and section headers (Poppins)
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.dark,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),

        // Title — card titles and list item headings (Poppins)
        titleLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.dark,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.dark,
        ),

        // Body — general readable text (Inter)
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.dark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.dark,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.grey,
        ),

        // Label — captions, chips, and helper text
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.grey,
        ),
      ),

      // ── App bar ─────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),

      // ── Elevated button ─────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input decoration ────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightOrange,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.grey),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      // ── Bottom navigation bar ────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Card ────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
