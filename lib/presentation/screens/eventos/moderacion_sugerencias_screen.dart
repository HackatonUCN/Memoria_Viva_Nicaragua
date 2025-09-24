import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/evento_cultural.dart';
import '../../../utils/date_formatter.dart';
import '../../providers/eventos_provider.dart';

class ModeracionSugerenciasScreen extends StatelessWidget {
  const ModeracionSugerenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventosProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Sugerencias de eventos'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.loadSugerenciasPendientes,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          body: provider.sugerenciasLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.sugerenciasError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar sugerencias',
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.sugerenciasError!,
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: provider.loadSugerenciasPendientes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
              : provider.sugerenciasPendientes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay sugerencias pendientes',
                            style: AppTypography.textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las nuevas sugerencias de eventos aparecerán aquí',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: provider.loadSugerenciasPendientes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Actualizar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.loadSugerenciasPendientes,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.sugerenciasPendientes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (ctx, i) {
                          final s = provider.sugerenciasPendientes[i];
                          return _SugerenciaCard(
                            sugerencia: s,
                            onAprobar: () => _aprobarSugerencia(ctx, provider, s),
                            onRechazar: () => _rechazarSugerencia(ctx, provider, s),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }

  Future<void> _aprobarSugerencia(BuildContext context, EventosProvider provider, SugerenciaEvento sugerencia) async {
    final confirmed = await _confirmarAprobacion(context, sugerencia);
    if (!confirmed) return;

    final err = await provider.aprobarSugerencia(sugerencia.id);
    if (context.mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error: $err'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Sugerencia "${sugerencia.nombre}" aprobada y convertida a evento'),
          ),
        );
      }
    }
  }

  Future<void> _rechazarSugerencia(BuildContext context, EventosProvider provider, SugerenciaEvento sugerencia) async {
    final razon = await _pedirRazon(context);
    if (razon == null) return;

    final err = await provider.rechazarSugerencia(sugerencia.id, razon: razon);
    if (context.mounted) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error: $err'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text('Sugerencia "${sugerencia.nombre}" rechazada'),
          ),
        );
      }
    }
  }

  Future<bool> _confirmarAprobacion(BuildContext context, SugerenciaEvento sugerencia) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar sugerencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres aprobar esta sugerencia?'),
            const SizedBox(height: 16),
            Text(
              'Se creará un evento oficial con el nombre "${sugerencia.nombre}"',
              style: AppTypography.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

Future<String?> _pedirRazon(BuildContext context) async {
  final controller = TextEditingController();
  final res = await showDialog<String?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Motivo del rechazo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Por favor, explica brevemente por qué rechazas esta sugerencia:'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Ej: Información incompleta, fecha incorrecta, etc.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Rechazar'),
        ),
      ],
    ),
  );
  return (res != null && res.trim().isNotEmpty) ? res.trim() : null;
}

class _SugerenciaCard extends StatelessWidget {
  final SugerenciaEvento sugerencia;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _SugerenciaCard({
    required this.sugerencia,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final fechaFormateada = DateFormatter.formatEventDateRange(
      sugerencia.fechaInicio,
      sugerencia.fechaFin,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    sugerencia.nombre,
                    style: AppTypography.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información básica
            _InfoRow(
              icon: Icons.event,
              label: 'Fecha',
              value: fechaFormateada,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.place_outlined,
              label: 'Ubicación',
              value: sugerencia.ubicacion.obtenerDireccionFormateada(),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Organizador',
              value: sugerencia.organizador,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.account_circle,
              label: 'Sugerido por',
              value: sugerencia.sugeridoPorNombre,
            ),
            const SizedBox(height: 12),

            // Descripción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sugerencia.descripcion,
                style: AppTypography.textTheme.bodyMedium,
              ),
            ),

            // Información adicional si existe
            if (sugerencia.contacto?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.contact_mail_outlined,
                label: 'Contacto',
                value: sugerencia.contacto!,
              ),
            ],

            if (sugerencia.esRecurrente && sugerencia.frecuencia != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.repeat,
                label: 'Frecuencia',
                value: 'Evento ${sugerencia.frecuencia}',
              ),
            ],

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAprobar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aprobar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


