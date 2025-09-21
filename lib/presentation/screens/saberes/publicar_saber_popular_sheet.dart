import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/validators/contenido_validator.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../providers/saberes/saber_form_provider.dart';
import '../../../domain/enums/departamentos.dart';
import '../../screens/mapa/map_picker_screen.dart';

class PublicarSaberPopularSheet extends StatelessWidget {
  const PublicarSaberPopularSheet({super.key});

  static Future<SaberPopular?> open(BuildContext context, {SaberPopular? initialSaber}) async {
    final result = await showModalBottomSheet<SaberPopular?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      useRootNavigator: false,
      builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => SaberFormProvider()
            ..init()
            ..loadSaberForEditIfNeeded(initialSaber),
          child: const _SheetScaffold(),
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaberFormProvider>();
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
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(provider.isEditing ? 'Editar saber popular' : 'Publicar saber popular',
                        style: AppTypography.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: provider.isPublishing
                          ? null
                          : () {
                              Navigator.of(context).maybePop();
                            },
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textLight,
                      ),
                      onPressed: provider.formularioValido && !provider.isPublishing
                          ? () async {
                              final ok = await context.read<SaberFormProvider>().publicar();
                              if (!context.mounted) return;
                              if (ok) {
                                final offline = context.read<SaberFormProvider>().lastPublishOffline;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: offline ? AppColors.warning : AppColors.success,
                                    content: Text(
                                      offline
                                          ? 'Sin conexión: tu saber se publicará cuando vuelvas a estar en línea'
                                          : (provider.isEditing ? 'Cambios guardados' : 'Saber publicado con éxito'),
                                    ),
                                  ),
                                );
                                SaberPopular? salida;
                                if (provider.isEditing) {
                                  salida = provider.saberEditadoMinimo();
                                } else {
                                  salida = provider.lastCreatedSaber ?? provider.saberConstruidoMinimo();
                                }
                                final nav = Navigator.of(context);
                                WidgetsBinding.instance.addPostFrameCallback((_) async {
                                  if (nav.canPop()) nav.pop(salida);
                                });
                              } else {
                                final err = context.read<SaberFormProvider>().errorMessage;
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: AppColors.error, content: Text(err)),
                                  );
                                }
                              }
                            }
                          : null,
                      child: provider.isPublishing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(provider.isEditing ? 'Guardar cambios' : 'Publicar'),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body responsive
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
        ),
      ),
    );
  }
}

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaberFormProvider>();
    if (provider.categoriasLoading) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('Categoría'),
        subtitle: LinearProgressIndicator(),
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
    final provider = context.watch<SaberFormProvider>();
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
                child: Icon(icon, color: Colors.white, size: 18),
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
    final provider = context.watch<SaberFormProvider>();
    return _SectionCard(
      title: 'Contenido del Saber',
      icon: Icons.edit_outlined,
      children: [
        _CounterField(
          label: 'Título',
          icon: Icons.title_outlined,
          helper: 'Entre 5 y 100 caracteres',
          value: provider.titulo,
          max: ContenidoValidator.MAX_TITULO_LENGTH,
          min: ContenidoValidator.MIN_TITULO_LENGTH,
          invalid: !(provider.titulo.isEmpty || provider.tituloValido),
          onChanged: provider.setTitulo,
        ),
        const SizedBox(height: 12),
        _CounterField(
          label: 'Descripción',
          icon: Icons.description_outlined,
          helper: 'Entre 20 y 5000 caracteres',
          value: provider.contenido,
          max: ContenidoValidator.MAX_DESCRIPCION_LENGTH,
          min: ContenidoValidator.MIN_DESCRIPCION_LENGTH,
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
      children: const [
        _CategoriaDropdown(),
        SizedBox(height: 12),
        _UbicacionSelector(),
        SizedBox(height: 12),
        _SaberMediaPickerRow(),
        SizedBox(height: 12),
        _MediaLivePreview(),
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

class _SaberMediaPickerRow extends StatelessWidget {
  const _SaberMediaPickerRow();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaberFormProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Multimedia', style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionButton(icon: Icons.photo_outlined, label: 'Galería', onTap: provider.addImagenDesdeGaleria),
            _ActionButton(icon: Icons.photo_camera_outlined, label: 'Cámara', onTap: provider.addImagenDesdeCamara),
            _ActionButton(icon: Icons.attach_file_outlined, label: 'Archivos', onTap: provider.addDesdeArchivos),
            _ActionButton(
              icon: provider.grabando ? Icons.stop_circle_outlined : Icons.mic_none_outlined,
              label: provider.grabando ? 'Detener' : 'Grabar audio',
              onTap: provider.grabando ? provider.detenerGrabacionAudio : provider.iniciarGrabacionAudio,
            ),
          ],
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
    return ElevatedButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(label));
  }
}

class _MediaLivePreview extends StatelessWidget {
  const _MediaLivePreview();
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SaberFormProvider>();
    if (provider.uploads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.perm_media_outlined, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text('Sin multimedia seleccionada', style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        ]),
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
          final Color border = u.status == SaberUploadStatus.done
              ? AppColors.success
              : (u.status == SaberUploadStatus.uploading ? AppColors.primary : AppColors.textSecondary);
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
                          : (u.tipo == TipoMultimedia.video
                              ? Icons.videocam_outlined
                              : (u.tipo == TipoMultimedia.audio ? Icons.graphic_eq : Icons.insert_drive_file_outlined)),
                      size: 16,
                      color: border,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        u.tipo == TipoMultimedia.imagen
                            ? 'Imagen'
                            : (u.tipo == TipoMultimedia.video
                                ? 'Video'
                                : (u.tipo == TipoMultimedia.audio ? 'Audio' : 'Documento')),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.bodySmall,
                      ),
                    ),
                    if (u.status == SaberUploadStatus.uploading)
                      Text('${u.progress.toInt()}%', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                    child: () {
                      if (u.tipo == TipoMultimedia.imagen) {
                        if ((u.url != null) && u.url!.isNotEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(u.url!, fit: BoxFit.cover),
                          );
                        }
                        if (u.bytes != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(u.bytes!, fit: BoxFit.cover),
                          );
                        }
                        if (u.file != null) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(u.file!, fit: BoxFit.cover),
                          );
                        }
                        return const Icon(Icons.image, color: AppColors.textSecondary);
                      }
                      if (u.tipo == TipoMultimedia.audio) {
                        if (u.status == SaberUploadStatus.done && (u.url != null) && u.url!.isNotEmpty) {
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
                        return Stack(children: const [
                          Positioned.fill(child: Center(child: Icon(Icons.play_circle_fill, size: 40, color: AppColors.textSecondary)))
                        ]);
                      }
                      // Documento
                      return Center(
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.insert_drive_file_outlined, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              u.displayName ?? 'Documento',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                      );
                    }(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  if (u.status == SaberUploadStatus.error)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: 'Reintentar',
                      onPressed: () => context.read<SaberFormProvider>().retryUpload(u.id),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Eliminar',
                    onPressed: () => context.read<SaberFormProvider>().eliminarMedia(u.id),
                  ),
                  const Spacer(),
                  if (u.status == SaberUploadStatus.uploading)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 18),
                      tooltip: 'Cancelar',
                      onPressed: () => context.read<SaberFormProvider>().cancelUpload(u.id),
                    ),
                ])
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
      _player.positionStream.listen((pos) { if (mounted) setState(() => _position = pos); });
      _player.durationStream.listen((d) { if (d != null && mounted) setState(() => _duration = d); });
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
        Row(children: [
          IconButton(
            icon: StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snap) {
                final playing = _player.playing;
                return Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, size: 28);
              },
            ),
            onPressed: () async {
              if (_player.playing) { await _player.pause(); } else { await _player.play(); }
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
        ])
      ],
    );
  }
}

class _UbicacionSelector extends StatelessWidget {
  const _UbicacionSelector();
  @override
  Widget build(BuildContext context) {
    // Reuse layout from relatos selector but wire to SaberFormProvider
    final provider = context.watch<SaberFormProvider>();
    final hasLocation = provider.departamento != null && provider.municipio != null;
    final subtitle = hasLocation
        ? '${provider.departamento} / ${provider.municipio}\n(${provider.latitud?.toStringAsFixed(5)}, ${provider.longitud?.toStringAsFixed(5)})'
        : 'Usaremos tu ubicación actual al publicar (si falla, se publicará sin ubicación)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.place_outlined, color: AppColors.primaryDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ubicación', style: AppTypography.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ]),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await Navigator.of(context).push<MapPickerResult>(
                  MaterialPageRoute(builder: (_) => const MapPickerScreen()),
                );
                if (picked != null) {
                  context.read<SaberFormProvider>().setUbicacion(
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
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.departamento,
                decoration: InputDecoration(
                  labelText: 'Departamento',
                  prefixIcon: const Icon(Icons.place_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                isExpanded: true,
                items: Departamento.values
                    .map((d) => DropdownMenuItem<String>(
                          value: d.nombre,
                          child: Text(d.nombre, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: context.read<SaberFormProvider>().setDepartamento,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: provider.municipio,
                decoration: InputDecoration(
                  labelText: 'Municipio',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
                isExpanded: true,
                items: () {
                  final depKey = (provider.departamento ?? '').toLowerCase();
                  final munis = municipiosPorDepartamento[depKey] ?? const <String>[];
                  return munis
                      .map((m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          ))
                      .toList();
                }(),
                onChanged: context.read<SaberFormProvider>().setMunicipio,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
