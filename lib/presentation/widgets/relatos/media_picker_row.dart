import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../providers/relatos/relato_form_provider.dart';

class MediaPickerRow extends StatelessWidget {
  const MediaPickerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Multimedia', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(
              icon: Icons.photo_outlined,
              label: 'Galería',
              onTap: provider.addImagenDesdeGaleria,
            ),
            _ActionButton(
              icon: Icons.photo_camera_outlined,
              label: 'Cámara',
              onTap: provider.addImagenDesdeCamara,
            ),
            _ActionButton(
              icon: Icons.attach_file_outlined,
              label: 'Archivos',
              onTap: provider.addDesdeArchivos,
            ),
            _ActionButton(
              icon: provider.grabando ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
              label: provider.grabando ? 'Detener' : 'Grabar audio',
              onTap: provider.grabando ? provider.detenerGrabacionAudio : provider.iniciarGrabacionAudio,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final u in provider.uploads)
              _UploadChip(
                id: u.id,
                label: u.tipo == TipoMultimedia.imagen
                    ? 'Imagen'
                    : (u.tipo == TipoMultimedia.video ? 'Video' : 'Audio'),
                status: u.status,
                progress: u.progress,
                onDelete: () => provider.eliminarMedia(u.id),
                onCancel: () => provider.cancelUpload(u.id),
                onRetry: () => provider.retryUpload(u.id),
              ),
          ],
        ),
        if (provider.hasPendingUploads)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('Subiendo archivos...', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _UploadChip extends StatelessWidget {
  final String id;
  final String label;
  final UploadStatus status;
  final double progress;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _UploadChip({
    required this.id,
    required this.label,
    required this.status,
    required this.progress,
    required this.onDelete,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Widget trailing;
    switch (status) {
      case UploadStatus.queued:
        color = AppColors.textSecondary;
        trailing = const Icon(Icons.schedule, size: 16);
        break;
      case UploadStatus.uploading:
        color = AppColors.primary;
        trailing = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress / 100.0,
          ),
        );
        break;
      case UploadStatus.done:
        color = AppColors.success;
        trailing = const Icon(Icons.check_circle_outline, size: 16);
        break;
      case UploadStatus.error:
        color = AppColors.error;
        trailing = const Icon(Icons.error_outline, size: 16);
        break;
      case UploadStatus.cancelled:
        color = AppColors.textSecondary;
        trailing = const Icon(Icons.cancel_outlined, size: 16);
        break;
    }

    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(width: 6),
          trailing,
        ],
      ),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 16),
      onPressed: () {},
      avatar: status == UploadStatus.uploading
          ? IconButton(
              icon: const Icon(Icons.cancel, size: 16),
              tooltip: 'Cancelar',
              onPressed: onCancel,
            )
          : (status == UploadStatus.error
              ? IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  tooltip: 'Reintentar',
                  onPressed: onRetry,
                )
              : null),
    );
  }
}


