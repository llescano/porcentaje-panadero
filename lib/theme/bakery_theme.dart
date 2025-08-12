import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'text_styles.dart';

class BakeryTheme {
  BakeryTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: BakeryColors.carameloSuave,
      scaffoldBackgroundColor: BakeryColors.cremaPanadero,
      cardColor: BakeryColors.panRecienHorneado,

      colorScheme: const ColorScheme.light(
        primary: BakeryColors.carameloSuave,
        secondary: BakeryColors.canela,
        surface: BakeryColors.panRecienHorneado,
        background: BakeryColors.cremaPanadero,
        error: Colors.red, // Or a custom error color
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: BakeryColors.maderaTostada,
        onBackground: BakeryColors.maderaTostada,
        onError: Colors.white,
        brightness: Brightness.light,
      ),

      textTheme: TextTheme(
        displayLarge: BakeryTextStyles.h1,
        displayMedium: BakeryTextStyles.h2,
        displaySmall: BakeryTextStyles.h3,
        headlineMedium: BakeryTextStyles.h1, // Mapping for older properties if needed
        headlineSmall: BakeryTextStyles.h2,
        titleLarge: BakeryTextStyles.h3,
        bodyLarge: BakeryTextStyles.bodyLarge,
        bodyMedium: BakeryTextStyles.bodyMedium,
        labelLarge: BakeryTextStyles.label,
      ).apply(
        bodyColor: BakeryColors.maderaTostada,
        displayColor: BakeryColors.maderaTostada,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: BakeryColors.carameloSuave,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: BakeryTextStyles.h2.copyWith(color: Colors.white),
        centerTitle: true,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BakeryColors.carameloSuave, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BakeryColors.carameloSuave, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BakeryColors.canela, width: 2),
        ),
        labelStyle: BakeryTextStyles.label,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BakeryColors.carameloSuave,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: BakeryTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
