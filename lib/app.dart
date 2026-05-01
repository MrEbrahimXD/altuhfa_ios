import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/launch/presentation/launch_screen.dart';

class TuhfaApp extends ConsumerWidget {
  const TuhfaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    final lightPalette = AppColors.dynamic(
      brightness: Brightness.light,
      accent: themeSettings.accentColor,
    );
    final darkPalette = AppColors.dynamic(
      brightness: Brightness.dark,
      accent: themeSettings.accentColor,
    );

    return MaterialApp(
      title: 'التحفة',
      debugShowCheckedModeBanner: false,
      themeMode: themeSettings.themeMode,
      theme: AppTheme.lightTheme(palette: lightPalette),
      darkTheme: AppTheme.darkTheme(palette: darkPalette),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final appChild = child ?? const SizedBox.shrink();
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final systemUiStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: theme.scaffoldBackgroundColor,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        );
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(themeSettings.fontScale),
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: systemUiStyle,
            child: appChild,
          ),
        );
      },
      themeAnimationDuration: const Duration(milliseconds: 280),
      themeAnimationCurve: Curves.easeOutCubic,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LaunchScreen(),
    );
  }
}
