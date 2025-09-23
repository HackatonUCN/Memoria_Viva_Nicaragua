import 'package:flutter/material.dart';

import '../../../domain/entities/saber_popular.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../common/cultural_icon.dart';
import '../../../core/constants/app_icons.dart';

class SaberSquareCard extends StatelessWidget {
  final SaberPopular saber;
  final double size;
  final VoidCallback? onTap;

  const SaberSquareCard({
    super.key, 
    required this.saber, 
    this.size = 140, 
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.10), 
              blurRadius: 14, 
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fondo con gradiente sutil
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.accent.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
              
              // Icono de libro centrado
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              
              // Gradiente inferior para el texto
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primaryDark.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Título en la parte inferior
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  saber.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
              
              // (oculto) Badge de categoría: solo icono y título según requerimiento
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String categoriaId) {
    switch (categoriaId) {
      case 'saber_recetas':
        return '🍲';
      case 'saber_artesanias':
        return '🎨';
      case 'saber_medicina_tradicional':
        return '🌿';
      case 'saber_musica_danza':
        return '🎵';
      case 'saber_dichos_refranes':
        return '💭';
      case 'saber_gastronomia':
        return '🍽️';
      case 'saber_agricultura':
        return '🌱';
      case 'saber_juegos_tradicionales':
        return '🎯';
      default:
        return '📚';
    }
  }
}
