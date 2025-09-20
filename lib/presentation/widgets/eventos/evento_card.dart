import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/evento_cultural.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/repositories/categoria_repository.dart';
import '../../../utils/date_formatter.dart';
import '../../providers/eventos_provider.dart';
import 'package:provider/provider.dart';

class EventoCard extends StatelessWidget {
  final EventoCultural evento;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isAdmin;

  const EventoCard({
    super.key,
    required this.evento,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = evento.imagenes.isNotEmpty;
    final String? imageUrl = hasImage ? evento.imagenes.first.url : null;
    final eventosProvider = context.watch<EventosProvider>();
    final isUpdating = eventosProvider.isEventUpdating(evento.id);
    final isDeleting = eventosProvider.isEventDeleting(evento.id);
    final isLoading = isUpdating || isDeleting;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kIsWeb
                  ? const []
                  : [
                      BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      )
                    ],
              border: Border.all(color: AppColors.withOpacity(AppColors.accent, 0.04), width: 2),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double dpr = MediaQuery.of(context).devicePixelRatio;
                        final int targetW = (constraints.maxWidth * dpr).clamp(360.0, 1600.0).round();
                        return AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            color: AppColors.surfaceVariant,
                            child: Hero(
                              tag: 'evento_media_$imageUrl',
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                memCacheWidth: targetW,
                                placeholder: (c, _) => Container(color: AppColors.background),
                                errorWidget: (c, _, __) => Container(
                                  color: AppColors.background,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              evento.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            PopupMenuButton<String>(
                              tooltip: 'Acciones',
                              onSelected: (v) {
                                if (v == 'edit') onEdit?.call();
                                if (v == 'delete') onDelete?.call();
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'edit', child: Text('Editar')),
                                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _EventCategoryChip(categoriaId: evento.categoriaId, categoriaNombre: evento.categoriaNombre),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.event_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              DateFormatter.formatEventDateRange(evento.fechaInicio, evento.fechaFin),
                              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${evento.ubicacion.municipio ?? ''}${evento.ubicacion.municipio != null && evento.ubicacion.departamento != null ? ', ' : ''}${evento.ubicacion.departamento ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              evento.organizador,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                            ),
                          ),
                          if ((evento.frecuencia ?? '').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.withOpacity(AppColors.accent, 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.withOpacity(AppColors.accent, 0.3)),
                              ),
                              child: Text(
                                evento.frecuencia!,
                                style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        evento.descripcion,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ver más…',
                        style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
                // Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isUpdating ? 'Actualizando...' : 'Eliminando...',
                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _EventCategoryChip extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;
  const _EventCategoryChip({required this.categoriaId, required this.categoriaNombre});

  @override
  Widget build(BuildContext context) {
    final ICategoriaRepository repo = ServiceLocator.get<ICategoriaRepository>();
    return FutureBuilder<Categoria?>(
      future: repo.obtenerCategoriaPorId(categoriaId),
      builder: (context, snapshot) {
        final Categoria? categoria = snapshot.data;
        final Color chipColor = AppColors.categoryColor(categoryId: categoriaId, hex: categoria?.color);
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.primaryDark;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(chipColor, 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.withOpacity(chipColor, 0.50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                categoriaNombre,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




