import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

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

  static Future<Relato?> open(BuildContext context, {Relato? initialRelato}) async {
    final result = await showModalBottomSheet<Relato?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      useRootNavigator: false,
      builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => RelatoFormProvider()
            ..init()
            ..loadRelatoForEditIfNeeded(initialRelato),
          child: WillPopScope(
            onWillPop: () async {
              // Evita pops reentrantes que disparan !_debugLocked
              return true;
            },
            child: const _SheetScaffold(),
          ),
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
          // Header unificado (como EventoFormSheet)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            decoration: const BoxDecoration(
              gradient: AppColors.nicaraguaGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isEditing ? 'Editar Relato' : 'Publicar Relato',
                        style: AppTypography.textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comparte tus memorias culturales con la comunidad',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 28),
                ),
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
          const Divider(height: 1),
          // Footer de acción
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.formularioValido && !provider.isPublishing ? () => _handleSubmit(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textLight,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: provider.isPublishing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(provider.isEditing ? Icons.save_rounded : Icons.send_rounded),
                    label: Text(
                      provider.isEditing ? 'Guardar cambios' : 'Publicar',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(BuildContext context) async {
    final provider = context.read<RelatoFormProvider>();
    debugPrint('[PUBLICAR_RELATO][PRESS] t=${DateTime.now().toIso8601String()}');
    final ok = await provider.publicar();
    if (!context.mounted) return;
    if (ok) {
      final offline = provider.lastPublishOffline;
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
      Relato? salida;
      if (provider.isEditing) {
        salida = provider.relatoEditadoMinimo();
      } else {
        salida = provider.lastCreatedRelato ?? provider.relatoConstruidoMinimo();
      }
      final nav = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await nav.maybePop(salida);
      });
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.error, content: Text(provider.errorMessage!)),
      );
    }
  }
}

class _CategoriaDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RelatoFormProvider>();
    if (provider.categoriasLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: const [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Cargando categorías...'),
          ],
        ),
      );
    }
    if (provider.categoriasError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error al cargar categorías: ${provider.categoriasError}',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }
    return DropdownButtonFormField<String>(
      value: provider.categoriaId,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
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
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
    this.helper,
    required this.value,
    required this.max,
    this.min,
    this.multiline = false,
    this.invalid = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = value.length;
    final hasError = invalid || (min != null && count > 0 && count < min!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          maxLines: multiline ? 4 : 1,
          minLines: multiline ? 3 : 1,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            helperText: helper,
            errorText: hasError ? (min != null && count > 0 && count < min! ? 'Mínimo $min caracteres' : 'Campo inválido') : null,
            counterText: '$count/$max',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          maxLength: max,
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
                    Icon(
                      u.tipo == TipoMultimedia.imagen
                          ? Icons.image_outlined
                          : (u.tipo == TipoMultimedia.video ? Icons.videocam_outlined : Icons.graphic_eq),
                      size: 16,
                      color: border,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        u.tipo == TipoMultimedia.imagen
                            ? 'Imagen'
                            : (u.tipo == TipoMultimedia.video ? 'Video' : 'Audio'),
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
                      if (u.tipo == TipoMultimedia.video) {
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
                      }
                      return const SizedBox.shrink();
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
                if (mounted) setState(() {});
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
