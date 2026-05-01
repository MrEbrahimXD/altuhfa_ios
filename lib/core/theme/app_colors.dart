import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color accent;
  final Color accentLight;
  final Color text;
  final Color textSecondary;
  final Color card;
  final Color surface;
  final Color background;
  final Color activeVerse;
  final Color activeVerseBorder;

  const AppColors({
    required this.accent,
    required this.accentLight,
    required this.text,
    required this.textSecondary,
    required this.card,
    required this.surface,
    required this.background,
    required this.activeVerse,
    required this.activeVerseBorder,
  });

  static const light = AppColors(
    accent: Color(0xFF1B6B4A),
    accentLight: Color(0xFF2D8B62),
    text: Color(0xFF2C1810),
    textSecondary: Color(0xFF6B5E54),
    card: Color(0xFFFFF8F0),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFAF6F0),
    activeVerse: Color(0x141B6B4A),
    activeVerseBorder: Color(0x661B6B4A),
  );

  static const dark = AppColors(
    accent: Color(0xFF7DD8AE),
    accentLight: Color(0xFFA7E7C7),
    text: Color(0xFFF1F5F3),
    textSecondary: Color(0xFFB2C0B9),
    card: Color(0xFF1A2128),
    surface: Color(0xFF141B22),
    background: Color(0xFF0E141A),
    activeVerse: Color(0x297DD8AE),
    activeVerseBorder: Color(0x807DD8AE),
  );

  static AppColors dynamic({
    required Brightness brightness,
    required Color accent,
  }) {
    final base = brightness == Brightness.dark ? dark : light;
    final resolvedAccent =
        brightness == Brightness.dark ? _tuneDarkAccent(accent) : accent;
    final hsl = HSLColor.fromColor(resolvedAccent);
    final accentLight = hsl
        .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0).toDouble())
        .withLightness(
          (hsl.lightness + (brightness == Brightness.dark ? 0.16 : 0.12))
              .clamp(0.0, 1.0)
              .toDouble(),
        )
        .toColor();

    Color blend(Color surface, double amount) {
      return Color.alphaBlend(
          resolvedAccent.withValues(alpha: amount), surface);
    }

    return base.copyWith(
      accent: resolvedAccent,
      accentLight: accentLight,
      background:
          blend(base.background, brightness == Brightness.dark ? 0.035 : 0.05),
      surface:
          blend(base.surface, brightness == Brightness.dark ? 0.055 : 0.07),
      card: blend(base.card, brightness == Brightness.dark ? 0.08 : 0.1),
      activeVerse: resolvedAccent.withValues(
        alpha: brightness == Brightness.dark ? 0.18 : 0.12,
      ),
      activeVerseBorder: resolvedAccent.withValues(
        alpha: brightness == Brightness.dark ? 0.56 : 0.4,
      ),
    );
  }

  static Color _tuneDarkAccent(Color accent) {
    final hsl = HSLColor.fromColor(accent);
    final tunedSaturation =
        (hsl.saturation * 0.82).clamp(0.35, 0.82).toDouble();
    final tunedLightness = hsl.lightness.clamp(0.48, 0.7).toDouble();
    return hsl
        .withSaturation(tunedSaturation)
        .withLightness(tunedLightness)
        .toColor();
  }

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentLight,
    Color? text,
    Color? textSecondary,
    Color? card,
    Color? surface,
    Color? background,
    Color? activeVerse,
    Color? activeVerseBorder,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      card: card ?? this.card,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      activeVerse: activeVerse ?? this.activeVerse,
      activeVerseBorder: activeVerseBorder ?? this.activeVerseBorder,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      activeVerse: Color.lerp(activeVerse, other.activeVerse, t)!,
      activeVerseBorder:
          Color.lerp(activeVerseBorder, other.activeVerseBorder, t)!,
    );
  }
}
