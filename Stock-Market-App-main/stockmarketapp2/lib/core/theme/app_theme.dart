// lib/core/theme/app_theme.dart

/*
  app_theme.dart – Centralized Color Palette & Theme Configuration

  • Defines AppColors, grouping all custom colors:
    – textHigh / textMedium for contrast levels
    – errorRed and downwardMovement / upwardMovement for alerts & trends
    – Borders1 / Borders2 for outlines
    – cardBackground for surfaces
    – primaryAccent for highlights
    – backgroundGradient & backgroundGradient2 for multi-stop backgrounds
    – backgroundStart / backgroundEnd for simple two-color gradients

  • (Optional) appTextTheme: a reusable TextTheme example,
    illustrating consistent font sizes, weights, and color usage.

  • buildAppTheme():
    – Returns a dark-mode ThemeData
    – Sets scaffoldBackgroundColor to transparent so the gradient shows through
    – Applies a custom fontFamily (e.g. 'DM_Sans')
    – Uses the AppColors palette in TextTheme and ColorScheme.dark
    – Ensures buttons, cards, and surfaces all follow the same design tokens

  By importing and using buildAppTheme() in your MaterialApp,
  the entire app adheres to a single, maintainable design system.
*/

import 'package:flutter/material.dart';

class AppColors {
  // ─── Main Text Colors ──────────────────────────────────────────────────────

  /// Primary (high-contrast) text color: 0xFFFFFFFF
  static const Color textHigh = Color(0xFFFFFFFF);

  /// Secondary (lighter) text color: 0xFFC4C4CC
  static const Color textMedium = Color(0xFFC4C4CC);

  /// Error or negative indicator color: 0xFFE84A5F
  static const Color errorRed = Color(0xFFE84A5F);

  /// Color for downward movement: 0xFFE84A5F
  static const Color downwardMovement = Color(0xFFE84A5F);

  /// Color for upward movement: 0xFF42B883
  static const Color upwardMovement = Color(0xFF42B883);

  //Borders
  static const Color Borders1 = Color(0xFF6660B3);

  //Borders
  static const Color Borders2 = Color(0xFF444255);

  // ─── Card & Surface Colors ─────────────────────────────────────────────────

  /// Card background color (dark grey): 0xFF0C0C0C
  static const Color cardBackground = Color(0xFF090534);

  // ─── Background Gradient Colors ────────────────────────────────────────────

  /// A list of colors (top to bottom) for the app’s main background gradient:
  /// [0] 0xFF180E8D
  /// [1] 0xFF160D80
  /// [2] 0xFF140C74
  /// [3] 0xFF10095A
  /// [4] 0xFF0D084D
  /// [5] 0xFF0B0741
  /// [6] 0xFF090534
  /// [7] 0xFF070427
  static const List<Color> backgroundGradient2 = <Color>[
    Color(0xFF5F88BB),
    Color(0xFF3A619E),
    Color(0xFF294381),
    Color(0xFF212F6F),
    Color(0xFF1D2666),
  ];

  static const List<Color> backgroundGradient = <Color>[
    Color(0xFF070427),
    Color(0xFF090534),
    Color(0xFF0B0741),
    Color(0xFF0D084D),
    Color(0xFF10095A),
    Color(0xFF140C74),
    Color(0xFF160D80),
    Color(0xFF180E8D),
  ];


  static const Color backgroundStart = Color(0xFF180E8D);
  static const Color backgroundEnd   = Color(0xFF070427);


  static const Color backgroundStart2 = Color(0xFF5F88BB);
  static const Color backgroundEnd2   = Color(0xFF1D2666);

  /// Accent color used for highlights and outlines (e.g., purple borders):
  static const Color primaryAccent = Color(0xFF584AFF);
}

/// (Optional) A centralized TextTheme you can use throughout the app.
/// Uncomment and customize as desired.
/*
final TextTheme appTextTheme = TextTheme(
  headlineLarge: TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textHigh,
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textHigh,
  ),
  bodyLarge: TextStyle(
    fontSize: 16,
    color: AppColors.textHigh,
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    color: AppColors.textMedium,
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    color: AppColors.textMedium,
  ),
  // …add other styles as needed…
);
*/

/// A complete ThemeData you can apply to MaterialApp if desired:
ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // let gradient shine through
    fontFamily: 'DM_Sans', // or whichever font you prefer
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: AppColors.textHigh,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textHigh,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textHigh,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textMedium,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textMedium,
      ),
    ),
    // Example: apply the primaryAccent to button themes, etc.
    primaryColor: AppColors.primaryAccent,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryAccent,
      onPrimary: AppColors.textHigh,
      background: AppColors.backgroundStart,
      onBackground: AppColors.textHigh,
      surface: AppColors.cardBackground,
      onSurface: AppColors.textHigh,
    ),
    // Further theming (e.g. ElevatedButtonTheme) can be added here…
  );
}
