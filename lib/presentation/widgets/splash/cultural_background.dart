import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../common/cultural_icon.dart';
import 'cultural_particle.dart';

class CulturalBackground extends StatefulWidget {
  const CulturalBackground({Key? key}) : super(key: key);

  @override
  State<CulturalBackground> createState() => _CulturalBackgroundState();
}

class _CulturalBackgroundState extends State<CulturalBackground> {
  final List<String> _culturalIcons = [
    AppIcons.marimba,
    AppIcons.guitarra,
    AppIcons.artesania,
    AppIcons.cacao,
    AppIcons.iglesia,
    AppIcons.volcan,
    AppIcons.guardabarranco,
    AppIcons.gueguense,
    AppIcons.artesania,
    AppIcons.nicaragua,
    AppIcons.relato,
    AppIcons.camara,

  ];

  List<Widget> _buildParticles() {
    final random = math.Random();
    final particles = <Widget>[];
    final colors = [
      AppColors.tierra,         // Color tierra para artesanías
      AppColors.jade,          // Color jade para naturaleza
      AppColors.cacao,         // Color cacao para gastronomía
      AppColors.maiz,          // Color maíz para agricultura
      AppColors.ceramica,      // Color cerámica para artesanías
    ];

    // Asegurar que ciertos iconos siempre estén presentes al menos una vez
    final iconsToEnsure = [
      AppIcons.artesania,
      AppIcons.guardabarranco,
    ];

    for (final ensuredIcon in iconsToEnsure) {
      final size = random.nextDouble() * 35 + 25;
      final color = colors[random.nextInt(colors.length)];
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final duration = Duration(milliseconds: random.nextInt(2000) + 3000);

      particles.add(
        Positioned(
          top: top,
          left: left,
          child: AnimatedCulturalParticle.withSvg(
            initialSize: size,
            color: color.withOpacity(0.4),
            svgPath: ensuredIcon,
            duration: duration,
            curve: Curves.easeInOut,
            startRotation: random.nextDouble() * 360,
            endRotation: random.nextDouble() * 360 + 720,
            startOpacity: 0,
            endOpacity: 0.7,
          ),
        ),
      );
    }

    for (int i = 0; i < 20; i++) {
      final size = random.nextDouble() * 35 + 25;
      final color = colors[random.nextInt(colors.length)];
      final iconPath = _culturalIcons[random.nextInt(_culturalIcons.length)];
      final top = random.nextDouble() * MediaQuery.of(context).size.height;
      final left = random.nextDouble() * MediaQuery.of(context).size.width;
      final duration = Duration(milliseconds: random.nextInt(2000) + 3000);

      particles.add(
        Positioned(
          top: top,
          left: left,
          child: AnimatedCulturalParticle.withSvg(
            initialSize: size,
            color: color.withOpacity(0.4),
            svgPath: iconPath,
            duration: duration,
            curve: Curves.easeInOut,
            startRotation: random.nextDouble() * 360,
            endRotation: random.nextDouble() * 360 + 720,
            startOpacity: 0,
            endOpacity: 0.7,
          ),
        ),
      );
    }

    return particles;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Gradiente de fondo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.background.withOpacity(0.8),
                  AppColors.surfaceVariant,
                ],
              ),
            ),
          ),
          // Partículas culturales
          ..._buildParticles(),
        ],
      ),
    );
  }
}