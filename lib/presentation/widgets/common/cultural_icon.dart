import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CulturalIcon extends StatelessWidget {
  final String svgPath;
  final double size;
  final Color? color;

  const CulturalIcon({
    Key? key,
    required this.svgPath,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      svgPath,
      width: size,
      height: size,
      colorFilter: color != null 
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
