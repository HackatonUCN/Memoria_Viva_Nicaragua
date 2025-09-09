import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CulturalIcon extends StatelessWidget {
  final String svgPath;
  final double size;
  final Color? color;

  const CulturalIcon({
    super.key,
    required this.svgPath,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Color explícito para teñir SVGs con rellenos fijos (opcional)
    final Color? explicitColor = color;
    // Color heredado/base para currentColor en SVGs (no nulo)
    final Color resolvedCurrentColor =
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).iconTheme.color ??
        Colors.black;

    return SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      // Solo aplicar tinte cuando se pasa color explícito.
      colorFilter: explicitColor != null
          ? ColorFilter.mode(explicitColor, BlendMode.srcIn)
          : null,
      // currentColor para SVGs que lo utilicen.
      theme: SvgTheme(
        currentColor: explicitColor ?? resolvedCurrentColor,
      ),
    );
  }
}
