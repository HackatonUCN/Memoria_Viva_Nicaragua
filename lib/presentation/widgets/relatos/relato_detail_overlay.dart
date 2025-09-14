import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:get_it/get_it.dart';
import 'package:memoria_viva_nicaragua/domain/repositories/relato_repository.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/media_playback_provider.dart';

class RelatoDetailOverlay extends StatelessWidget {
  final Relato relato;
  const RelatoDetailOverlay({super.key, required this.relato});

  static Future<void> open(BuildContext context, Relato? relato, {String? relatoId}) async {
    // Antes de abrir: pausar reproducción en cards
    try {
      final media = context.read<MediaPlaybackProvider>();
      await media.pauseScope('card', relatoId: relato?.id ?? relatoId);
    } catch (_) {}
    // Usar navigator raíz para evitar context desactivado
    final NavigatorState rootNav = Navigator.of(context, rootNavigator: true);
    final BuildContext rootContext = rootNav.context;
    // Primero cerrar cualquier bottom sheet existente para evitar conflictos
    rootNav.popUntil((route) {
      return route.isFirst || (!route.willHandlePopInternally && !route.hasActiveRouteBelow);
    });
    
    // Pequeño delay para asegurar que el anterior se cerró completamente
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Ahora abrir el nuevo overlay
    // Usar el contexto del root navigator; evita fallos por context desactivado
    FeedProvider? feedProvider;
    try {
      feedProvider = rootContext.read<FeedProvider>();
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
        final content = _OverlayScaffold(relato: relato, relatoId: relatoId);
        if (feedProvider != null) {
          // Inyectar el FeedProvider existente para que like/compartir/reportar funcionen y refresquen UI
          return ChangeNotifierProvider<FeedProvider>.value(
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
  final Relato? relato;
  final String? relatoId;
  const _OverlayScaffold({required this.relato, this.relatoId});

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
                child: _DetailContent(relato: relato, relatoId: relatoId, controller: controller),
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
  final Relato? relato;
  final String? relatoId;
  final ScrollController controller;
  const _DetailContent({required this.relato, this.relatoId, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (relato == null) {
      if (relatoId == null || relatoId!.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final repo = GetIt.I<IRelatoRepository>();
      return StreamBuilder<Relato?>(
        stream: repo.observarRelatoPorId(relatoId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data!;
          return _buildContent(context, r);
        },
      );
    }

    final Relato r = relato!;

    return _buildContent(context, r);
  }

  Widget _buildContent(BuildContext context, Relato r) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _MediaCarousel(multimedia: r.multimedia),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.titulo, style: AppTypography.storyTitle),
                const SizedBox(height: 8),
                Text(
                  '${r.autorNombre} • ${_formatFecha(r.fechaCreacion)}'
                  '${r.ubicacion != null ? ' • ' + r.ubicacion!.obtenerDireccionFormateada() : ''}',
                  style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(r.contenido, style: AppTypography.storyContent),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _categoriaChip(context, r.categoriaId, r.categoriaNombre)
                  ]..addAll(r.etiquetas.map((e) => _chip('#$e'))),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        final bool canViewOnMap = r.ubicacion != null;
                        return Tooltip(
                          message: canViewOnMap ? 'Ver en el mapa' : 'Sin ubicación',
                          child: Opacity(
                            opacity: canViewOnMap ? 1.0 : 0.55,
                            child: ElevatedButton.icon(
                              onPressed: canViewOnMap
                                  ? () {
                                      print('DEBUG: Botón "Ver en el mapa" presionado para relato ${r.id}');
                                      print('DEBUG: Navegando al mapa con ubicación: (${r.ubicacion!.latitud}, ${r.ubicacion!.longitud})');
                                      
                                      // Obtener el NavigationProvider antes de cerrar  
                                      final nav = context.read<NavigationProvider>();
                                      
                                      // Establecer datos de navegación ANTES de cambiar de pantalla
                                      nav.setMapFocusRelatoId(r.id);
                                      if (r.ubicacion != null) {
                                        nav.setMapFocusLocation(
                                          lat: r.ubicacion!.latitud,
                                          lng: r.ubicacion!.longitud,
                                          radiusKm: 3, // Radio más específico para mejor centrado
                                        );
                                      }
                                      
                                      // Resolver root navigator/context para cambiar de tab y mostrar mensaje
                                      final rootNav = Navigator.of(context, rootNavigator: true);
                                      final rootCtx = rootNav.context;
                                      
                                      // Cerrar overlay
                                      Navigator.of(context).pop();
                                      
                                      // Cambiar al tab del mapa en el siguiente frame (sin depender del contexto del overlay)
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        try { nav.setIndex(1); } catch (_) {}
                                        try {
                                          ScaffoldMessenger.of(rootCtx).showSnackBar(
                                            SnackBar(
                                              content: Text('Mostrando "${r.titulo}" en el mapa'),
                                              duration: const Duration(seconds: 2),
                                              backgroundColor: AppColors.primary,
                                            ),
                                          );
                                        } catch (_) {}
                                      });
                                    }
                                  : null,
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Ver en el mapa'),
                            ),
                          ),
                        );
                      },
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Builder(
                          builder: (context) {
                            bool liked = false;
                            FeedProvider? feed;
                            try {
                              liked = context.select<FeedProvider, bool>((p) => p.isLiked(r.id));
                              feed = context.read<FeedProvider>();
                            } catch (_) {
                              feed = null;
                              liked = false;
                            }
                            final bool isOwner = feed?.currentUserId != null && r.autorId == feed!.currentUserId;
                            return IconButton(
                              tooltip: 'Me gusta',
                              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? AppColors.accent : null),
                              onPressed: feed == null || isOwner
                                  ? null
                                  : () async {
                                      final f = feed!;
                                      await f.toggleLike(r.id);
                                    },
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Compartir',
                          icon: const Icon(Icons.ios_share_outlined),
                          onPressed: () async {
                            FeedProvider? provider;
                            try {
                              provider = context.read<FeedProvider>();
                            } catch (_) {
                              provider = null;
                            }
                            final webUrl = Uri.parse('https://memoriaviva.app/relatos/${r.id}');
                            final resumen = r.contenido.length > 120 ? r.contenido.substring(0, 120) + '…' : r.contenido;
                            final message = '${r.titulo}\n\n$resumen\n\nEnlace: $webUrl';
                            await Share.share(message, subject: 'Relato – ${r.titulo}');
                            if (provider != null) {
                              await provider.compartir(r.id);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Reportar',
                          icon: const Icon(Icons.flag_outlined),
                          onPressed: () {
                            FeedProvider? feed;
                            try {
                              feed = context.read<FeedProvider>();
                            } catch (_) {
                              feed = null;
                            }
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
                                title: const Text('Reportar relato'),
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
                                      await f.reportRelato(relatoId: r.id, razon: reason);
                                      if (context.mounted) Navigator.pop(ctx);
                                    },
                                    child: const Text('Reportar'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
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
  int _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

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
    return Column(
      children: [
        SizedBox(
          height: mediaHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const PageScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: widget.multimedia.length,
                itemBuilder: (ctx, i) => _buildMedia(ctx, widget.multimedia[i]),
              ),
              // Controles de navegación opcionales por si el gesto es conflictivo en algunos dispositivos
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
                        final prev = (_index - 1).clamp(0, widget.multimedia.length - 1);
                        _pageController.animateToPage(prev, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.chevron_left, size: 28, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
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
                        final next = (_index + 1).clamp(0, widget.multimedia.length - 1);
                        _pageController.animateToPage(next, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: Icon(Icons.chevron_right, size: 28, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.multimedia.length, (i) => _dot(i == _index)),
        ),
      ],
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

  Widget _buildMedia(BuildContext context, Multimedia m) {
    switch (m.tipo) {
      case TipoMultimedia.imagen:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'relato_media_${m.url}',
              child: InteractiveViewer(
                minScale: 0.9,
                maxScale: 4.0,
                panEnabled: false,
                scaleEnabled: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                    final int targetW = (constraints.maxWidth * devicePixelRatio).clamp(360.0, 2000.0).round();
                    return CachedNetworkImage(
                      imageUrl: m.url,
                      memCacheWidth: targetW,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (c, _) => Container(color: AppColors.surfaceVariant),
                      errorWidget: (c, _, __) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      case TipoMultimedia.video:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _InlineVideo(key: ValueKey('overlay_video_${m.url}'), url: m.url),
        );
      case TipoMultimedia.audio:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _AudioPlayerCard(key: ValueKey('overlay_audio_${m.url}'), url: m.url),
        );
    }
  }
}

class _InlineVideo extends StatefulWidget {
  final String url;
  const _InlineVideo({super.key, required this.url});

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> with AutomaticKeepAliveClientMixin {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;
  String? _handlerKey;
  bool _isSeeking = false;
  Timer? _resumeDebounce;
  bool _wasPlayingBeforeSeek = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  // Debug helpers
  int _dbgLastDurMs = -1;
  int _dbgLastPosMs = -1;
  bool _dbgLastInit = false;
  bool _dbgLastBuf = false;
  String? _dbgLastErr;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // En web, habilitar uso de HTML video (HLS/MP4)
    final resolvedUrl = kIsWeb ? widget.url : _maybeToCloudinaryHls(widget.url);
    _controller = kIsWeb
        ? VideoPlayerController.network(resolvedUrl)
        : VideoPlayerController.networkUrl(
            Uri.parse(resolvedUrl),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            formatHint: _inferFormatFromUrl(resolvedUrl),
          )
      ..setLooping(false)
      ..initialize().then((_) async {
        _duration = _controller.value.duration;
        if (!kIsWeb && _duration == Duration.zero) {
          await _warmUpAndPollDuration(_controller, muted: _muted);
          _duration = _controller.value.duration;
        }
        if (mounted) setState(() => _initialized = true);
      });
    
    // Listener para actualizar posición y duración
    _controller.addListener(() {
      final value = _controller.value;
      if (!mounted || !value.isInitialized) return;
      if (_isSeeking) return;
      setState(() {
        _position = value.position;
        _duration = value.duration;
      });
      _dbgLogIfChanged(prefix: 'Inline');
    });
    
    // Registrar handler de pausa con scope 'overlay'
    try {
      final media = context.read<MediaPlaybackProvider>();
      _handlerKey = media.registerHandler(
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
      try { context.read<MediaPlaybackProvider>().unregisterHandlerByKey(_handlerKey!); } catch (_) {}
    }
    _controller.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Intenta inferir el formato de video para ayudar al plugin nativo
  /// cuando el servidor no expone cabeceras completas (móvil).
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
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex == -1) return url;
      if (uploadIndex + 1 < segments.length && !segments[uploadIndex + 1].startsWith('sp_')) {
        segments.insert(uploadIndex + 1, 'sp_auto');
      }
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
      final newUrl = newUri.toString();
      _dbgLog('Resolved Cloudinary HLS: $newUrl');
      return newUrl;
    } catch (_) {
      return url;
    }
  }

  Future<void> _warmUpAndPollDuration(VideoPlayerController controller, {required bool muted}) async {
    try {
      await controller.setVolume(0.0);
      await controller.play();
    } catch (_) {}
    final sw = Stopwatch()..start();
    while (mounted && sw.elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(milliseconds: 120));
      final d = controller.value.duration;
      if (d > Duration.zero) break;
    }
    try {
      await controller.pause();
      await controller.setVolume(muted ? 0.0 : 1.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _initialized && _controller.value.aspectRatio > 0 
            ? _controller.value.aspectRatio 
            : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video centrado y cubriendo el contenedor
            Positioned.fill(
              child: _initialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    )
                  : Container(color: AppColors.surfaceVariant),
            ),
            
            // Overlay oscuro para los controles
            Positioned.fill(child: Container(color: AppColors.imageOverlay.withOpacity(0.3))),
            
            // Botón central play/pause
            if (_initialized)
              Center(
                child: IconButton(
                  iconSize: 64,
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    try {
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
                      _dbgLog('Inline playToggle isPlaying=${_controller.value.isPlaying}');
                    } catch (e) {
                      print("Error al reproducir: $e");
                    }
                  },
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
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider para posición (seek al soltar en móviles)
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
                            _dbgLog('Inline seek start at ${_position.inMilliseconds}');
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
                            _dbgLog('Inline seek end to ${newPosition.inMilliseconds}');
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
                          
                          // Botón de pantalla completa
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                            onPressed: () async {
                              final start = await _controller.position ?? Duration.zero;
                              if (!mounted) return;
                              // Abrir página de pantalla completa
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _FullscreenVideoPage(url: widget.url, startAt: start),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            // Logo de prueba
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
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),

            // Debug overlay en modo debug
            if (kDebugMode)
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _dbgInfo(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _dbgLog(String msg) {
    // Prefijo útil para agrupar logs
    print('[VideoDBG] $msg | url=${widget.url}');
  }

  void _dbgLogIfChanged({required String prefix}) {
    final v = _controller.value;
    final durMs = v.duration.inMilliseconds;
    final posMs = v.position.inMilliseconds;
    final init = v.isInitialized;
    final buf = v.isBuffering;
    final err = v.errorDescription;
    if (durMs != _dbgLastDurMs || posMs != _dbgLastPosMs || init != _dbgLastInit || buf != _dbgLastBuf || err != _dbgLastErr) {
      _dbgLastDurMs = durMs;
      _dbgLastPosMs = posMs;
      _dbgLastInit = init;
      _dbgLastBuf = buf;
      _dbgLastErr = err;
      _dbgLog('$prefix state init=$init dur=$durMs pos=$posMs buf=$buf err=${err ?? 'none'}');
    }
  }

  String _dbgInfo() {
    final v = _controller.value;
    return 'init=${v.isInitialized} buf=${v.isBuffering}\n'
        'dur=${v.duration.inMilliseconds} pos=${v.position.inMilliseconds}\n'
        'play=${v.isPlaying} err=${v.errorDescription ?? 'none'}';
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final String url;
  final Duration startAt;
  const _FullscreenVideoPage({super.key, required this.url, required this.startAt});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;
  bool _isSeeking = false;
  Timer? _resumeDebounce;
  bool _wasPlayingBeforeSeek = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb
        ? VideoPlayerController.network(widget.url)
        : VideoPlayerController.networkUrl(
            Uri.parse(widget.url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            formatHint: _inferFormatFromUrl(widget.url),
          )
      ..setLooping(false)
      ..initialize().then((_) async {
        await _controller.seekTo(widget.startAt);
        _duration = _controller.value.duration;
        if (!kIsWeb && _duration == Duration.zero) {
          await _warmUpAndPollDuration(_controller, muted: _muted);
          _duration = _controller.value.duration;
        }
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      });
    
    // Listener para actualizar posición
    _controller.addListener(() {
      if (_controller.value.isInitialized && mounted && !_isSeeking) {
        setState(() {
          _position = _controller.value.position;
        });
      }
    });
    
    // Forzar orientación landscape para pantalla completa
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    _controller.dispose();
    // Restaurar orientación
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  VideoFormat? _inferFormatFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.mp4')) return VideoFormat.other;
    if (lower.contains('.m3u8')) return VideoFormat.hls;
    if (lower.contains('.webm')) return VideoFormat.other;
    if (lower.contains('.mov')) return VideoFormat.other;
    return null;
  }

  Future<void> _warmUpAndPollDuration(VideoPlayerController controller, {required bool muted}) async {
    try {
      await controller.setVolume(0.0);
      await controller.play();
    } catch (_) {}
    final sw = Stopwatch()..start();
    while (mounted && sw.elapsed < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(milliseconds: 120));
      final d = controller.value.duration;
      if (d > Duration.zero) break;
    }
    try {
      await controller.pause();
      await controller.setVolume(muted ? 0.0 : 1.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Reproduciendo'),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video centrado
            if (_initialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            else
              const CircularProgressIndicator(color: Colors.white),
              
            // Botón central play/pause
            if (_initialized)
              Center(
                child: IconButton(
                  iconSize: 64,
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      if (_controller.value.isPlaying) {
                        await _controller.pause();
                      } else {
                        if (_muted) {
                          await _controller.setVolume(1.0);
                          _muted = false;
                        }
                        await _controller.play();
                      }
                      if (mounted) setState(() {});
                    } catch (e) {
                      print("Error al reproducir: $e");
                    }
                  },
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
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Slider para posición (pantalla completa)
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
                            return p.clamp(0, maxMs).toDouble();
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
            
            // Logo de prueba
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
          ],
        ),
      ),
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  final String url;
  const _AudioPlayerCard({super.key, required this.url});

  @override
  State<_AudioPlayerCard> createState() => _AudioPlayerCardState();
}

class _AudioPlayerCardState extends State<_AudioPlayerCard> {
  late final AudioPlayer _player;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = true;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
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
      _posSub = _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      _durSub = _player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
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
    _posSub?.cancel();
    _durSub?.cancel();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _loading
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
            : Row(
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
                        max: () {
                          final m = _duration.inMilliseconds.toDouble();
                          return m < 1.0 ? 1.0 : m;
                        }(),
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


