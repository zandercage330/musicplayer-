import 'package:flutter/material.dart';

class AppColors {
  // Primary & Accent Colors
  static const Color primaryColor = Color(0xFF34D1BF);
  static const Color accentColor = Color(0xFF22C3B1);

  // Background Colors
  static const Color backgroundColor = Color(0xFF070707);

  // Text Colors
  static const Color primaryTextColor = Color(0xFFFAFAFA);
  static const Color secondaryTextColor = Color(
    0xFFEAEAEA,
  ); // From text style.txt, similar to EBEBEB
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightGrayTextColor = Color(0xFFD9D9D9);

  // Other Palette Colors from Figma
  static const Color selectionWhite = Color(
    0xFFFAFAFA,
  ); // Same as primaryTextColor
  static const Color selectionTeal1 = Color(0xFF34D1BF); // Same as primaryColor
  static const Color selectionGray1 = Color(
    0xFFD9D9D9,
  ); // Same as lightGrayTextColor
  static const Color selectionPureWhite = Color(
    0xFFFFFFFF,
  ); // Same as whiteColor
  static const Color selectionGray2 = Color(0xFFEBEBEB);
  static const Color selectionBlack = Color(
    0xFF070707,
  ); // Same as backgroundColor
  static const Color selectionTeal2 = Color(0xFF22C3B1); // Same as accentColor

  static const Color darkGrayTransparent = Color(
    0x33333333,
  ); // #333333 with 20% opacity

  static const Color mutedPink = Color(0xFF9F8282);
  static const Color lightBlueGray = Color(0xFFA7CDCF);
  static const Color lightPurplePink = Color(0xFFCDA4D4);
  static const Color lightPink = Color(0xFFDFB2B2);

  // Common Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Semantic Colors (can be defined later or refined if specific roles are known)
  // static const Color errorColor = Color(0xFFYourErrorColor); // Example
  // static const Color successColor = Color(0xFFYourSuccessColor); // Example
  // static const Color warningColor = Color(0xFFYourWarningColor); // Example
}

// Basic ThemeData can be defined here later in Subtask 2.3
// For now, focusing on getting the color palette right for Subtask 2.1

class AppTextStyles {
  static const String _fontFamily = 'Oxygen';

  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.secondaryTextColor, // 0xFFEAEAEA
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.50,
  );

  static const TextStyle subtitle1Bold = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.whiteColor, // Colors.white
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const TextStyle bodyText1Bold = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.primaryTextColor, // 0xFFFAFAFA
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );

  static const TextStyle captionRegular = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.whiteColor, // Colors.white
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.15,
  );

  static const TextStyle bodyText2Bold = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.primaryTextColor, // 0xFFFAFAFA
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.50,
  );

  static const TextStyle logoText1 = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.secondaryTextColor, // 0xFFEAEAEA
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.50,
  );

  static const TextStyle logoText2 = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.accentColor, // 0xFF22C3B1
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.50,
  );

  static const TextStyle navLabelSelected = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.primaryColor, // 0xFF34D1BF
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle navLabelUnselected = TextStyle(
    fontFamily: _fontFamily,
    color: AppColors.primaryTextColor, // 0xFFFAFAFA
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: AppTextStyles._fontFamily,
  primaryColor: AppColors.primaryColor,
  scaffoldBackgroundColor: AppColors.backgroundColor,
  // accentColor is deprecated, use colorScheme.secondary instead
  // accentColor: AppColors.accentColor,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryColor,
    secondary: AppColors.accentColor,
    surface:
        AppColors
            .backgroundColor, // Or a slightly different dark color if available
    onPrimary: AppColors.white, // Text/icon color on primary color
    onSecondary: AppColors.white, // Text/icon color on secondary color
    onSurface: AppColors.primaryTextColor, // Text/icon color on surface
    onError: AppColors.white, // Text/icon color on error color
    // error: AppColors.errorColor, // Define if you have a specific error color
  ),
  textTheme: const TextTheme(
    // Mapping based on typical usage and size/weight from AppTextStyles
    displayLarge:
        AppTextStyles
            .headline1, // Usually for very large text, like a splash screen title
    displayMedium: AppTextStyles.headline1, // Could be refined
    displaySmall: AppTextStyles.headline1, // Could be refined

    headlineLarge: AppTextStyles.headline1,
    headlineMedium:
        AppTextStyles.headline1, // fontSize: 24, fontWeight: FontWeight.w700
    headlineSmall:
        AppTextStyles
            .bodyText1Bold, // fontSize: 16, fontWeight: FontWeight.w700

    titleLarge:
        AppTextStyles.bodyText1Bold, // For screen titles, list item titles
    titleMedium:
        AppTextStyles
            .bodyText2Bold, // fontSize: 14, fontWeight: FontWeight.w700
    titleSmall:
        AppTextStyles
            .subtitle1Bold, // fontSize: 12, fontWeight: FontWeight.w700

    bodyLarge: AppTextStyles.bodyText2Bold, // Default for larger body text
    bodyMedium:
        AppTextStyles
            .bodyText2Bold, // Default for standard body text (can be regular weight too)
    bodySmall:
        AppTextStyles
            .captionRegular, // fontSize: 12, fontWeight: FontWeight.w400

    labelLarge: AppTextStyles.bodyText1Bold, // For buttons
    labelMedium: AppTextStyles.subtitle1Bold,
    labelSmall:
        AppTextStyles.captionRegular, // For very small labels, like bottom nav
  ),
  // Other theme properties like appBarTheme, buttonTheme, cardTheme will be handled in Subtask 2.4
  appBarTheme: AppBarTheme(
    backgroundColor:
        AppColors.backgroundColor, // Or a slightly different shade if specified
    elevation: 0, // Flat app bars are common in dark themes
    iconTheme: const IconThemeData(color: AppColors.primaryTextColor),
    titleTextStyle: AppTextStyles.bodyText1Bold.copyWith(
      color: AppColors.primaryTextColor,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.white, // Text color for elevated button
      textStyle: AppTextStyles.bodyText1Bold.copyWith(color: AppColors.white),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Example border radius
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.selectionBlack.withAlpha(26), // Subtle fill
    hintStyle: AppTextStyles.captionRegular.copyWith(
      color: AppColors.lightGrayTextColor,
    ),
    labelStyle: AppTextStyles.bodyText2Bold.copyWith(
      color: AppColors.primaryTextColor,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none, // No border by default for a cleaner look
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
    ),
    errorStyle: AppTextStyles.captionRegular.copyWith(
      color: Colors.redAccent,
    ), // Example error color
  ),
  cardTheme: CardTheme(
    color: AppColors.selectionBlack.withAlpha(13), // Slightly off-background
    elevation: 0, // Often flat in dark themes, or very subtle
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Example border radius
    ),
    margin: const EdgeInsets.all(8), // Default margin for cards
  ),
);
