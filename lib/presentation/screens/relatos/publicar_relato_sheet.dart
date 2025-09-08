import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../domain/entities/relato.dart';
import '../../providers/relatos/relato_form_provider.dart';
import '../../widgets/relatos/media_picker_row.dart';
import '../../widgets/relatos/ubicacion_selector.dart';

class PublicarRelatoSheet extends StatelessWidget {
  const PublicarRelatoSheet({super.key});

  static Future<bool?> open(BuildContext context, {Relato? initialRelato}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => RelatoFormProvider()
            ..init()
            ..loadRelatoForEditIfNeeded(initialRelato),
          child: const _SheetScaffold(),
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    // Este widget se usa a través del método estático open().
    // Retornar un placeholder evita errores si se llegara a insertar en el árbol.
    return const SizedBox.shrink();
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final paddingBottom = viewInsets.bottom > 0 ? viewInsets.bottom : 24.0;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: const _Content(),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header decorado
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.nicaraguaGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textLight)),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Publicar Relato', style: AppTypography.textTheme.displaySmall?.copyWith(color: AppColors.textLight)),
                      const SizedBox(height: 2),
                      Text(
                        'Comparte tus memorias culturales con la comunidad',
                        style: AppTypography.metadata.copyWith(color: AppColors.withOpacity(AppColors.textLight, 0.9)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textLight,
                  ),
                  onPressed: provider.formularioValido && !provider.isPublishing ? () async {
                    final uid = context.read<RelatoFormProvider>();
                    debugPrint('[PUBLICAR_SHEET][PRESS] t=${DateTime.now().toIso8601String()} uid=${uid}');
                    final ok = await context.read<RelatoFormProvider>().publicar();
                    if (!context.mounted) return;
                    if (ok) {
                      final offline = context.read<RelatoFormProvider>().lastPublishOffline;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: offline ? AppColors.warning : AppColors.success,
                          content: Text(
                            offline
                                ? 'Sin conexión: tu relato se publicará cuando vuelvas a estar en línea'
                                : (provider.isEditing ? 'Cambios guardados' : 'Relato publicado con éxito'),
                          ),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    } else if (provider.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(backgroundColor: AppColors.error, content: Text(provider.errorMessage!)),
                      );
                    }
                  } : null,
                  child: provider.isPublishing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(provider.isEditing ? 'Guardar cambios' : 'Publicar'),
                )
              ],
            ),
          ),

          const Divider(height: 1),

          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 720;
                final EdgeInsets bodyPad = EdgeInsets.symmetric(horizontal: isWide ? 20 : 16, vertical: 16);
                if (!isWide) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: bodyPad,
                    child: Column(
                      children: const [
                        _ContentSection(),
                        SizedBox(height: 16),
                        _MetaSection(),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: bodyPad,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Expanded(flex: 3, child: _ContentSection()),
                      SizedBox(width: 16),
                      Expanded(flex: 2, child: _MetaSection()),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriaDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    if (provider.categoriasLoading) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: LinearProgressIndicator(),
        subtitle: Text('Cargando categorías...'),
      );
    }
    if (provider.categoriasError != null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Categoría'),
        subtitle: Text(provider.categoriasError!, style: const TextStyle(color: AppColors.error)),
      );
    }
    return DropdownButtonFormField<String>(
      value: provider.categoriaId,
      decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
      items: provider.categorias
          .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.nombre)))
          .toList(),
      onChanged: provider.setCategoria,
      validator: (_) => provider.categoriaValida ? null : 'Selecciona una categoría',
    );
  }
}

class _EtiquetasChips extends StatefulWidget {
  @override
  State<_EtiquetasChips> createState() => _EtiquetasChipsState();
}

class _EtiquetasChipsState extends State<_EtiquetasChips> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Etiquetas', style: AppTypography.textTheme.titleMedium?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in provider.etiquetas)
              Chip(
                label: Text(e),
                onDeleted: () => provider.removeEtiqueta(e),
              ),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Añadir etiqueta y Enter',
                ),
                onSubmitted: (v) {
                  provider.addEtiqueta(v);
                  _controller.clear();
                },
              ),
            )
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Máximo 10, sin duplicados',
          style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: AppColors.accentGradient, shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.textTheme.titleLarge?.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    return _SectionCard(
      title: 'Contenido del Relato',
      icon: Icons.edit_outlined,
      children: [
        _CounterField(
          label: 'Título',
          icon: Icons.title_outlined,
          helper: 'Entre 5 y 80 caracteres',
          value: provider.titulo,
          max: 80,
          invalid: !(provider.titulo.isEmpty || provider.tituloValido),
          onChanged: provider.setTitulo,
        ),
        const SizedBox(height: 12),
        _CounterField(
          label: 'Contenido',
          icon: Icons.description_outlined,
          helper: 'Mínimo 20 caracteres',
          value: provider.contenido,
          max: 2000,
          min: 20,
          multiline: true,
          invalid: !(provider.contenido.isEmpty || provider.contenidoValido),
          onChanged: provider.setContenido,
        ),
        const SizedBox(height: 12),
        _EtiquetasChips(),
      ],
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Datos y Multimedia',
      icon: Icons.tune_outlined,
      children: [
        _CategoriaDropdown(),
        const SizedBox(height: 12),
        const UbicacionSelector(),
        const SizedBox(height: 12),
        const MediaPickerRow(),
        const SizedBox(height: 12),
        const _MediaLivePreview(),
      ],
    );
  }
}

class _CounterField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? helper;
  final String value;
  final int max;
  final int? min;
  final bool multiline;
  final bool invalid;
  final ValueChanged<String> onChanged;

  const _CounterField({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.invalid,
    required this.onChanged,
    this.helper,
    this.min,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final int len = value.length;
    final bool belowMin = min != null && len < min! && len > 0;
    final Color countColor = belowMin || invalid ? AppColors.error : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            helperText: helper,
            errorText: invalid ? 'Revisa este campo' : null,
          ),
          initialValue: value,
          onChanged: onChanged,
          maxLines: multiline ? 6 : 1,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${min != null ? '$len/$min mín · ' : ''}$len/$max',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: countColor),
          ),
        ),
      ],
    );
  }
}

class _MediaLivePreview extends StatelessWidget {
  const _MediaLivePreview();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    if (provider.uploads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.perm_media_outlined, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text('Sin multimedia seleccionada', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.uploads.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final u = provider.uploads[i];
          final Color border = u.status == UploadStatus.done
              ? AppColors.success
              : (u.status == UploadStatus.uploading ? AppColors.primary : AppColors.textSecondary);
          return Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border.withOpacity(0.5)),
              boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(u.tipo == TipoMultimedia.imagen ? Icons.image_outlined : Icons.graphic_eq, size: 16, color: border),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        u.tipo == TipoMultimedia.imagen ? 'Imagen' : 'Audio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ),
                    if (u.status == UploadStatus.uploading)
                      Text('${u.progress.toInt()}%', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: () {
                      // Previsualización rica por tipo de multimedia
                      if (u.tipo == TipoMultimedia.imagen) {
                        if ((u.url != null) && u.url!.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              u.url!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        if (u.bytes != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              u.bytes!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        if (u.file != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              u.file!,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return const Icon(Icons.image, color: AppColors.textSecondary);
                      }
                      if (u.tipo == TipoMultimedia.audio) {
                        if (u.status == UploadStatus.done && (u.url != null) && u.url!.isNotEmpty) {
                          return _AudioPreviewMini(url: u.url!);
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.graphic_eq, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text('Audio'),
                          ],
                        );
                      }
                      // Placeholder para otros tipos (video, etc.)
                      return Stack(
                        children: [
                          Container(color: AppColors.surfaceVariant),
                          const Positioned.fill(
                            child: Center(
                              child: Icon(Icons.play_circle_fill, size: 40, color: AppColors.textSecondary),
                            ),
                          )
                        ],
                      );
                    }(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (u.status == UploadStatus.error)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Reintentar',
                        onPressed: () => context.read<RelatoFormProvider>().retryUpload(u.id),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Eliminar',
                      onPressed: () => context.read<RelatoFormProvider>().eliminarMedia(u.id),
                    ),
                    const Spacer(),
                    if (u.status == UploadStatus.uploading)
                      IconButton(
                        icon: const Icon(Icons.cancel, size: 18),
                        tooltip: 'Cancelar',
                        onPressed: () => context.read<RelatoFormProvider>().cancelUpload(u.id),
                      ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AudioPreviewMini extends StatefulWidget {
  final String url;
  const _AudioPreviewMini({required this.url});

  @override
  State<_AudioPreviewMini> createState() => _AudioPreviewMiniState();
}

class _AudioPreviewMiniState extends State<_AudioPreviewMini> {
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
        setState(() => _position = pos);
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
    if (_loading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              icon: StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snap) {
                  final playing = _player.playing;
                  return Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 28);
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
            Expanded(
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
              ),
            ),
            Text('${_fmt(_position)} / ${_fmt(_duration)}', style: AppTypography.metadata.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }
}
