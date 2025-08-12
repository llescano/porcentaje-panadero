import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class BakeryTextStyles {
  // Evita que la clase sea instanciada.
  BakeryTextStyles._();

  static TextStyle get h1 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: BakeryColors.maderaTostada,
      );

  static TextStyle get h2 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: BakeryColors.maderaTostada,
      );

  static TextStyle get h3 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: BakeryColors.maderaTostada,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BakeryColors.maderaTostada,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BakeryColors.chocolateOscuro,
      );

  static TextStyle get label => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BakeryColors.canela,
      );
}
