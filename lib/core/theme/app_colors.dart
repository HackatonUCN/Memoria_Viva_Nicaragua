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

  // Colores para categorías (afinados para armonizar con primario/acento en light y dark)
  static const Color historiaColor = Color(0xFFDAA520);     // Historia: dorado (goldenrod)
  static const Color tradicionColor = Color(0xFF2A9D8F);    // Tradición: verde-azulado (teal)
  static const Color gastronomiaColor = Color(0xFFE76F51);  // Gastronomía: coral cálido
  static const Color artesaniaColor = Color(0xFFC97C5D);    // Artesanía: terracota
  static const Color leyendaColor = Color(0xFF7E57C2);      // Leyenda: púrpura místico
  static const Color danzaColor = Color(0xFFD81B60);        // Danza: fucsia intenso
  static const Color musicaColor = Color(0xFF1E88E5);       // Música: azul vibrante
  
  // Colores para categorías de eventos
  static const Color eventoFestividadesColor = Color(0xFFF57C00); // Festividades: naranja
  static const Color eventoConciertosColor = Color(0xFFD81B60);   // Conciertos: magenta
  static const Color eventoTalleresColor = Color(0xFF8E24AA);     // Talleres: púrpura
  static const Color eventoExposicionesColor = Color(0xFF5E35B1); // Exposiciones: índigo
  static const Color eventoGastronomiaColor = Color(0xFFFB8C00);  // Gastronomía: naranja ámbar
  static const Color eventoDanzaColor = Color(0xFFD81B60);        // Danza: fucsia intenso

  // Colores para el modo oscuro
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Elementos de UI en modo oscuro
  static const Color darkCardShadow = Color(0x66000000);     // Sombra de tarjetas en dark
  static const Color darkDivider = Color(0xFF2E2E2E);         // Divisores en dark
  static const Color darkInputBorder = darkTextSecondary;     // Bordes de inputs en dark
  static const Color darkInputFocused = accent;               // Input con foco en dark
  static const Color darkNavigationInactive = darkTextSecondary; // Navegación inactiva en dark
  static const Color darkNavigationActive = accent;           // Navegación activa en dark

  // Fallback de colores por categoría (IDs del seed)
  static const Map<String, Color> categoryFallbacks = {
    'relato_tradiciones': Color(0xFF2A9D8F),
    'relato_costumbres': Color(0xFFF4A261),
    'saber_recetas': Color(0xFFFF7043),
    'evento_festividades': eventoFestividadesColor,
    'evento_conciertos': eventoConciertosColor,
    'evento_talleres': eventoTalleresColor,
    'evento_exposiciones': eventoExposicionesColor,
    'evento_gastronomia': eventoGastronomiaColor,
    'evento_danza': eventoDanzaColor,
    'relato_leyendas_mitos': Color(0xFF7E57C2),
    'relato_historia_oral': Color(0xFFDAA520),
    'relato_personajes': Color(0xFF8D6E63),
    'relato_memorias_comunitarias': Color(0xFF66BB6A),
    'saber_dichos_refranes': Color(0xFFFFB300),
    'saber_artesanias': Color(0xFFC97C5D),
    'saber_medicina_tradicional': Color(0xFF2E7D32),
    'saber_gastronomia': Color(0xFFE76F51),
    'saber_agricultura': Color(0xFF7CB342),
    'saber_musica_danza': Color(0xFF1E88E5),
    'saber_juegos_tradicionales': Color(0xFF26C6DA),
  };

  /// Devuelve el color de categoría usando hexadecimal (si viene de Firestore) o fallback por id
  static Color categoryColor({required String categoryId, String? hex}) {
    if (hex != null && hex.isNotEmpty) {
      String value = hex;
      if (value.startsWith('#')) value = value.substring(1);
      if (value.length == 6) value = 'FF$value';
      try {
        return Color(int.parse(value, radix: 16));
      } catch (_) {}
    }
    return categoryFallbacks[categoryId] ?? accent;
  }

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