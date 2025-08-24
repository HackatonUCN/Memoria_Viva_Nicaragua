import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía de la aplicación
class AppTypography {
  // Fuentes principales
  static final TextTheme textTheme = TextTheme(
    // Títulos grandes
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 45,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),

    // Títulos
    headlineLarge: GoogleFonts.lato(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineMedium: GoogleFonts.lato(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),
    headlineSmall: GoogleFonts.lato(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    ),

    // Títulos de nivel medio
    titleLarge: GoogleFonts.lato(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    titleMedium: GoogleFonts.lato(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),

    // Cuerpo de texto
    bodyLarge: GoogleFonts.lato(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.lato(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),

    // Etiquetas y botones
    labelLarge: GoogleFonts.lato(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.lato(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.lato(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  // Estilos específicos para relatos
  static final TextStyle storyTitle = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static final TextStyle storyContent = GoogleFonts.lora(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.6,
  );

  // Estilos para fechas y metadata
  static final TextStyle metadata = GoogleFonts.lato(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
  );

  // Estilos para citas y testimonios
  static final TextStyle quote = GoogleFonts.merriweather(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.5,
    height: 1.6,
  );
}
