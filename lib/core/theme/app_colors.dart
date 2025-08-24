import 'package:flutter/material.dart';

/// Paleta de colores inspirada en la cultura nicaragüense
class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF4A6192);      // Slate Blue oscuro
  static const Color primaryDark = Color(0xFF2E3A59);  // Charcoal
  static const Color accent = Color(0xFFA3B18A);       // Verde sage

  // Colores de identidad
  static const Color tierra = Color(0xFFB85C3C);       // Barro de artesanías
  static const Color jade = Color(0xFF177245);         // Piedra precolombina
  static const Color cacao = Color(0xFF3E2723);        // Cacao nicaragüense
  static const Color maiz = Color(0xFFF9A825);         // Maíz nicaragüense
  static const Color ceramica = Color(0xFFBC8F8F);     // Cerámica precolombina

  // Colores de fondo
  static const Color background = Color(0xFFF8F8F5);   // Blanco hueso
  static const Color surface = Colors.white;           // Blanco puro
  static const Color surfaceVariant = Color(0xFFF5F2EB); // Papel artesanal

  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1D25);    // Texto principal
  static const Color textSecondary = Color(0xFF7D8597);  // Texto secundario
  static const Color textLight = Color(0xFFFFFFFF);      // Texto claro

  // Colores de estado
  static const Color success = Color(0xFF2E7D32);      // Verde selva tropical
  static const Color error = Color(0xFFC62828);        // Rojo cerámica
  static const Color warning = maiz;                   // Amarillo maíz
  static const Color info = primary;                   // Azul primario

  // Colores para categorías
  static const Color historiaColor = cacao;            // Historias en café cacao
  static const Color tradicionColor = jade;            // Tradiciones en verde jade
  static const Color gastronomiaColor = tierra;        // Gastronomía en rojo tierra
  static const Color artesaniaColor = ceramica;        // Artesanías en tono cerámica
  static const Color leyendaColor = Color(0xFF6D4C41); // Leyendas en café oscuro
  static const Color danzaColor = Color(0xFFAD1457);   // Danzas en rojo violeta
  static const Color musicaColor = Color(0xFF1E88E5);  // Música en azul cielo

  // Colores para el modo oscuro
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Gradientes culturales
  static const LinearGradient nicaraguaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, Color(0xFF8A9A72)], // Verde sage oscuro
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFA726),  // Naranja atardecer
      Color(0xFFEF6C00),  // Naranja profundo
      tierra,             // Tierra nicaragüense
    ],
  );

  static const LinearGradient precolumbinoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      jade,              // Verde jade
      ceramica,          // Cerámica
      tierra,            // Tierra
    ],
  );

  // Opacidades comunes
  static const double opacity10 = 0.1;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity40 = 0.4;
  static const double opacity60 = 0.6;
  static const double opacity80 = 0.8;

  // Obtener color con opacidad
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Overlay para imágenes con texto
  static Color get imageOverlay => withOpacity(primaryDark, opacity30);

  // Colores para elementos de UI específicos
  static const Color cardShadow = Color(0x1A000000);     // Sombra de tarjetas
  static const Color divider = Color(0xFFE0E0E0);        // Divisores
  static const Color inputBorder = textSecondary;         // Bordes de inputs
  static const Color inputFocused = accent;               // Input con foco
  static const Color navigationInactive = textSecondary;  // Navegación inactiva
  static const Color navigationActive = accent;           // Navegación activa
}