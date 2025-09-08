import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/navigation_provider.dart';

class RelatoDetailOverlay extends StatelessWidget {
  final Relato relato;
  const RelatoDetailOverlay({super.key, required this.relato});

  static Future<void> open(BuildContext context, Relato relato) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: AppColors.withOpacity(AppColors.primaryDark, 0.6),
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OverlayScaffold(relato: relato),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _OverlayScaffold extends StatelessWidget {
  final Relato relato;
  const _OverlayScaffold({required this.relato});

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
                child: _DetailContent(relato: relato, controller: controller),
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
  final Relato relato;
  final ScrollController controller;
  const _DetailContent({required this.relato, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        SliverToBoxAdapter(child: _MediaCarousel(multimedia: relato.multimedia)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(relato.titulo, style: AppTypography.storyTitle),
                const SizedBox(height: 8),
                Text(
                  '${relato.autorNombre} • ${_formatFecha(relato.fechaCreacion)}'
                  '${relato.ubicacion != null ? ' • ' + relato.ubicacion!.obtenerDireccionFormateada() : ''}',
                  style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(relato.contenido, style: AppTypography.storyContent),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Categoría: ${relato.categoriaNombre}')
                  ]..addAll(relato.etiquetas.map((e) => _chip('#$e'))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<NavigationProvider>().setIndex(1);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Ver en el mapa'),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share_outlined)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.flag_outlined)),
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
    return Column(
      children: [
        SizedBox(
          height: 380,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        // Placeholder visual (integración de reproductor real se puede añadir luego)
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: m.obtenerThumbnailUrl(),
                  fit: BoxFit.cover,
                  placeholder: (c, _) => Container(color: AppColors.surfaceVariant),
                  errorWidget: (c, _, __) => Container(color: AppColors.surfaceVariant),
                ),
              ),
            ),
            const Positioned.fill(child: Center(child: Icon(Icons.play_circle_filled, size: 64, color: Colors.white)))
          ]),
        );
      case TipoMultimedia.audio:
        return _AudioPlayerCard(url: m.url);
    }
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
      _player.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
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
                      setState(() {});
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


