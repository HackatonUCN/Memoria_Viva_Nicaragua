import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/eventos_provider.dart';

class ModeracionSugerenciasScreen extends StatelessWidget {
  const ModeracionSugerenciasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EventosProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Sugerencias de eventos')),
          body: provider.sugerenciasLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: provider.loadSugerenciasPendientes,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: provider.sugerenciasPendientes.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final s = provider.sugerenciasPendientes[i];
                      return ListTile(
                        leading: const Icon(Icons.pending_outlined),
                        title: Text(s.nombre, style: AppTypography.textTheme.titleMedium),
                        subtitle: Text('${s.descripcion}\n${s.ubicacion.departamento ?? ''} ${s.ubicacion.municipio ?? ''}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Aprobar',
                              icon: const Icon(Icons.check_circle, color: AppColors.success),
                              onPressed: () async {
                                final err = await provider.aprobarSugerencia(s.id);
                                if (err != null && ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(err)));
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Rechazar',
                              icon: const Icon(Icons.cancel, color: AppColors.error),
                              onPressed: () async {
                                final razon = await _pedirRazon(ctx);
                                if (razon == null) return;
                                final err = await provider.rechazarSugerencia(s.id, razon: razon);
                                if (err != null && ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(backgroundColor: AppColors.error, content: Text(err)));
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

Future<String?> _pedirRazon(BuildContext context) async {
  final controller = TextEditingController();
  final res = await showDialog<String?>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Motivo del rechazo'),
      content: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(hintText: 'Describe brevemente el motivo'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Rechazar')),
      ],
    ),
  );
  return (res != null && res.trim().isNotEmpty) ? res.trim() : null;
}


