import 'package:flutter/material.dart';

class AccentOption {
  final Color color;
  final String androidAlias;

  const AccentOption({
    required this.color,
    required this.androidAlias,
  });
}

class AccentPalette {
  static const int defaultAccentValue = 0xFF1B6B4A;
  static const Color defaultAccent = Color(defaultAccentValue);

  static const List<AccentOption> options = [
    AccentOption(
      color: Color(0xFF1B6B4A),
      androidAlias: 'MainActivityIconGreen',
    ),
    AccentOption(
      color: Color(0xFF0D9488),
      androidAlias: 'MainActivityIconTeal',
    ),
    AccentOption(
      color: Color(0xFF2563EB),
      androidAlias: 'MainActivityIconBlue',
    ),
    AccentOption(
      color: Color(0xFF4F46E5),
      androidAlias: 'MainActivityIconIndigo',
    ),
    AccentOption(
      color: Color(0xFFB45309),
      androidAlias: 'MainActivityIconAmber',
    ),
    AccentOption(
      color: Color(0xFFEA580C),
      androidAlias: 'MainActivityIconOrange',
    ),
    AccentOption(
      color: Color(0xFFC026D3),
      androidAlias: 'MainActivityIconFuchsia',
    ),
    AccentOption(
      color: Color(0xFFBE123C),
      androidAlias: 'MainActivityIconRose',
    ),
    AccentOption(
      color: Color(0xFFDC2626),
      androidAlias: 'MainActivityIconRed',
    ),
    AccentOption(
      color: Color(0xFF0891B2),
      androidAlias: 'MainActivityIconCyan',
    ),
    AccentOption(
      color: Color(0xFF5B21B6),
      androidAlias: 'MainActivityIconViolet',
    ),
    AccentOption(
      color: Color(0xFF334155),
      androidAlias: 'MainActivityIconSlate',
    ),
  ];

  static int encodeColor(Color color) {
    final a = (color.a * 255).round() & 0xff;
    final r = (color.r * 255).round() & 0xff;
    final g = (color.g * 255).round() & 0xff;
    final b = (color.b * 255).round() & 0xff;
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  static String androidAliasForColor(Color color) {
    final encoded = encodeColor(color);
    for (final option in options) {
      if (encodeColor(option.color) == encoded) {
        return option.androidAlias;
      }
    }
    return options.first.androidAlias;
  }

  static List<String> get androidAliases {
    return options.map((option) => option.androidAlias).toList(growable: false);
  }
}
