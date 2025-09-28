import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/saber_popular.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../common/cultural_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../utils/date_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../utils/web_downloader.dart';
import '../../../utils/cloudinary_url.dart';

// Helper function for Cloudinary image optimization
String _cloudinaryScaled(String url, {required int width}) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('res.cloudinary.com')) return url;
    final segments = List<String>.from(uri.pathSegments);
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex == -1) return url;
    // Insert transformation preserving existing ones
    final String transform = 'f_auto,q_auto,w_$width';
    if (uploadIndex + 1 < segments.length && segments[uploadIndex + 1].isNotEmpty && !segments[uploadIndex + 1].contains(',')) {
      segments.insert(uploadIndex + 1, transform);
    } else if (uploadIndex + 1 < segments.length) {
      segments[uploadIndex + 1] = '${segments[uploadIndex + 1]},$transform';
    } else {
      segments.add(transform);
    }
    final newUri = uri.replace(pathSegments: segments);
    return newUri.toString();
  } catch (_) {
    return url;
  }
}

// Helper function for formatting relative dates
String _formatRelativeDate(DateTime fecha) {
  final now = DateTime.now();
  final difference = now.difference(fecha);
  
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return difference.inMinutes <= 1 ? 'Ahora' : '${difference.inMinutes}m';
    }
    return '${difference.inHours}h';
  } else if (difference.inDays == 1) {
    return 'Ayer';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '${weeks}sem';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return '${months}mes';
  } else {
    final years = (difference.inDays / 365).floor();
    return '${years}año${years > 1 ? 's' : ''}';
  }
}

class SaberCard extends StatelessWidget {
  final SaberPopular saber;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onMore;
  final bool showMore;
  final bool isLiked;

  const SaberCard({
    super.key,
    required this.saber,
    this.onTap,
    this.onLike,
    this.onShare,
    this.onReport,
    this.onMore,
    this.showMore = false,
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 900;
    const double maxCardWidth = 840;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxCardWidth),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kIsWeb
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
               border: Border.all(
                 color: AppColors.primary.withOpacity(0.12),
                 width: 1,
               ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // Multimedia si existe
                 if (saber.multimedia.isNotEmpty)
                   _SaberMediaCarousel(multimedia: saber.multimedia),
                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y menú
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              saber.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.titleLarge?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
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
                      
                      const SizedBox(height: 8),
                      
                      // Chip de categoría
                      _SaberCategoryChip(
                        categoriaId: saber.categoriaId,
                        categoriaNombre: saber.categoriaNombre,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Autor y fecha
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            saber.autorNombre,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                           Text(
                             _formatRelativeDate(saber.fechaCreacion),
                             style: AppTypography.textTheme.bodySmall?.copyWith(
                               color: AppColors.textSecondary,
                             ),
                           ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Contenido preview
                      Text(
                        saber.contenido,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Etiquetas
                      if (saber.etiquetas.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: saber.etiquetas.take(3).map((etiqueta) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                 decoration: BoxDecoration(
                                   color: AppColors.primary.withOpacity(0.15),
                                   borderRadius: BorderRadius.circular(12),
                                   border: Border.all(
                                     color: AppColors.primary.withOpacity(0.3),
                                     width: 0.5,
                                   ),
                                 ),
                                child: Text(
                                  etiqueta,
                                  style: AppTypography.textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      // Acciones
                      Row(
                        children: [
                          // Like
                          InkWell(
                            onTap: onLike,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 18,
                                    color: isLiked ? AppColors.accent : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${saber.likes}',
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Compartir
                          InkWell(
                            onTap: onShare,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${saber.compartidos}',
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Reportar (visible para todos)
                          InkWell(
                            onTap: onReport,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Reportar',
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Ubicación si existe y no es la ubicación predeterminada
                          if (saber.ubicacion != null && 
                              !(saber.ubicacion!.departamento == 'Nacional' && 
                                saber.ubicacion!.municipio == 'Nicaragua'))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                   Text(
                                     saber.ubicacion!.obtenerDireccionFormateada(),
                                     style: AppTypography.textTheme.bodySmall?.copyWith(
                                       color: AppColors.accent,
                                       fontSize: 11,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
}

// Widget para el chip de categoría
class _SaberCategoryChip extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;

  const _SaberCategoryChip({
    required this.categoriaId,
    required this.categoriaNombre,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor(categoriaId).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor(categoriaId).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getCategoryIcon(categoriaId),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            categoriaNombre,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: _getCategoryColor(categoriaId),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
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

  Color _getCategoryColor(String categoriaId) {
    switch (categoriaId) {
      case 'saber_recetas':
        return const Color(0xFFFF7043);
      case 'saber_artesanias':
        return const Color(0xFFC97C5D);
      case 'saber_medicina_tradicional':
        return const Color(0xFF2E7D32);
      case 'saber_musica_danza':
        return const Color(0xFF1E88E5);
      case 'saber_dichos_refranes':
        return const Color(0xFFFFB300);
      case 'saber_gastronomia':
        return const Color(0xFFE76F51);
      case 'saber_agricultura':
        return const Color(0xFF7CB342);
      case 'saber_juegos_tradicionales':
        return const Color(0xFF26C6DA);
      default:
        return AppColors.primary;
    }
  }
}

// Widget para carrusel de multimedia (imágenes, audio, video)
class _SaberMediaCarousel extends StatefulWidget {
  final List<Multimedia> multimedia;

  const _SaberMediaCarousel({required this.multimedia});

  @override
  State<_SaberMediaCarousel> createState() => _SaberMediaCarouselState();
}

class _SaberMediaCarouselState extends State<_SaberMediaCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _autoplayTried = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.multimedia.isEmpty) return const SizedBox.shrink();
    final bool showArrows = widget.multimedia.length > 1;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.multimedia.length,
            itemBuilder: (context, index) {
              final media = widget.multimedia[index];
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: _buildMediaPreview(media),
              );
            },
          ),
          
          // Deshabilitar autoplay en carrusel para evitar decodificación simultánea
          if (!_autoplayTried) const SizedBox.shrink(),
          
          // Flechas de navegación
          if (showArrows)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final prev = (_currentIndex - 1).clamp(0, widget.multimedia.length - 1);
                      _pageController.animateToPage(prev, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.chevron_left, size: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            
          if (showArrows)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final next = (_currentIndex + 1).clamp(0, widget.multimedia.length - 1);
                      _pageController.animateToPage(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.chevron_right, size: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          
          // Indicadores de página
          if (showArrows)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.multimedia.length,
                  (index) => _dot(index == _currentIndex),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _dot(bool active) => Container(
    width: active ? 10 : 6,
    height: active ? 10 : 6,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      color: active ? AppColors.accent : AppColors.withOpacity(AppColors.accent, 0.4),
      shape: BoxShape.circle,
    ),
  );

  Widget _buildMediaPreview(Multimedia media) {
    switch (media.tipo) {
      case TipoMultimedia.imagen:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: AppColors.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Hero(
                  tag: 'saber_media_${media.url}',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                      final int targetW = (constraints.maxWidth * devicePixelRatio).clamp(360.0, 1600.0).round();
                      final String url = _cloudinaryScaled(media.url, width: targetW);
                      return CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        fadeInDuration: const Duration(milliseconds: 160),
                        fadeOutDuration: const Duration(milliseconds: 120),
                        placeholder: (c, _) => Container(color: AppColors.background),
                        errorWidget: (c, _, __) => Container(
                          color: AppColors.background, 
                          child: const Icon(Icons.broken_image_outlined)
                        ),
                        memCacheWidth: targetW,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      
      case TipoMultimedia.video:
        return Container(
          color: AppColors.primaryDark,
          child: Stack(
            children: [
              // Placeholder para video con mejor presentación
              Container(
                color: AppColors.background,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Overlay con icono de play
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primaryDark.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
              // Badge de tipo de contenido
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      
      case TipoMultimedia.audio:
        return Container(
          color: AppColors.accent.withOpacity(0.1),
          child: Stack(
            children: [
              // Fondo con patrón para audio
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.audiotrack,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
              ),
              // Badge de tipo de contenido
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Audio',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Información del audio
              if (media.descripcion != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      media.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      
      case TipoMultimedia.documento:
        return Container(
          color: AppColors.primaryDark.withOpacity(0.05),
          child: Stack(
            children: [
              // Fondo con patrón para documentos
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark.withOpacity(0.1),
                      AppColors.accent.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getDocumentIcon(media.url),
                        size: 48,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDocumentType(media.url).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge de tipo de contenido
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Documento',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Información del documento
              if (media.descripcion != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          media.descripcion!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (media.tamanoBytes != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(media.tamanoBytes!),
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Icono de descarga
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: () async {
                    final sanitized = sanitizeCloudinaryRawPdfUrl(media.url);
                    final url = ensureAttachment(sanitized);
                    if (kIsWeb) {
                      // Log for diagnostics
                      // ignore: avoid_print
                      print('[PDF] Card download web sanitized=$sanitized url=$url');
                      await triggerWebDownload(url);
                    } else {
                      // ignore: avoid_print
                      print('[PDF] Card download mobile sanitized=$sanitized url=$url');
                      await _launchExternal(url);
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download,
                      size: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  IconData _getDocumentIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'epub':
        return Icons.menu_book;
      case 'txt':
        return Icons.text_snippet;
      case 'rtf':
        return Icons.article;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getDocumentType(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'PDF';
      case 'doc':
        return 'DOC';
      case 'docx':
        return 'DOCX';
      case 'epub':
        return 'EPUB';
      case 'txt':
        return 'TXT';
      case 'rtf':
        return 'RTF';
      default:
        return 'DOC';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

Future<void> _launchExternal(String url) async {
  try {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (_) {}
}

