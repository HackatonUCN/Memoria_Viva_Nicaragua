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
      barrierColor: AppColors.withOpacity(AppColors.primaryDark, 0.45),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final content = _FadeIn(child: _OverlayScaffold(evento: evento, eventoId: eventoId));
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

class _FadeIn extends StatefulWidget {
  final Widget child;
  const _FadeIn({required this.child});
  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
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
        // Imágenes del evento
        if (e.imagenes.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _MediaCarousel(multimedia: e.imagenes),
            ),
          ),
        
        // Contenido principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del evento
                Text(
                  e.titulo, 
                  style: AppTypography.storyTitle.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Información principal del evento
                _buildEventInfoCard(context, e),
                const SizedBox(height: 20),

                // Descripción
                _buildDescriptionSection(context, e),
                const SizedBox(height: 20),

                // Categoría
                _buildCategorySection(context, e),
                const SizedBox(height: 24),

                // Información del organizador
                _buildOrganizerSection(context, e),
                const SizedBox(height: 24),

                // Botones de acción
                _buildActionButtons(context, e),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventInfoCard(BuildContext context, EventoCultural e) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Fecha
          _buildInfoRow(
            icon: Icons.event,
            title: 'Fecha y hora',
            content: _formatFechaEvento(e.fechaInicio, e.fechaFin),
          ),
          const SizedBox(height: 12),
          
          // Ubicación
          _buildInfoRow(
            icon: Icons.place_outlined,
            title: 'Ubicación',
            content: e.ubicacion.obtenerDireccionFormateada(),
          ),
          
          // Frecuencia (si es recurrente)
          if (e.esRecurrente && e.frecuencia != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.repeat,
              title: 'Frecuencia',
              content: 'Evento ${e.frecuencia}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, EventoCultural e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            e.descripcion,
            style: AppTypography.storyContent.copyWith(
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, EventoCultural e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categoría',
          style: AppTypography.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _categoriaChip(context, e.categoriaId, e.categoriaNombre),
      ],
    );
  }

  Widget _buildOrganizerSection(BuildContext context, EventoCultural e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizador',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.organizador,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (e.contacto != null && e.contacto!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.contact_mail_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.contacto!,
                    style: AppTypography.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EventoCultural e) {
    return Row(
      children: [
        // Botón Ver en el mapa
        Expanded(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver en el mapa'),
          ),
        ),
        const SizedBox(width: 12),
        
        // Botón Compartir
        ElevatedButton(
          onPressed: () async {
            final webUrl = Uri.parse('https://memoriaviva.app/eventos/${e.id}');
            final resumen = e.descripcion.length > 120 ? e.descripcion.substring(0, 120) + '…' : e.descripcion;
            final message = '${e.titulo}\n\n$resumen\n\nFecha: ${_formatFechaEvento(e.fechaInicio, e.fechaFin)}\n\nEnlace: $webUrl';
            await Share.share(message, subject: 'Evento – ${e.titulo}');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.ios_share_outlined),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(chipColor, 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.withOpacity(chipColor, 0.5),
          width: 1,
        ),
      ),
      child: Text(
        categoriaNombre,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      case TipoMultimedia.documento:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}
