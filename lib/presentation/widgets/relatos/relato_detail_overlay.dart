import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class RelatoDetailOverlay extends StatelessWidget {
  final Relato relato;
  const RelatoDetailOverlay({super.key, required this.relato});

  static Future<void> open(BuildContext context, Relato? relato, {String? relatoId}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.withOpacity(AppColors.primaryDark, 0.6),
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OverlayScaffold(relato: relato, relatoId: relatoId),
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
                    _chip('Categoría: ${r.categoriaNombre}')
                  ]..addAll(r.etiquetas.map((e) => _chip('#$e'))),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<NavigationProvider>().setIndex(1);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver en el mapa'),
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
                            return IconButton(
                              tooltip: 'Me gusta',
                              icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? AppColors.accent : null),
                              onPressed: feed == null
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
}

class _MediaCarousel extends StatefulWidget {
  final List<Multimedia> multimedia;
  const _MediaCarousel({required this.multimedia});

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
                child: CachedNetworkImage(
                  imageUrl: m.url,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  placeholder: (c, _) => Container(color: AppColors.surfaceVariant),
                  errorWidget: (c, _, __) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
          ),
        );
      case TipoMultimedia.video:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _InlineVideo(url: m.url),
        );
      case TipoMultimedia.audio:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: _AudioPlayerCard(url: m.url),
        );
    }
  }
}

class _InlineVideo extends StatefulWidget {
  final String url;
  const _InlineVideo({required this.url});

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    // En web, habilitar uso de HTML video (HLS/MP4)
    _controller = kIsWeb
        ? VideoPlayerController.network(widget.url)
        : VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(false)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: AppColors.surfaceVariant, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video centrado y cubriendo el contenedor
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            // Botón central play/pause
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white),
                onPressed: () async {
                  if (_controller.value.isPlaying) {
                    await _controller.pause();
                  } else {
                    await _controller.play();
                  }
                  if (mounted) setState(() {});
                },
              ),
            ),
            // Barra de controles inferior (overlay) para evitar overflow vertical
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                      onPressed: () async {
                        if (_controller.value.isPlaying) {
                          await _controller.pause();
                        } else {
                          await _controller.play();
                        }
                        if (mounted) setState(() {});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () async {
                        final pos = await _controller.position ?? Duration.zero;
                        final target = pos - const Duration(seconds: 10);
                        await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () async {
                        final pos = await _controller.position ?? Duration.zero;
                        final dur = _controller.value.duration;
                        final target = pos + const Duration(seconds: 10);
                        await _controller.seekTo(target > dur ? dur : target);
                      },
                    ),
                    IconButton(
                      icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: () async {
                        _muted = !_muted;
                        await _controller.setVolume(_muted ? 0.0 : 1.0);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (d) async {
                          final dur = _controller.value.duration;
                          if (dur == Duration.zero) return;
                          final w = MediaQuery.of(context).size.width;
                          final delta = (d.primaryDelta ?? 0) / w;
                          final current = await _controller.position ?? Duration.zero;
                          final target = current + Duration(milliseconds: (dur.inMilliseconds * delta).toInt());
                          final clamped = target < Duration.zero
                              ? Duration.zero
                              : (target > dur ? dur : target);
                          await _controller.seekTo(clamped);
                        },
                        child: VideoProgressIndicator(_controller, allowScrubbing: true, colors: VideoProgressColors(playedColor: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Pantalla completa',
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final String url;
  final Duration startAt;
  const _FullscreenVideoPage({required this.url, required this.startAt});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb
        ? VideoPlayerController.network(widget.url)
        : VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(false)
      ..initialize().then((_) async {
        await _controller.seekTo(widget.startAt);
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: _initialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio == 0 ? 16 / 9 : _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black45,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                            onPressed: () async {
                              if (_controller.value.isPlaying) {
                                await _controller.pause();
                              } else {
                                await _controller.play();
                              }
                              if (mounted) setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                            onPressed: () async {
                              final pos = await _controller.position ?? Duration.zero;
                              final target = pos - const Duration(seconds: 10);
                              await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                            onPressed: () async {
                              final pos = await _controller.position ?? Duration.zero;
                              final dur = _controller.value.duration;
                              final target = pos + const Duration(seconds: 10);
                              await _controller.seekTo(target > dur ? dur : target);
                            },
                          ),
                          IconButton(
                            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                            onPressed: () async {
                              _muted = !_muted;
                              await _controller.setVolume(_muted ? 0.0 : 1.0);
                              if (mounted) setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: VideoProgressIndicator(_controller, allowScrubbing: true, colors: VideoProgressColors(playedColor: Colors.white))),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _AudioPlayerCard extends StatefulWidget {
  final String url;
  const _AudioPlayerCard({required this.url});

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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
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
                      if (_player.playing) {
                        await _player.pause();
                      } else {
                        await _player.play();
                      }
                      if (mounted) setState(() {});
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                      value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                      onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
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


