import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
import '../../providers/media_playback_provider.dart';

class RelatoCard extends StatelessWidget {
  final Relato relato;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final VoidCallback? onMore;
  final bool showMore;
  final bool isLiked;

  const RelatoCard({
    super.key,
    required this.relato,
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
    final List<Multimedia> medias = relato.multimedia;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth >= 900;
    const double maxCardWidth = 840;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? maxCardWidth : double.infinity),
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 12),
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
              // Borde sutil con color de acento; ancho 1 para eficiencia
              border: Border.all(color: AppColors.withOpacity(AppColors.accent, 0.18), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medias.isNotEmpty)
                  RepaintBoundary(child: _CardMediaCarousel(key: PageStorageKey('card_media_${relato.id}'), items: medias)),
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _AvatarCircle(name: relato.autorNombre),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${relato.autorNombre}${relato.ubicacion != null ? ' • ' + relato.ubicacion!.obtenerDireccionFormateada() : ''}',
                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                          _ActionIcon(icon: isLiked ? Icons.favorite : Icons.favorite_border, label: '${relato.likes}', onTap: onLike, active: isLiked),
                          const SizedBox(width: 8),
                          _ActionIcon(icon: Icons.ios_share_outlined, label: '${relato.compartidos}', onTap: onShare),
                          const Spacer(),
                          _ActionIcon(icon: Icons.flag_outlined, label: 'Reportar', onTap: onReport),
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

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _ActionIcon({required this.icon, required this.label, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active ? AppColors.withOpacity(AppColors.accent, 0.18) : AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: active ? AppColors.accent : AppColors.primary, size: 20),
            ),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String name;
  const _AvatarCircle({required this.name});

  @override
  Widget build(BuildContext context) {
    final String initials = name.isNotEmpty
        ? name.trim().split(RegExp(r"\s+")).take(2).map((e) => e[0].toUpperCase()).join()
        : '?';
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.withOpacity(AppColors.primary, 0.12),
      child: Text(initials, style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
                        final int targetW = (constraints.maxWidth * devicePixelRatio).clamp(360.0, 1600.0).round();
                        final String url = _cloudinaryScaled(media.url, width: targetW);
                        Widget image = CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          fadeInDuration: const Duration(milliseconds: 160),
                          fadeOutDuration: const Duration(milliseconds: 120),
                          placeholder: (c, _) => Container(color: AppColors.background),
                          errorWidget: (c, _, __) => Container(color: AppColors.background, child: const Icon(Icons.broken_image_outlined)),
                          memCacheWidth: targetW,
                        );
                        if (kIsWeb) {
                          image = MouseRegion(
                            onEnter: (_) {
                              // Precargar versión más grande al hover para minimizar jank al abrir overlay
                              final int preW = (targetW * 1.5).clamp(360, 2000).toInt();
                              final String preUrl = _cloudinaryScaled(media.url, width: preW);
                              precacheImage(CachedNetworkImageProvider(preUrl), context);
                            },
                            child: image,
                          );
                        }
                        return image;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case TipoMultimedia.video:
        return _LazyCardVideoPreview(key: ValueKey('card_video_${media.url}'), url: media.url);
      case TipoMultimedia.audio:
        return _InlineAudioPlayer(key: ValueKey('card_audio_${media.url}'), url: media.url);
      case TipoMultimedia.documento:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

class _CardMediaCarousel extends StatefulWidget {
  final List<Multimedia> items;
  const _CardMediaCarousel({super.key, required this.items});

  @override
  State<_CardMediaCarousel> createState() => _CardMediaCarouselState();
}

class _CardMediaCarouselState extends State<_CardMediaCarousel> {
  late final PageController _controller;
  int _index = 0;
  bool _autoplayTried = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showArrows = widget.items.length > 1;
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.items.length,
            itemBuilder: (ctx, i) => _MediaPreview(media: widget.items[i]),
          ),
          // Deshabilitar autoplay en carrusel para evitar decodificación simultánea
          if (!_autoplayTried) const SizedBox.shrink(),
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
                      final prev = (_index - 1).clamp(0, widget.items.length - 1);
                      _controller.animateToPage(prev, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
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
                      final next = (_index + 1).clamp(0, widget.items.length - 1);
                      _controller.animateToPage(next, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.chevron_right, size: 28, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          if (showArrows)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.items.length, (i) => _dot(i == _index)),
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
}

class _InlineAudioPlayer extends StatefulWidget {
  final String url;
  const _InlineAudioPlayer({super.key, required this.url});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _CardVideoPreview extends StatefulWidget {
  final String url;
  const _CardVideoPreview({super.key, required this.url});

  @override
  State<_CardVideoPreview> createState() => _CardVideoPreviewState();
}

class _LazyCardVideoPreview extends StatefulWidget {
  final String url;
  const _LazyCardVideoPreview({super.key, required this.url});

  @override
  State<_LazyCardVideoPreview> createState() => _LazyCardVideoPreviewState();
}

class _LazyCardVideoPreviewState extends State<_LazyCardVideoPreview> with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_activated) {
      return _CardVideoPreview(url: widget.url, key: ValueKey('active_${widget.url}'));
    }
    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(height: 200, color: AppColors.background),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black54, foregroundColor: Colors.white),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Cargar video'),
            onPressed: () {
              setState(() => _activated = true);
            },
          ),
        ],
      ),
    );
  }
}

class _CardVideoPreviewState extends State<_CardVideoPreview> with AutomaticKeepAliveClientMixin {
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
      _dbgLogIfChanged(prefix: 'Card');
    });
    
    // Registrar pausa global con ámbito 'card' sin leer provider en dispose
    try {
      _media = context.read<MediaPlaybackProvider>();
      _handlerKey = _media!.registerHandler(
        scope: 'card',
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
    if (lower.contains('.m3u8')) return VideoFormat.hls;
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
      final newUrl = newUri.toString();
      _dbgLog('Resolved Cloudinary HLS: $newUrl');
      return newUrl;
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

  void _dbgLog(String msg) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Container(
        color: AppColors.background,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video centrado con cover para que se vea bien en la card
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
                    : Container(color: AppColors.background),
              ),
              
              // Overlay oscuro para los controles
              Positioned.fill(child: Container(color: AppColors.imageOverlay)),
              
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
                      final media = context.read<MediaPlaybackProvider>();
                      if (_controller.value.isPlaying) {
                        await _controller.pause();
                      } else {
                        // Garantizar exclusividad antes de reproducir
                        final excludeKey = media.keyFor(scope: 'card', sourceId: widget.url);
                        await media.willStartPlayback(scope: 'card', sourceId: widget.url, tipo: 'video', excludeKey: excludeKey);
                        if (_muted) {
                          await _controller.setVolume(1.0);
                          _muted = false;
                        }
                        await _controller.play();
                      }
                      if (mounted) setState(() {});
                      _dbgLog('Card playToggle isPlaying=${_controller.value.isPlaying}');
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
                const Center(child: CircularProgressIndicator()),

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
      ),
    );
  }
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> with AutomaticKeepAliveClientMixin {
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
  bool get wantKeepAlive => true;

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
      // Registrar pausa global con ámbito 'card'
      try {
        final media = context.read<MediaPlaybackProvider>();
        _handlerKey = media.registerHandler(
          scope: 'card',
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
    super.build(context);
    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
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
          IconButton(
            icon: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final playing = _player.playing;
                return Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 32);
              },
            ),
            onPressed: () async {
              final media = context.read<MediaPlaybackProvider>();
              if (_player.playing) {
                await _player.pause();
              } else {
                await media.willStartPlayback(scope: 'card', sourceId: widget.url, tipo: 'audio');
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
                  _resumeDebounce = Timer(const Duration(milliseconds: 150), () {
                    if (mounted) _player.play();
                  });
                }
                _isSeeking = false;
              },
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${_fmt(_position)} / ${_fmt(_duration)}', style: AppTypography.metadata.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
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
        final Color chipColor = AppColors.categoryColor(categoryId: categoriaId, hex: categoria?.color);
        final String iconPath = _resolveIconPath(categoria?.icono);
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
              CulturalIcon(svgPath: iconPath, size: 16, color: chipColor),
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
