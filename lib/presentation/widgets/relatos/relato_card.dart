import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart';

import '../../../domain/entities/relato.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../common/cultural_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/repositories/categoria_repository.dart';

class RelatoCard extends StatelessWidget {
  final Relato relato;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onMore;
  final bool showMore;

  const RelatoCard({
    super.key,
    required this.relato,
    this.onTap,
    this.onLike,
    this.onShare,
    this.onReport,
    this.onMore,
    this.showMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final Multimedia? firstMedia = relato.multimedia.isNotEmpty ? relato.multimedia.first : null;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 900;
    const double maxCardWidth = 760;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? maxCardWidth : double.infinity),
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (firstMedia != null)
                  _MediaPreview(media: firstMedia),
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
                              relato.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (showMore)
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              color: AppColors.textSecondary,
                              tooltip: 'Opciones',
                              onPressed: onMore,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _CategoriaChip(categoriaId: relato.categoriaId, categoriaNombre: relato.categoriaNombre),
                      const SizedBox(height: 6),
                      Text(
                        '${relato.autorNombre}${relato.ubicacion != null ? ' • ' + relato.ubicacion!.obtenerDireccionFormateada() : ''}',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        relato.contenido,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ver más…',
                        style: AppTypography.textTheme.labelLarge?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _actionIcon(Icons.favorite_border, onLike),
                          Text('${relato.likes}', style: AppTypography.textTheme.bodyMedium),
                          const SizedBox(width: 12),
                          _actionIcon(Icons.ios_share_outlined, onShare),
                          Text('${relato.compartidos}', style: AppTypography.textTheme.bodyMedium),
                          const Spacer(),
                          _actionIcon(Icons.flag_outlined, onReport),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback? onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final Multimedia media;
  const _MediaPreview({required this.media});

  @override
  Widget build(BuildContext context) {
    switch (media.tipo) {
      case TipoMultimedia.imagen:
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Hero(
                    tag: 'relato_media_${media.url}',
                    child: CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (c, _) => Container(color: AppColors.background),
                      errorWidget: (c, _, __) => Container(color: AppColors.background, child: const Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case TipoMultimedia.video:
        // Placeholder visual para video (inline). El reproductor real se mostrará en el overlay.
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: media.obtenerThumbnailUrl(),
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Container(color: AppColors.imageOverlay),
                      ),
                      const Positioned.fill(
                        child: Center(
                          child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case TipoMultimedia.audio:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: AppColors.surfaceVariant,
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.play_arrow, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('0:30', style: AppTypography.metadata.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        );
    }
  }
}



class _CategoriaChip extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;

  const _CategoriaChip({
    required this.categoriaId,
    required this.categoriaNombre,
  });

  @override
  Widget build(BuildContext context) {
    final ICategoriaRepository repo = ServiceLocator.get<ICategoriaRepository>();

    return FutureBuilder<Categoria?> (
      future: repo.obtenerCategoriaPorId(categoriaId),
      builder: (context, snapshot) {
        final Categoria? categoria = snapshot.data;
        final Color chipColor = _hexToColorOrFallback(categoria?.color);
        final String iconPath = _resolveIconPath(categoria?.icono);

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
              CulturalIcon(svgPath: iconPath, size: 16, color: chipColor),
              const SizedBox(width: 6),
              Text(
                categoriaNombre,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.primaryDark,
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

Color _hexToColorOrFallback(String? hex) {
  if (hex == null || hex.isEmpty) return AppColors.accent;
  String value = hex;
  if (value.startsWith('#')) value = value.substring(1);
  if (value.length == 6) value = 'FF$value';
  try {
    return Color(int.parse(value, radix: 16));
  } catch (_) {
    return AppColors.accent;
  }
}

String _resolveIconPath(String? iconoNombre) {
  switch ((iconoNombre ?? 'relato').toLowerCase()) {
    case 'marimba':
      return AppIcons.marimba;
    case 'guitarra':
      return AppIcons.guitarra;
    case 'cacao':
      return AppIcons.cacao;
    case 'artesania':
      return AppIcons.artesania;
    case 'iglesia':
      return AppIcons.iglesia;
    case 'volcan':
      return AppIcons.volcan;
    case 'camara':
      return AppIcons.camara;
    case 'gueguense':
      return AppIcons.gueguense;
    case 'guardabarranco':
      return AppIcons.guardabarranco;
    case 'nicaragua':
      return AppIcons.nicaragua;
    case 'apple':
      return AppIcons.apple;
    case 'relato':
    default:
      return AppIcons.relato;
  }
}

