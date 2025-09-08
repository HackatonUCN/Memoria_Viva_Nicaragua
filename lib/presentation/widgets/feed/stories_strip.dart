import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/evento_cultural.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StoriesStrip extends StatelessWidget {
  final List<EventoCultural> eventos;
  final bool loading;
  final String? error;
  final VoidCallback onSeeAll;
  final void Function(EventoCultural) onTap;

  const StoriesStrip({
    super.key,
    required this.eventos,
    required this.loading,
    required this.error,
    required this.onSeeAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Eventos',
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: Text('Ver todos', style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.accent)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (_, __) => _shimmerCard(),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemCount: 5,
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final e = eventos[index];
                    final image = e.imagenes.isNotEmpty ? e.imagenes.first.url : null;
                    return InkWell(
                      onTap: () => onTap(e),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.surface,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (image != null)
                                CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(color: AppColors.background),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      AppColors.primaryDark.withOpacity(0.35),
                                      AppColors.primaryDark.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.titulo, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: AppTypography.textTheme.titleMedium?.copyWith(
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.bold,
                                        )),
                                    const SizedBox(height: 2),
                                    Text('${e.ubicacion.departamento ?? ''} ${e.ubicacion.municipio ?? ''}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textLight)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _shimmerCard() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}


