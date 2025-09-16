import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart';
import 'package:get_it/get_it.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/repositories/evento_cultural_repository.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/eventos_provider.dart';
import '../../providers/media_playback_provider.dart';

class EventoDetailOverlay extends StatelessWidget {
  final EventoCultural evento;
  const EventoDetailOverlay({super.key, required this.evento});

  static Future<void> open(BuildContext context, EventoCultural? evento, {String? eventoId}) async {
    // Antes de abrir: pausar reproducción en cards
    try {
      final media = context.read<MediaPlaybackProvider>();
      await media.pauseScope('card', relatoId: evento?.id ?? eventoId);
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
    EventosProvider? eventosProvider;
    try {
      eventosProvider = rootContext.read<EventosProvider>();
    } catch (_) {
      eventosProvider = null;
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
        final content = _OverlayScaffold(evento: evento, eventoId: eventoId);
        if (eventosProvider != null) {
          // Inyectar el EventosProvider existente
          return ChangeNotifierProvider<EventosProvider>.value(
            value: eventosProvider!,
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
  final EventoCultural? evento;
  final String? eventoId;
  const _OverlayScaffold({required this.evento, this.eventoId});

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
                child: _DetailContent(evento: evento, eventoId: eventoId, controller: controller),
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
  final EventoCultural? evento;
  final String? eventoId;
  final ScrollController controller;
  const _DetailContent({required this.evento, this.eventoId, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (evento == null) {
      if (eventoId == null || eventoId!.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final repo = GetIt.I<IEventoCulturalRepository>();
      return StreamBuilder<EventoCultural?>(
        stream: repo.observarEventoPorId(eventoId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final e = snapshot.data!;
          return _buildContent(context, e);
        },
      );
    }

    final EventoCultural e = evento!;

    return _buildContent(context, e);
  }

  Widget _buildContent(BuildContext context, EventoCultural e) {
    return CustomScrollView(
      controller: controller,
      slivers: [
        if (e.imagenes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: _MediaCarousel(multimedia: e.imagenes),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.titulo, style: AppTypography.storyTitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _formatFechaEvento(e.fechaInicio, e.fechaFin),
                      style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.ubicacion.obtenerDireccionFormateada(),
                        style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (e.esRecurrente && e.frecuencia != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.repeat, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Evento ${e.frecuencia}',
                        style: AppTypography.metadata.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(e.descripcion, style: AppTypography.storyContent),
                const SizedBox(height: 12),
                _categoriaChip(context, e.categoriaId, e.categoriaNombre),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) {
                        final bool canViewOnMap = true; // Eventos siempre tienen ubicación
                        return Tooltip(
                          message: 'Ver en el mapa',
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Obtener el NavigationProvider antes de cerrar  
                              final nav = context.read<NavigationProvider>();
                              
                               // Establecer datos de navegación ANTES de cambiar de pantalla
                               nav.setMapFocusRelatoId(e.id);
                               nav.setMapFocusLocation(
                                lat: e.ubicacion.latitud,
                                lng: e.ubicacion.longitud,
                                radiusKm: 3, // Radio más específico para mejor centrado
                              );
                              
                              // Resolver root navigator/context para cambiar de tab y mostrar mensaje
                              final rootNav = Navigator.of(context, rootNavigator: true);
                              final rootCtx = rootNav.context;
                              
                              // Cerrar overlay
                              Navigator.of(context).pop();
                              
                              // Cambiar al tab del mapa en el siguiente frame
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                try { nav.setIndex(1); } catch (_) {}
                                try {
                                  ScaffoldMessenger.of(rootCtx).showSnackBar(
                                    SnackBar(
                                      content: Text('Mostrando "${e.titulo}" en el mapa'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                } catch (_) {}
                              });
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Ver en el mapa'),
                          ),
                        );
                      },
                    ),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Compartir',
                          icon: const Icon(Icons.ios_share_outlined),
                          onPressed: () async {
                            final webUrl = Uri.parse('https://memoriaviva.app/eventos/${e.id}');
                            final resumen = e.descripcion.length > 120 ? e.descripcion.substring(0, 120) + '…' : e.descripcion;
                            final message = '${e.titulo}\n\n$resumen\n\nFecha: ${_formatFechaEvento(e.fechaInicio, e.fechaFin)}\n\nEnlace: $webUrl';
                            await Share.share(message, subject: 'Evento – ${e.titulo}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.withOpacity(AppColors.primary, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del organizador',
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              e.organizador,
                              style: AppTypography.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (e.contacto != null && e.contacto!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.contact_mail_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.contacto!,
                                style: AppTypography.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatFechaEvento(DateTime inicio, DateTime fin) {
    final bool mismoMes = inicio.month == fin.month && inicio.year == fin.year;
    final bool mismoDia = inicio.day == fin.day && mismoMes;
    
    if (mismoDia) {
      // Mismo día: "17/09/2025 • 14:00 - 18:00"
      return '${_formatFecha(inicio)} • ${_formatHora(inicio)} - ${_formatHora(fin)}';
    } else if (mismoMes) {
      // Mismo mes: "17-18/09/2025"
      return '${inicio.day}-${fin.day}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
    } else {
      // Diferentes meses: "17/09/2025 - 02/10/2025"
      return '${_formatFecha(inicio)} - ${_formatFecha(fin)}';
    }
  }

  String _formatFecha(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatHora(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

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
              // Controles de navegación
              if (widget.multimedia.length > 1) ...[
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
            ],
          ),
        ),
        if (widget.multimedia.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.multimedia.length, (i) => _dot(i == _index)),
          ),
        ],
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
              tag: 'evento_media_${m.url}',
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
      // Eventos generalmente solo usan imágenes, pero mantenemos compatibilidad
      case TipoMultimedia.video:
      case TipoMultimedia.audio:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: Text(
              'Este tipo de contenido no está disponible',
              style: AppTypography.textTheme.bodyMedium,
            ),
          ),
        );
    }
  }
}
