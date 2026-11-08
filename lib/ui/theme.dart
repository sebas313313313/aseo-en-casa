import 'package:flutter/material.dart';

class AppColors {
  static const blue = Color(0xFF0A84FF);
  static const indigo = Color(0xFF5E5CE6);
  static const purple = Color(0xFFBF5AF2);
  static const pink = Color(0xFFFF375F);
  static const orange = Color(0xFFFF9F0A);
  static const yellow = Color(0xFFFFD60A);
  static const green = Color(0xFF30D158);
  static const teal = Color(0xFF64D2FF);
  static const red = Color(0xFFFF453A);

  static const lightBg = Color(0xFFF4F4F7);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCardAlt = Color(0xFFF2F2F7);
  static const lightText = Color(0xFF1C1C1E);
  static const lightSecondary = Color(0xFF6E6E73);
  static const lightTertiary = Color(0xFF8E8E93);

  static const darkBg = Color(0xFF0B0B0F);
  static const darkCard = Color(0xFF1C1C1E);
  static const darkCardAlt = Color(0xFF2C2C2E);
  static const darkText = Color(0xFFF5F5F7);
  static const darkSecondary = Color(0xFFA1A1A6);
  static const darkTertiary = Color(0xFF6E6E73);

  static const separatorLight = Color(0x14000000);
  static const separatorDark = Color(0x1AFFFFFF);
}

extension AppThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get appBg => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get appCard => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get appCardAlt => isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
  Color get appText => isDark ? AppColors.darkText : AppColors.lightText;
  Color get appSecondary =>
      isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  Color get appTertiary =>
      isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
  Color get appSeparator =>
      isDark ? AppColors.separatorDark : AppColors.separatorLight;
  Color get appAccent => Theme.of(this).colorScheme.primary;
  Color get appShadow => Colors.black.withValues(alpha: isDark ? 0.4 : 0.06);
  Color soft(Color color, [double alpha = 0.14]) =>
      color.withValues(alpha: isDark ? alpha + 0.06 : alpha);
}

class AppTheme {
  static const String fontFamily = 'Segoe UI Variable Display';
  static const List<String> fontFallback = [
    'SF Pro Display',
    'SF Pro Text',
    'Segoe UI Variable Text',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
  ];

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static TextStyle _style(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFallback,
      );

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final secondary = isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final cardAlt = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.blue.withValues(alpha: isDark ? 0.22 : 0.12),
      onPrimaryContainer: isDark ? Colors.white : AppColors.blue,
      secondary: AppColors.orange,
      onSecondary: Colors.black,
      secondaryContainer:
          AppColors.orange.withValues(alpha: isDark ? 0.24 : 0.15),
      onSecondaryContainer: isDark ? Colors.white : const Color(0xFF8A4B00),
      tertiary: AppColors.purple,
      onTertiary: Colors.white,
      tertiaryContainer:
          AppColors.purple.withValues(alpha: isDark ? 0.24 : 0.14),
      onTertiaryContainer: isDark ? Colors.white : AppColors.purple,
      error: AppColors.red,
      onError: Colors.white,
      errorContainer: AppColors.red.withValues(alpha: 0.16),
      onErrorContainer: isDark ? Colors.white : AppColors.red,
      surface: card,
      onSurface: text,
      surfaceContainerHighest: cardAlt,
      onSurfaceVariant: secondary,
      outline: isDark ? AppColors.separatorDark : AppColors.separatorLight,
      outlineVariant: isDark ? const Color(0x12FFFFFF) : const Color(0x0D000000),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.lightCard : AppColors.darkCard,
      onInverseSurface: isDark ? AppColors.lightText : AppColors.darkText,
      inversePrimary: AppColors.blue,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
    );

    final textTheme = TextTheme(
      displayLarge:
          _style(44, FontWeight.w700, text, height: 1.02, letterSpacing: -1.6),
      displayMedium:
          _style(34, FontWeight.w700, text, height: 1.08, letterSpacing: -1.1),
      displaySmall:
          _style(28, FontWeight.w700, text, height: 1.1, letterSpacing: -0.8),
      headlineLarge:
          _style(26, FontWeight.w700, text, height: 1.12, letterSpacing: -0.6),
      headlineMedium:
          _style(22, FontWeight.w700, text, height: 1.15, letterSpacing: -0.4),
      headlineSmall:
          _style(20, FontWeight.w600, text, height: 1.2, letterSpacing: -0.2),
      titleLarge:
          _style(18, FontWeight.w600, text, height: 1.2, letterSpacing: -0.2),
      titleMedium:
          _style(17, FontWeight.w600, text, height: 1.25, letterSpacing: -0.1),
      titleSmall: _style(15, FontWeight.w600, text, height: 1.25),
      bodyLarge: _style(17, FontWeight.w400, text, height: 1.42),
      bodyMedium: _style(15, FontWeight.w400, text, height: 1.42),
      bodySmall: _style(13, FontWeight.w400, secondary, height: 1.38),
      labelLarge: _style(16, FontWeight.w600, text, height: 1.2),
      labelMedium: _style(13, FontWeight.w600, text, height: 1.2),
      labelSmall: _style(11, FontWeight.w600, secondary,
          height: 1.2, letterSpacing: 0.5),
    );

    final radius = BorderRadius.circular(16);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.separatorDark : AppColors.separatorLight,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: text, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: secondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: secondary),
        prefixIconColor: secondary,
        suffixIconColor: secondary,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: isDark ? AppColors.separatorDark : const Color(0x0F000000),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.red, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.red),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.darkCardAlt : const Color(0xFFD9D9DE),
          disabledForegroundColor:
              isDark ? AppColors.darkTertiary : Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _style(16, FontWeight.w600, Colors.white),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: _style(15, FontWeight.w600, AppColors.blue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size.fromHeight(50),
          side: BorderSide(
            color: isDark ? AppColors.separatorDark : const Color(0x14000000),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: _style(15, FontWeight.w600, text),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkCardAlt : const Color(0xFF1C1C1E),
        contentTextStyle: _style(14, FontWeight.w500, Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actionTextColor: AppColors.teal,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.blue,
        linearTrackColor: Color(0x1A000000),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(8),
        thumbColor: WidgetStateProperty.all(
          (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
