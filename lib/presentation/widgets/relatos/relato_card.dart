import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                )
              ],
              border: Border.all(color: AppColors.withOpacity(AppColors.primary, 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (medias.isNotEmpty)
                  _CardMediaCarousel(items: medias),
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
        return _CardVideoPreview(url: media.url);
      case TipoMultimedia.audio:
        return _InlineAudioPlayer(url: media.url);
    }
  }
}

class _CardMediaCarousel extends StatefulWidget {
  final List<Multimedia> items;
  const _CardMediaCarousel({required this.items});

  @override
  State<_CardMediaCarousel> createState() => _CardMediaCarouselState();
}

class _CardMediaCarouselState extends State<_CardMediaCarousel> {
  late final PageController _controller;
  int _index = 0;

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
  const _InlineAudioPlayer({required this.url});

  @override
  State<_InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _CardVideoPreview extends StatefulWidget {
  final String url;
  const _CardVideoPreview({required this.url});

  @override
  State<_CardVideoPreview> createState() => _CardVideoPreviewState();
}

class _CardVideoPreviewState extends State<_CardVideoPreview> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
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
              Positioned.fill(child: IgnorePointer(child: Container(color: AppColors.imageOverlay))),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: !_initialized
                          ? null
                          : () async {
                              final pos = await _controller.position ?? Duration.zero;
                              final target = pos - const Duration(seconds: 10);
                              await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
                            },
                    ),
                    IconButton(
                      icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 30),
                      onPressed: !_initialized
                          ? null
                          : () async {
                              if (_controller.value.isPlaying) {
                                await _controller.pause();
                              } else {
                                await _controller.play();
                              }
                              if (mounted) setState(() {});
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: !_initialized
                          ? null
                          : () async {
                              final pos = await _controller.position ?? Duration.zero;
                              final dur = _controller.value.duration;
                              final target = pos + const Duration(seconds: 10);
                              await _controller.seekTo(target > dur ? dur : target);
                            },
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: !_initialized
                          ? null
                          : () async {
                              _muted = !_muted;
                              await _controller.setVolume(_muted ? 0.0 : 1.0);
                              if (mounted) setState(() {});
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineAudioPlayerState extends State<_InlineAudioPlayer> {
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

