import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/evento_cultural.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class EventoSquareCard extends StatelessWidget {
  final EventoCultural evento;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const EventoSquareCard({
    super.key, 
    required this.evento, 
    this.size = 140, 
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? image = evento.imagenes.isNotEmpty ? evento.imagenes.first.url : null;
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
            BoxShadow(color: AppColors.primary.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Hero(
                  tag: 'evento_media_square_${evento.id}_0',
                  child: CachedNetworkImage(imageUrl: image, fit: BoxFit.contain),
                )
              else
                Container(color: AppColors.background),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.primaryDark.withOpacity(0.55),
                      AppColors.primaryDark.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.textLight, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${evento.ubicacion.municipio ?? ''}${evento.ubicacion.municipio != null && evento.ubicacion.departamento != null ? ', ' : ''}${evento.ubicacion.departamento ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.labelSmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            evento.organizador,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.labelSmall?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Menú de administrador en la esquina superior derecha
              if (isAdmin)
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


