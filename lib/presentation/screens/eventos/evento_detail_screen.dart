import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/evento_cultural.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../utils/date_formatter.dart';
import '../../providers/navigation_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class EventoDetailScreen extends StatelessWidget {
  final EventoCultural evento;
  const EventoDetailScreen({super.key, required this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(evento.titulo, style: AppTypography.textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Compartir',
            icon: const Icon(Icons.ios_share_outlined),
            onPressed: () async {
              final webUrl = Uri.parse('https://memoriaviva.app/eventos/${evento.id}');
              final resumen = evento.descripcion.length > 120 ? evento.descripcion.substring(0, 120) + '…' : evento.descripcion;
              final message = '${evento.titulo}\n\n$resumen\n\nFecha: ${DateFormatter.formatEventDateRange(evento.fechaInicio, evento.fechaFin)}\n\nEnlace: $webUrl';
              await Share.share(message, subject: 'Evento – ${evento.titulo}');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (evento.imagenes.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: evento.imagenes.length,
                  itemBuilder: (context, index) {
                    final url = evento.imagenes[index].url;
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => Container(color: AppColors.background),
                      errorWidget: (c, _, __) => const Icon(Icons.broken_image_outlined),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(evento.titulo, style: AppTypography.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(DateFormatter.formatEventDateTimeRange(evento.fechaInicio, evento.fechaFin),
                              style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${evento.ubicacion.municipio ?? ''}${evento.ubicacion.municipio != null && evento.ubicacion.departamento != null ? ', ' : ''}${evento.ubicacion.departamento ?? ''}',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (evento.esRecurrente && evento.frecuencia != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Evento ${evento.frecuencia}', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _CategoriaChip(nombre: evento.categoriaNombre, categoriaId: evento.categoriaId),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.withOpacity(AppColors.primary, 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.withOpacity(AppColors.primary, 0.12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Organizador', style: AppTypography.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(evento.organizador, style: AppTypography.textTheme.bodyMedium)),
                          ],
                        ),
                        if (evento.contacto != null && evento.contacto!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.contact_mail_outlined, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(child: Text(evento.contacto!, style: AppTypography.textTheme.bodyMedium)),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Descripción', style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(evento.descripcion, style: AppTypography.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final nav = context.read<NavigationProvider>();
                          nav.setMapFocusRelatoId(evento.id);
                          nav.setMapFocusLocation(lat: evento.ubicacion.latitud, lng: evento.ubicacion.longitud, radiusKm: 3);
                          Navigator.of(context).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            try { nav.setIndex(1); } catch (_) {}
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Mostrando "${evento.titulo}" en el mapa'),
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
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

}

class _CategoriaChip extends StatelessWidget {
  final String nombre;
  final String categoriaId;
  const _CategoriaChip({required this.nombre, required this.categoriaId});

  @override
  Widget build(BuildContext context) {
    final Color chipColor = AppColors.categoryColor(categoryId: categoriaId);
    final bool isDark = (Theme.of(context).brightness == Brightness.dark);
    final Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(chipColor, 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.withOpacity(chipColor, 0.50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            nombre,
            style: AppTypography.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


