import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../../utils/web_downloader.dart';
import '../../../utils/cloudinary_url.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../../domain/repositories/saber_popular_repository.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../providers/saberes/saberes_feed_provider.dart';
import '../../providers/media_playback_provider.dart';
import '../../providers/navigation_provider.dart';

class SaberDetailOverlay extends StatelessWidget {
  final SaberPopular saber;
  const SaberDetailOverlay({super.key, required this.saber});

  static Future<void> open(BuildContext context, SaberPopular? saber, {String? saberId}) async {
    try {
      final media = context.read<MediaPlaybackProvider>();
      await media.pauseScope('card', relatoId: saber?.id ?? saberId);
    } catch (_) {}

    final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
    final BuildContext rootContext = rootNav.context;
    rootNav.popUntil((route) {
      return route.isFirst || (!route.willHandlePopInternally && !route.hasActiveRouteBelow);
    });
    await Future.delayed(const Duration(milliseconds: 50));

    SaberesFeedProvider? feedProvider;
    try {
      feedProvider = rootContext.read<SaberesFeedProvider>();
    } catch (_) {
      feedProvider = null;
    }

    await showModalBottomSheet(
      context: rootContext,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      barrierColor: AppColors.withOpacity(AppColors.primaryDark, 0.6),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final content = _OverlayScaffold(saber: saber, saberId: saberId);
        if (feedProvider != null) {
          return ChangeNotifierProvider<SaberesFeedProvider>.value(
            value: feedProvider!,
            child: content,
          );
        }
        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _OverlayScaffold extends StatelessWidget {
  final SaberPopular? saber;
  final String? saberId;
  const _OverlayScaffold({required this.saber, this.saberId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (ctx, controller) => Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: _DetailContent(saber: saber, saberId: saberId, controller: controller),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 12,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final SaberPopular? saber;
  final String? saberId;
  final ScrollController controller;
  const _DetailContent({required this.saber, this.saberId, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (saber == null) {
      if (saberId == null || saberId!.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final repo = GetIt.I<ISaberPopularRepository>();
      return StreamBuilder<SaberPopular?>(
        stream: repo.observarSaberPorId(saberId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          return _buildContent(context, s);
        },
      );
    }
    return _buildContent(context, saber!);
  }

  Widget _buildContent(BuildContext context, SaberPopular s) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _MediaCarousel(multimedia: s.multimedia),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.titulo, style: AppTypography.storyTitle),
                const SizedBox(height: 8),
                Text(
                  '${s.autorNombre} • ${_formatFecha(s.fechaCreacion)}'
                  '${s.ubicacion != null ? ' • ' + s.ubicacion!.obtenerDireccionFormateada() : ''}',
                  style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(s.contenido, style: AppTypography.storyContent),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _categoriaChip(context, s.categoriaId, s.categoriaNombre)
                  ]..addAll(s.etiquetas.map((e) => _chip('#$e'))),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Builder(
                      builder: (context) {
                        bool liked = false;
                        SaberesFeedProvider? feed;
                        try {
                          liked = context.select<SaberesFeedProvider, bool>((p) => p.isLiked(s.id));
                          feed = context.read<SaberesFeedProvider>();
                        } catch (_) {
                          feed = null;
                          liked = false;
                        }
                        final bool isOwner = feed?.currentUserId != null && s.autorId == feed!.currentUserId;
                        return IconButton(
                          tooltip: 'Me gusta',
                          icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? AppColors.accent : null),
                          onPressed: feed == null || isOwner
                              ? null
                              : () async {
                                  final f = feed!;
                                  await f.toggleLike(s.id);
                                },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Compartir',
                      icon: const Icon(Icons.ios_share_outlined),
                      onPressed: () async {
                        SaberesFeedProvider? provider;
                        try { provider = context.read<SaberesFeedProvider>(); } catch (_) { provider = null; }
                        final webUrl = Uri.parse('https://memoriaviva.app/saberes/${s.id}');
                        final resumen = s.contenido.length > 120 ? s.contenido.substring(0, 120) + '…' : s.contenido;
                        final message = '${s.titulo}\n\n$resumen\n\nEnlace: $webUrl';
                        await Share.share(message, subject: 'Saber – ${s.titulo}');
                        if (provider != null) { await provider.compartir(s.id); }
                      },
                    ),
                    IconButton(
                      tooltip: 'Reportar',
                      icon: const Icon(Icons.flag_outlined),
                      onPressed: () {
                        SaberesFeedProvider? feed;
                        try { feed = context.read<SaberesFeedProvider>(); } catch (_) { feed = null; }
                        if (feed == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Acción no disponible en esta vista')),
                          );
                          return;
                        }
                        final controller = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reportar saber'),
                            content: TextField(
                              controller: controller,
                              maxLines: 3,
                              decoration: const InputDecoration(hintText: 'Describe el motivo (mín. 10 caracteres)'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                              ElevatedButton(
                                onPressed: () async {
                                  final reason = controller.text.trim();
                                  if (reason.length < 10) return;
                                  final f = feed!;
                                  await f.reportar(s.id, reason);
                                  if (context.mounted) Navigator.pop(ctx);
                                },
                                child: const Text('Reportar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Builder(
                      builder: (_) {
                        final canViewOnMap = s.ubicacion != null;
                        return Tooltip(
                          message: canViewOnMap ? 'Ver en el mapa' : 'Sin ubicación',
                          child: Opacity(
                            opacity: canViewOnMap ? 1.0 : 0.55,
                            child: IconButton(
                              icon: const Icon(Icons.map_outlined),
                              onPressed: canViewOnMap ? () {
                                try {
                                  final nav = context.read<NavigationProvider>();
                                  if (s.ubicacion != null) {
                                    nav.setMapFocusLocation(
                                      lat: s.ubicacion!.latitud,
                                      lng: s.ubicacion!.longitud,
                                      radiusKm: 3,
                                    );
                                  }
                                  final rootNav = Navigator.of(context, rootNavigator: true);
                                  final rootCtx = rootNav.context;
                                  Navigator.of(context).pop();
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    try { nav.setIndex(1); } catch (_) {}
                                    try {
                                      ScaffoldMessenger.of(rootCtx).showSnackBar(
                                        SnackBar(
                                          content: Text('Mostrando "${s.titulo}" en el mapa'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    } catch (_) {}
                                  });
                                } catch (_) {}
                              } : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _chip(String text) => Chip(
        label: Text(text),
        backgroundColor: AppColors.withOpacity(AppColors.accent, 0.2),
      );

  Widget _categoriaChip(BuildContext context, String categoriaId, String categoriaNombre) {
    final Color chipColor = AppColors.categoryColor(categoryId: categoriaId);
    final bool isDark = (Theme.of(context).brightness == Brightness.dark);
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.primaryDark;
    return Chip(
      label: Text('Categoría: $categoriaNombre', style: AppTypography.textTheme.labelMedium?.copyWith(color: textColor)),
      backgroundColor: AppColors.withOpacity(chipColor, 0.15),
      shape: StadiumBorder(side: BorderSide(color: AppColors.withOpacity(chipColor, 0.5))),
    );
  }
}

class _MediaCarousel extends StatefulWidget {
  final List<Multimedia> multimedia;
  const _MediaCarousel({super.key, required this.multimedia});

  @override
  State<_MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<_MediaCarousel> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.multimedia.isEmpty) return const SizedBox.shrink();
    
    final double screenHeight = MediaQuery.of(context).size.height;
    final double mediaHeight = (screenHeight * 0.6).clamp(360.0, 720.0);
    final bool showArrows = widget.multimedia.length > 1;
    
    return SizedBox(
      height: mediaHeight,
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
            itemBuilder: (ctx, i) {
              final m = widget.multimedia[i];
              switch (m.tipo) {
                case TipoMultimedia.imagen:
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Hero(
                        tag: 'saber_media_${m.url}',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                            final int targetW = (constraints.maxWidth * devicePixelRatio).clamp(360.0, 2000.0).round();
                            final String url = _cloudinaryScaled(m.url, width: targetW);
                            return CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              fadeInDuration: const Duration(milliseconds: 160),
                              fadeOutDuration: const Duration(milliseconds: 120),
                              placeholder: (c, _) => Container(color: AppColors.surfaceVariant),
                              errorWidget: (c, _, __) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(child: Icon(Icons.broken_image_outlined)),
                              ),
                              memCacheWidth: targetW,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                case TipoMultimedia.video:
                  return _VideoPlayerCard(url: m.url);
                case TipoMultimedia.audio:
                  return _AudioPlayerCard(url: m.url);
                case TipoMultimedia.documento:
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_getDocumentIcon(m.url), size: 64, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            _getDocumentType(m.url),
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _openDocument(context, m.url),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Abrir documento'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _downloadDocument(context, m.url),
                                icon: const Icon(Icons.download),
                                label: const Text('Descargar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
          
          // Flechas de navegación
          if (showArrows)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final prev = (_currentIndex - 1).clamp(0, widget.multimedia.length - 1);
                      _pageController.animateToPage(prev, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.chevron_left, size: 32, color: Colors.white),
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
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      final next = (_currentIndex + 1).clamp(0, widget.multimedia.length - 1);
                      _pageController.animateToPage(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.chevron_right, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          
          // Indicadores de página
          if (showArrows)
            Positioned(
              bottom: 16,
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

  Future<void> _openDocument(BuildContext context, String url) async {
    final String lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) {
      if (kIsWeb) {
        // En Web: si el content-type es PDF abrimos en navegador, si no, descargamos
        debugPrint('[PDF] Web pre-check url=$url');
        try {
          final head = await http.head(Uri.parse(url)).timeout(const Duration(seconds: 6));
          final ct = head.headers['content-type'] ?? '';
          debugPrint('[Probe] HEAD status=${head.statusCode} ct=$ct');
          if (head.statusCode >= 200 && head.statusCode < 400 && ct.contains('application/pdf')) {
            debugPrint('[PDF] Web open in browser url=$url');
            await _launchExternal(url, context);
          } else {
            debugPrint('[PDF] Web fallback to download url=$url');
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se puede previsualizar (HTTP ${head.statusCode}). Descargando…')),
              );
            } catch (_) {}
            await triggerWebDownload(ensureAttachment(url));
          }
        } catch (e) {
          debugPrint('[Probe] HEAD failed: $e; fallback to download');
          await triggerWebDownload(ensureAttachment(url));
        }
        return;
      }
      debugPrint('[PDF] Mobile open in dialog url=$url');
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) {
          final Size size = MediaQuery.of(ctx).size;
          final double w = (size.width * 0.92).clamp(280.0, 820.0);
          final double h = (size.height * 0.78).clamp(280.0, 820.0);
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: w,
              height: h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Vista previa del PDF', style: AppTypography.textTheme.titleMedium),
                        ),
                        IconButton(
                          tooltip: 'Abrir en navegador',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _launchExternal(url, ctx),
                        ),
                        IconButton(
                          tooltip: 'Descargar',
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            if (kIsWeb) {
                              // NO usar ensureAttachment aquí, enviar la URL original
                              // El proxy se encargará de la descarga
                              final sanitizedUrl = sanitizeCloudinaryRawPdfUrl(url);
                              await triggerWebDownload(sanitizedUrl);
                            } else {
                              await _downloadDocument(ctx, url);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: SfPdfViewer.network(
                        url,
                        canShowScrollHead: true,
                        canShowScrollStatus: false,
                        pageLayoutMode: PdfPageLayoutMode.single,
                        onDocumentLoaded: (details) {
                          debugPrint('[PDF] Loaded ok: pages=${details.document.pages.count} url=$url');
                        },
                        onDocumentLoadFailed: (details) {
                          try {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('No se pudo cargar el PDF: '+details.error), duration: const Duration(seconds: 3)),
                            );
                          } catch (_) {}
                          debugPrint('[PDF] Load failed url=$url error=${details.error} desc=${details.description}');
                          _probeUrl(url);
                          _launchExternal(url, ctx);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      await _launchExternal(url, context);
    }
  }

  Future<void> _launchExternal(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      final can = await canLaunchUrl(uri);
      if (!can) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento')));
        }
        return;
      }
      // En dispositivos móviles, abre en el lector PDF nativo
      // En web, abre en una nueva pestaña
      final LaunchMode mode = kIsWeb ? LaunchMode.externalApplication : LaunchMode.platformDefault;
      await launchUrl(uri, mode: mode);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el documento')));
      }
    }
  }

  Future<void> _downloadDocument(BuildContext context, String url) async {
    try {
      // Sanitize malformed RAW URLs that have duplicated .pdf segments
      final sanitized = sanitizeCloudinaryRawPdfUrl(url);
      final Uri uri = Uri.parse(sanitized);
      
      // IMPORTANTE: NO añadir fl_attachment aquí, lo añadiremos en el proxy
      // Esto evita el error 404 en Cloudinary
      debugPrint('[PDF] Download request original=$url sanitized=$sanitized web=$kIsWeb');
      
      if (kIsWeb) {
        // Mostrar mensaje de descarga iniciada
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Descargando documento...'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (_) {}
        
        // Enviar la URL sanitizada directamente al proxy
        // El proxy se encargará de añadir Content-Disposition: attachment
        await triggerWebDownload(sanitized);
      } else {
        // En móvil, abrir con el visor nativo
        await _launchExternal(sanitized, context);
      }
    } catch (e) {
      debugPrint('[PDF] Download exception for url=$url error=$e');
      if (kIsWeb) {
        // Si falla, intentar con la URL original sin sanitizar
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intentando descarga directa...'),
              duration: Duration(seconds: 2),
            ),
          );
        } catch (_) {}
        await triggerWebDownload(url);
      } else {
        await _launchExternal(url, context);
      }
    }
  }

  // Simple diagnostic probe to inspect reachability and headers
  Future<void> _probeUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      debugPrint('[Probe] HEAD $url');
      final head = await http.head(uri).timeout(const Duration(seconds: 8));
      debugPrint('[Probe] HEAD status=${head.statusCode} ct=${head.headers['content-type']} cl=${head.headers['content-length']}');
    } catch (e) {
      debugPrint('[Probe] HEAD failed: $e');
      try {
        debugPrint('[Probe] GET range 0-0 $url');
        final get = await http.get(Uri.parse(url), headers: {'Range': 'bytes=0-0'}).timeout(const Duration(seconds: 8));
        debugPrint('[Probe] GET status=${get.statusCode} ct=${get.headers['content-type']} cors=${get.headers['access-control-allow-origin']}');
      } catch (e2) {
        debugPrint('[Probe] GET failed: $e2');
      }
    }
  }
  
  Widget _dot(bool active) => Container(
    width: active ? 12 : 8,
    height: active ? 12 : 8,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      color: active ? AppColors.accent : AppColors.withOpacity(AppColors.accent, 0.4),
      shape: BoxShape.circle,
      boxShadow: active ? [BoxShadow(color: AppColors.accent.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : null,
    ),
  );
  
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
        return 'Documento PDF';
      case 'doc':
      case 'docx':
        return 'Documento Word';
      case 'epub':
        return 'Libro Digital';
      case 'txt':
        return 'Documento de Texto';
      case 'rtf':
        return 'Documento RTF';
      default:
        return 'Documento';
    }
  }
}

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

class _AudioPlayerCard extends StatefulWidget {
  final String url;
  const _AudioPlayerCard({super.key, required this.url});

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _VideoPlayerCard extends StatefulWidget {
  final String url;
  const _VideoPlayerCard({super.key, required this.url});

  @override
  State<_VideoPlayerCard> createState() => _VideoPlayerCardState();
}

class _VideoPlayerCardState extends State<_VideoPlayerCard> with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true;
  String? _handlerKey;
  MediaPlaybackProvider? _media;
  bool _isSeeking = false;
  Timer? _resumeDebounce;
  bool _wasPlayingBeforeSeek = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late final String _srcUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _srcUrl = kIsWeb ? widget.url : _maybeToCloudinaryHls(widget.url);
    _controller = kIsWeb
        ? VideoPlayerController.network(_srcUrl)
        : VideoPlayerController.networkUrl(
            Uri.parse(_srcUrl),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            formatHint: _inferFormatFromUrl(_srcUrl),
          )
      ..setLooping(false)
      ..initialize().then((_) async {
        _duration = _controller.value.duration;
        if (!kIsWeb && _duration == Duration.zero) {
          await _warmUpAndPollDuration();
        }
        if (mounted) setState(() => _initialized = true);
      });
    
    // Listener para actualizar posición
    _controller.addListener(() {
      final value = _controller.value;
      if (!mounted || !value.isInitialized) return;
      if (_isSeeking) return;
      setState(() {
        _position = value.position;
        if (value.duration > Duration.zero && value.duration >= _duration) {
          _duration = value.duration;
        }
      });
    });
    
    // Registrar pausa global con ámbito 'overlay'
    try {
      _media = context.read<MediaPlaybackProvider>();
      _handlerKey = _media!.registerHandler(
        scope: 'overlay',
        sourceId: widget.url,
        onPause: () async { await _controller.pause(); },
        tipo: 'video',
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    if (_handlerKey != null) {
      _media?.unregisterHandlerByKey(_handlerKey!);
    }
    _controller.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  VideoFormat? _inferFormatFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8')) return VideoFormat.hls;
    if (lower.contains('.mp4')) return VideoFormat.other;
    if (lower.contains('.webm')) return VideoFormat.other;
    if (lower.contains('.mov')) return VideoFormat.other;
    return null;
  }

  String _maybeToCloudinaryHls(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.host.contains('res.cloudinary.com')) return url;
      final segments = List<String>.from(uri.pathSegments);
      // Expect something like /video/upload/v123/.../<public_id>.mp4
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1) return url;
      // Insert streaming profile after 'upload'
      if (uploadIndex + 1 < segments.length && !segments[uploadIndex + 1].startsWith('sp_')) {
        segments.insert(uploadIndex + 1, 'sp_auto');
      }
      // Replace last extension with .m3u8
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (last.contains('.')) {
          final base = last.substring(0, last.lastIndexOf('.'));
          segments[segments.length - 1] = '$base.m3u8';
        } else {
          segments[segments.length - 1] = '${segments.last}.m3u8';
        }
      }
      final newUri = uri.replace(pathSegments: segments);
      return newUri.toString();
    } catch (_) {
      return url;
    }
  }

  Future<void> _warmUpAndPollDuration() async {
    final bool wasMuted = _muted;
    try {
      await _controller.setVolume(0.0);
      await _controller.play();
    } catch (_) {}
    final sw = Stopwatch()..start();
    while (mounted && sw.elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(milliseconds: 120));
      final d = _controller.value.duration;
      if (d > Duration.zero) {
        _duration = d;
        break;
      }
    }
    try {
      await _controller.pause();
      await _controller.setVolume(wasMuted ? 0.0 : 1.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.black,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video centrado con contain para que se vea completo
                Positioned.fill(
                  child: _initialized
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        )
                      : Container(color: Colors.black),
                ),
                
                // Overlay oscuro para los controles
                Positioned.fill(child: Container(color: _controller.value.isPlaying ? Colors.transparent : AppColors.withOpacity(Colors.black, 0.4))),
                
                // Botón central play/pause
                if (_initialized)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          color: Colors.white,
                        ),
                        onPressed: () async {
                          final media = context.read<MediaPlaybackProvider>();
                          if (_controller.value.isPlaying) {
                            await _controller.pause();
                          } else {
                            // Garantizar exclusividad antes de reproducir
                            final excludeKey = media.keyFor(scope: 'overlay', sourceId: widget.url);
                            await media.willStartPlayback(scope: 'overlay', sourceId: widget.url, tipo: 'video', excludeKey: excludeKey);
                            if (_muted) {
                              await _controller.setVolume(1.0);
                              _muted = false;
                            }
                            await _controller.play();
                          }
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ),
                
                // Controles inferiores
                if (_initialized)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Slider para posición (seek en cambio final para móviles)
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              min: 0,
                              max: (() {
                                final d = _duration.inMilliseconds;
                                final p = _position.inMilliseconds;
                                final ms = d > 0 ? d : (p + 1000);
                                final m = ms.toDouble();
                                return m < 1.0 ? 1.0 : m;
                              })(),
                              value: (() {
                                final d = _duration.inMilliseconds;
                                final p = _position.inMilliseconds;
                                final maxMs = d > 0 ? d : (p + 1000);
                                final v = p.clamp(0, maxMs).toDouble();
                                return v;
                              })(),
                              onChangeStart: (value) async {
                                _isSeeking = true;
                                _wasPlayingBeforeSeek = _controller.value.isPlaying;
                                await _controller.pause();
                              },
                              onChanged: (value) {
                                setState(() {
                                  _position = Duration(milliseconds: value.toInt());
                                });
                              },
                              onChangeEnd: (value) async {
                                final newPosition = Duration(milliseconds: value.toInt());
                                await _controller.seekTo(newPosition);
                                _resumeDebounce?.cancel();
                                if (_wasPlayingBeforeSeek) {
                                  _resumeDebounce = Timer(const Duration(milliseconds: 150), () async {
                                    if (!mounted) return;
                                    await _controller.play();
                                  });
                                }
                                _isSeeking = false;
                              },
                            ),
                          ),
                          
                          // Controles y tiempo
                          Row(
                            children: [
                              // Botones de control
                              IconButton(
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 20),
                                onPressed: () async {
                                  final pos = _position;
                                  final target = pos - const Duration(seconds: 10);
                                  await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 20),
                                onPressed: () async {
                                  final pos = _position;
                                  final dur = _duration;
                                  final target = pos + const Duration(seconds: 10);
                                  await _controller.seekTo(target > dur ? dur : target);
                                },
                              ),
                              
                              // Tiempo actual / duración
                              Expanded(
                                child: Text(
                                  '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              
                              // Botón de mute
                              IconButton(
                                icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
                                onPressed: () async {
                                  _muted = !_muted;
                                  await _controller.setVolume(_muted ? 0.0 : 1.0);
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Logo de memoria viva
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Memoria Viva",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                
                // Indicador de carga
                if (!_initialized)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = true;
  String? _handlerKey;
  bool _isSeeking = false;
  Timer? _resumeDebounce;
  bool _wasPlayingBeforeSeek = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      _duration = _player.duration ?? Duration.zero;
      _player.positionStream.listen((pos) { if (mounted) setState(() => _position = pos); });
      _player.durationStream.listen((d) { if (d != null && mounted) setState(() => _duration = d); });
      try {
        final media = context.read<MediaPlaybackProvider>();
        _handlerKey = media.registerHandler(
          scope: 'overlay',
          sourceId: widget.url,
          onPause: () async { await _player.pause(); },
          tipo: 'audio',
        );
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    if (_handlerKey != null) {
      try { context.read<MediaPlaybackProvider>().unregisterHandlerByKey(_handlerKey!); } catch (_) {}
    }
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            IconButton(
              icon: StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snap) {
                  final playing = _player.playing;
                  return Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 36);
                },
              ),
              onPressed: () async {
                final media = context.read<MediaPlaybackProvider>();
                if (_player.playing) {
                  await _player.pause();
                } else {
                  await media.willStartPlayback(scope: 'overlay', sourceId: widget.url, tipo: 'audio');
                  await _player.play();
                }
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Listener(
                onPointerDown: (_) async {
                  _isSeeking = true;
                  _wasPlayingBeforeSeek = _player.playing;
                  await _player.pause();
                },
                onPointerUp: (_) {
                  _resumeDebounce?.cancel();
                  if (_wasPlayingBeforeSeek) {
                    _resumeDebounce = Timer(const Duration(milliseconds: 150), () async {
                      if (!mounted) return;
                      await _player.play();
                    });
                  }
                  _isSeeking = false;
                },
                child: Slider(
                  min: 0,
                  max: () { final m = _duration.inMilliseconds.toDouble(); return m < 1.0 ? 1.0 : m; }(),
                  value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                  onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${_fmt(_position)} / ${_fmt(_duration)}', style: AppTypography.metadata.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}


