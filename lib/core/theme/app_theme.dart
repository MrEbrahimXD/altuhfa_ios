import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static const darkBackground = Color(0xFF0E141A);
  static const darkSurface = Color(0xFF141B22);
  static const darkCard = Color(0xFF1A2128);
  static const darkAccent = Color(0xFF7DD8AE);
  static const darkAccentLight = Color(0xFFA7E7C7);
  static const darkText = Color(0xFFF1F5F3);
  static const darkTextSecondary = Color(0xFFB2C0B9);

  static const lightBackground = Color(0xFFFAF6F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFF8F0);
  static const lightAccent = Color(0xFF1B6B4A);
  static const lightAccentLight = Color(0xFF2D8B62);
  static const lightText = Color(0xFF2C1810);
  static const lightTextSecondary = Color(0xFF6B5E54);

  static ThemeData lightTheme({AppColors? palette}) {
    return _buildTheme(
      brightness: Brightness.light,
      palette: palette ?? AppColors.light,
    );
  }

  static ThemeData darkTheme({AppColors? palette}) {
    return _buildTheme(
      brightness: Brightness.dark,
      palette: palette ?? AppColors.dark,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required AppColors palette,
  }) {
    final isDark = brightness == Brightness.dark;
    Color onColor(Color color) {
      return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    final baseTextTheme = isDark
        ? ThemeData.dark(useMaterial3: true).textTheme
        : ThemeData.light(useMaterial3: true).textTheme;

    final textTheme = GoogleFonts.amiriTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.amiri(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: palette.accent,
      ),
      headlineMedium: GoogleFonts.amiri(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: palette.text,
      ),
      titleLarge: GoogleFonts.amiri(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: palette.accent,
      ),
      bodyLarge: GoogleFonts.amiri(
        fontSize: 24,
        color: palette.text,
        height: 2.0,
      ),
      bodyMedium: GoogleFonts.amiri(
        fontSize: 18,
        color: palette.textSecondary,
        height: 1.8,
      ),
      labelLarge: GoogleFonts.amiri(
        fontSize: 16,
        color: palette.textSecondary,
        height: 1.5,
      ),
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      primary: palette.accent,
      secondary: palette.accentLight,
      surface: palette.surface,
      onPrimary: onColor(palette.accent),
      onSecondary: onColor(palette.accentLight),
      onSurface: palette.text,
      outline: palette.accent.withValues(alpha: 0.24),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      extensions: [palette],
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: palette.background,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.amiri(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: palette.accent,
        ),
        iconTheme: IconThemeData(color: palette.accent),
        actionsIconTheme: IconThemeData(color: palette.accent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.amiri(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.surface,
        contentTextStyle: GoogleFonts.amiri(
          fontSize: 16,
          color: palette.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: palette.textSecondary.withValues(alpha: 0.35),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.accent.withValues(alpha: 0.14),
      ),
      listTileTheme: ListTileThemeData(
        textColor: palette.text,
        iconColor: palette.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: GoogleFonts.amiri(
          fontSize: 15,
          color: palette.textSecondary.withValues(alpha: 0.7),
        ),
        labelStyle: GoogleFonts.amiri(
          fontSize: 15,
          color: palette.textSecondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          textStyle: GoogleFonts.amiri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: scheme.onPrimary,
          textStyle: GoogleFonts.amiri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.accent,
          side: BorderSide(color: palette.accent.withValues(alpha: 0.35)),
          textStyle: GoogleFonts.amiri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: GoogleFonts.amiri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent;
          }
          return palette.textSecondary.withValues(alpha: 0.8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.accent.withValues(alpha: 0.35);
          }
          return palette.textSecondary.withValues(alpha: 0.25);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.accent,
        inactiveTrackColor: palette.accent.withValues(alpha: 0.2),
        thumbColor: palette.accent,
        overlayColor: palette.accent.withValues(alpha: 0.14),
        trackHeight: 3,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.accent.withValues(alpha: 0.14),
        circularTrackColor: palette.accent.withValues(alpha: 0.14),
      ),
    );
  }

  static Color highlightColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkAccent.withValues(alpha: 0.18)
        : lightAccent.withValues(alpha: 0.08);
  }

  static Color accentColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkAccent : lightAccent;
  }

  static Color activeVerseColor(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkAccent.withValues(alpha: 0.15)
        : lightAccent.withValues(alpha: 0.08);
  }

  static Color activeVerseBorder(Brightness brightness) {
    return brightness == Brightness.dark
        ? darkAccent.withValues(alpha: 0.5)
        : lightAccent.withValues(alpha: 0.4);
  }
}
