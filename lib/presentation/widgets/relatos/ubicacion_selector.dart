import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../screens/mapa/map_picker_screen.dart';
import '../../providers/relatos/relato_form_provider.dart';

class UbicacionSelector extends StatelessWidget {
  const UbicacionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    final hasLocation = provider.departamento != null && provider.municipio != null;
    final subtitle = hasLocation
        ? '${provider.departamento} / ${provider.municipio}\n(${provider.latitud?.toStringAsFixed(5)}, ${provider.longitud?.toStringAsFixed(5)})'
        : 'Usaremos tu ubicación actual al publicar (si falla, se publicará sin ubicación)';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ubicación', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await Navigator.of(context).push<MapPickerResult>(
                MaterialPageRoute(builder: (_) => const MapPickerScreen()),
              );
              if (picked != null) {
                context.read<RelatoFormProvider>().setUbicacion(
                      dep: picked.departamento,
                      mun: picked.municipio,
                      lat: picked.latitud,
                      lng: picked.longitud,
                    );
              }
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ubicar en el mapa'),
          )
        ],
      ),
    );
  }
}


