import 'package:flutter/material.dart';

/// Sistema de espaciado y dimensiones de la aplicación
class AppSpacing {
  // Espaciado base
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Radios de borde
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusCircular = 999.0;

  // Elevaciones
  static const double elevationXs = 2.0;
  static const double elevationSm = 4.0;
  static const double elevationMd = 8.0;
  static const double elevationLg = 16.0;
  static const double elevationXl = 24.0;

  // Tamaños de iconos
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // Dimensiones de componentes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;
  static const double cardMinHeight = 80.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double fabSize = 56.0;

  // Márgenes y paddings comunes
  static const EdgeInsets marginXs = EdgeInsets.all(xs);
  static const EdgeInsets marginSm = EdgeInsets.all(sm);
  static const EdgeInsets marginMd = EdgeInsets.all(md);
  static const EdgeInsets marginLg = EdgeInsets.all(lg);
  static const EdgeInsets marginXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Márgenes horizontales y verticales
  static const EdgeInsets marginHorizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets marginHorizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets marginHorizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets marginHorizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets marginHorizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets marginVerticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets marginVerticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets marginVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets marginVerticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets marginVerticalXl = EdgeInsets.symmetric(vertical: xl);

  // Dimensiones responsivas
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  static double responsiveWidth(BuildContext context, double percentage) =>
      screenWidth(context) * percentage;

  static double responsiveHeight(BuildContext context, double percentage) =>
      screenHeight(context) * percentage;
}
