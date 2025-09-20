import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/factories/usecases.dart';
import '../../../domain/enums/tipos_evento.dart';
import '../../../domain/enums/tipos_contenido.dart';
import '../../../domain/enums/departamentos.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../../data/datasources/impl/cloudinary_storage_datasource_impl.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../domain/services/i_geolocation_service.dart';
import '../../../utils/nicaragua_coordinates.dart';
import '../mapa/map_picker_screen.dart';

class EventoFormResult {
  final bool success;
  final String? errorMessage;
  const EventoFormResult.success() : success = true, errorMessage = null;
  const EventoFormResult.error(this.errorMessage) : success = false;
}

class EventoFormSheet extends StatelessWidget {
  const EventoFormSheet({super.key});

  static Future<EventoFormResult?> open(BuildContext context, {bool publicarDirecto = false, dynamic initial}) async {
    final res = await showModalBottomSheet<EventoFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.2),
      useRootNavigator: false,
      builder: (ctx) {
        return ChangeNotifierProvider(
          create: (_) => EventoFormProvider()..init(initial: initial),
          child: WillPopScope(
            onWillPop: () async => true,
            child: _FadeIn(child: _SheetScaffold(publicarDirecto: publicarDirecto, initial: initial)),
          ),
        );
      },
    );
    return res;
  }

  @override
  Widget build(BuildContext context) {
    // Este widget se usa a través del método estático open().
    // Retornar un placeholder evita errores si se llegara a insertar en el árbol.
    return const SizedBox.shrink();
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

class _SheetScaffold extends StatelessWidget {
  final bool publicarDirecto;
  final dynamic initial;

  const _SheetScaffold({required this.publicarDirecto, this.initial});

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
        child: _Content(publicarDirecto: publicarDirecto, initial: initial),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final bool publicarDirecto;
  final dynamic initial;

  const _Content({required this.publicarDirecto, this.initial});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
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
                        initial == null
                            ? (publicarDirecto ? 'Publicar Evento' : 'Sugerir Evento')
                            : 'Editar Evento',
                        style: AppTypography.textTheme.headlineSmall?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        initial == null
                            ? (publicarDirecto ? 'Comparte un evento cultural con todos' : 'Propón un evento para revisar')
                            : 'Actualiza la información del evento',
                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textLight.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
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
                    child: const Column(
                      children: [
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
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

          // Footer con botón de acción
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: provider.canSubmit ? () => _handleSubmit(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textLight,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                    ),
                    icon: provider.isSaving
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                        : Icon(
                      initial == null
                          ? (publicarDirecto ? Icons.event_available_rounded : Icons.send_rounded)
                          : Icons.save_rounded,
                    ),
                    label: Text(
                      initial == null
                          ? (publicarDirecto ? 'Publicar Evento' : 'Enviar Sugerencia')
                          : 'Guardar Cambios',
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
    final provider = context.read<EventoFormProvider>();
    final result = await provider.submitForm(publicarDirecto: publicarDirecto, initial: initial);
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }
}

class _ContentSection extends StatelessWidget {
  const _ContentSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();
    return _SectionCard(
      title: 'Información del Evento',
      icon: Icons.event_outlined,
      children: [
        _CounterField(
          label: 'Título del evento',
          icon: Icons.title_outlined,
          helper: 'Entre 3 y 80 caracteres',
          value: provider.titulo,
          max: 80,
          invalid: !(provider.titulo.isEmpty || provider.tituloValido),
          onChanged: provider.setTitulo,
        ),
        const SizedBox(height: 12),
        _CounterField(
          label: 'Descripción',
          icon: Icons.description_outlined,
          helper: 'Mínimo 10 caracteres',
          value: provider.descripcion,
          max: 1000,
          min: 10,
          multiline: true,
          invalid: !(provider.descripcion.isEmpty || provider.descripcionValida),
          onChanged: provider.setDescripcion,
        ),
        const SizedBox(height: 12),
        _CounterField(
          label: 'Organizador',
          icon: Icons.people_alt_outlined,
          helper: 'Nombre del organizador o institución',
          value: provider.organizador,
          max: 100,
          invalid: !(provider.organizador.isEmpty || provider.organizadorValido),
          onChanged: provider.setOrganizador,
        ),
      ],
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Detalles y Multimedia',
      icon: Icons.tune_outlined,
      children: [
        const _CategoriaDropdown(),
        const SizedBox(height: 12),
        const _UbicacionSelector(),
        const SizedBox(height: 12),
        const _FechasSelector(),
        const SizedBox(height: 12),
        const _RecurrenciaSection(),
        const SizedBox(height: 12),
        const _MediaPickerSection(),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

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

class _CategoriaDropdown extends StatelessWidget {
  const _CategoriaDropdown();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();

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

class _UbicacionSelector extends StatelessWidget {
  const _UbicacionSelector();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();
    final hasLocation = provider.departamento != null && provider.municipio != null;
    final hasCoordinates = provider.latitud != null && provider.longitud != null;
    
    String subtitle = 'Selecciona la ubicación del evento';
    if (hasLocation) {
      subtitle = '${provider.departamento} / ${provider.municipio}';
      if (hasCoordinates) {
        subtitle += '\n(${provider.latitud?.toStringAsFixed(5)}, ${provider.longitud?.toStringAsFixed(5)})';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información de ubicación con botón de mapa
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasLocation ? Icons.place : Icons.place_outlined, 
                color: hasLocation ? AppColors.primaryDark : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación', 
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle, 
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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
                    provider.setUbicacion(
                      dep: picked.departamento,
                      mun: picked.municipio,
                      lat: picked.latitud,
                      lng: picked.longitud,
                    );
                  }
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Ubicar en el mapa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  side: BorderSide(color: AppColors.primaryDark.withOpacity(0.3)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Divisor con "O" en el medio
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'O',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        // Selectores tradicionales
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
                  child: Text(
                    d.nombre,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: provider.setDepartamento,
                validator: (_) => provider.departamentoValido ? null : 'Selecciona un departamento',
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
                items: provider.municipiosDisponibles
                    .map((m) => DropdownMenuItem<String>(
                  value: m,
                  child: Text(
                    m,
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: (provider.departamento == null || 
                           provider.departamento!.isEmpty ||
                           provider.departamento == 'Nacional')
                    ? null
                    : provider.setMunicipio,
                validator: (_) => provider.municipioValido ? null : 'Selecciona un municipio',
                hint: (provider.departamento == null || provider.departamento!.isEmpty)
                    ? const Text('Selecciona un departamento primero')
                    : provider.departamento == 'Nacional'
                        ? const Text('Evento nacional - Nicaragua')
                        : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FechasSelector extends StatelessWidget {
  const _FechasSelector();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de inicio',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: Text(
                    '${provider.fechaInicio.day.toString().padLeft(2,'0')}/${provider.fechaInicio.month.toString().padLeft(2,'0')}/${provider.fechaInicio.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de fin',
                    prefixIcon: const Icon(Icons.event_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: Text(
                    '${provider.fechaFin.day.toString().padLeft(2,'0')}/${provider.fechaFin.month.toString().padLeft(2,'0')}/${provider.fechaFin.year}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final provider = context.read<EventoFormProvider>();
    final initialDate = isStart ? provider.fechaInicio : provider.fechaFin;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      if (isStart) {
        provider.setFechaInicio(date);
      } else {
        provider.setFechaFin(date);
      }
    }
  }
}

class _RecurrenciaSection extends StatelessWidget {
  const _RecurrenciaSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();
    const List<String> opciones = ['Ninguna', 'Semanal', 'Mensual', 'Anual', 'Cada 15 días'];
    
    return DropdownButtonFormField<String>(
      value: provider.frecuencia ?? 'Ninguna',
      decoration: InputDecoration(
        labelText: 'Frecuencia del evento',
        prefixIcon: const Icon(Icons.repeat_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        helperText: 'Selecciona si el evento se repite periódicamente',
      ),
      isExpanded: true,
      items: opciones
          .map((f) => DropdownMenuItem(
            value: f,
            child: Row(
              children: [
                Icon(
                  f == 'Ninguna' ? Icons.event_outlined : Icons.repeat,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  f == 'Ninguna' ? 'Evento único (no se repite)' : f,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ))
          .toList(),
      onChanged: (value) {
        if (value == 'Ninguna') {
          provider.setEsRecurrente(false);
          provider.setFrecuencia(null);
        } else {
          provider.setEsRecurrente(true);
          provider.setFrecuencia(value?.toLowerCase());
        }
      },
    );
  }
}

class _MediaPickerSection extends StatelessWidget {
  const _MediaPickerSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes', style: AppTypography.textTheme.titleMedium),
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
              icon: Icons.attach_file_outlined,
              label: 'Archivos',
              onTap: provider.addDesdeArchivos,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.uploads.isNotEmpty) const _MediaLivePreviewEventos(),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}

class _ImageChip extends StatelessWidget {
  final int index;
  final VoidCallback onDelete;

  const _ImageChip({
    required this.index,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('Imagen ${index + 1}'),
      avatar: const Icon(Icons.image_outlined, size: 16),
      onDeleted: onDelete,
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }
}

// ---- Subida y previsualización de imágenes para Eventos ----
enum UploadStatus { queued, uploading, done, error, cancelled }

class MediaUploadItem {
  final String id;
  final File? file;
  final Uint8List? bytes; // Web
  String? url;
  UploadStatus status;
  double progress; // 0..100
  String? error;

  MediaUploadItem({
    required this.id,
    this.file,
    this.bytes,
    this.url,
    this.status = UploadStatus.queued,
    this.progress = 0,
    this.error,
  });
}

class _MediaLivePreviewEventos extends StatelessWidget {
  const _MediaLivePreviewEventos();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventoFormProvider>();
    final items = provider.uploads;
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileSize = constraints.maxWidth >= 480 ? 140 : 110;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final u in items)
              SizedBox(
                width: tileSize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: () {
                                if (u.url != null && u.url!.isNotEmpty) {
                                  return Image.network(u.url!, fit: BoxFit.cover);
                                }
                                if (u.bytes != null) {
                                  return Image.memory(u.bytes!, fit: BoxFit.cover);
                                }
                                if (u.file != null) {
                                  return Image.file(u.file!, fit: BoxFit.cover);
                                }
                                return Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Center(child: Icon(Icons.image, color: AppColors.textSecondary)),
                                );
                              }(),
                            ),
                          ),
                          if (u.status == UploadStatus.uploading)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LinearProgressIndicator(
                                value: (u.progress.clamp(0, 100)) / 100,
                                minHeight: 4,
                              ),
                            ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Row(
                              children: [
                                if (u.status == UploadStatus.error)
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => context.read<EventoFormProvider>().retryUpload(u.id),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => context.read<EventoFormProvider>().eliminarMedia(u.id),
                                ),
                              ],
                            ),
                          ),
                          if (u.status == UploadStatus.uploading)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: IconButton(
                                icon: const Icon(Icons.cancel, size: 18, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => context.read<EventoFormProvider>().cancelUpload(u.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      () {
                        switch (u.status) {
                          case UploadStatus.queued:
                            return 'En cola';
                          case UploadStatus.uploading:
                            return 'Subiendo ${(u.progress).toStringAsFixed(0)}%';
                          case UploadStatus.done:
                            return 'Lista';
                          case UploadStatus.error:
                            return 'Error';
                          case UploadStatus.cancelled:
                            return 'Cancelada';
                        }
                      }(),
                      style: AppTypography.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
// Provider para manejar el formulario de eventos
class EventoFormProvider extends ChangeNotifier {
  // Campos del formulario
  String titulo = '';
  String descripcion = '';
  String organizador = '';
  String? categoriaId;
  String? departamento;
  String? municipio;
  DateTime fechaInicio = DateTime.now().add(const Duration(days: 1));
  DateTime fechaFin = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool esRecurrente = false;
  String? frecuencia;
  double? latitud;
  double? longitud;
  // Subidas en curso/terminadas
  final List<MediaUploadItem> uploads = [];
  bool get hasPendingUploads => uploads.any((u) => u.status == UploadStatus.queued || u.status == UploadStatus.uploading);

  // Categorías
  List<Categoria> categorias = [];
  bool categoriasLoading = false;
  String? categoriasError;
  // Cache en memoria compartida (similar a RelatoFormProvider)
  static List<Categoria> _memCacheCategorias = [];
  static DateTime? _memCacheAt;
  static const Duration _memCacheTtl = Duration(minutes: 10);
  static void seedCategoriasCache(List<Categoria> cats) {
    _memCacheCategorias = List.of(cats);
    _memCacheAt = DateTime.now();
  }

  // Estado
  bool isSaving = false;
  bool get canSubmit => !isSaving && _validateForm() && !hasPendingUploads;

  // Validaciones
  bool get tituloValido => titulo.trim().length >= 3;
  bool get descripcionValida => descripcion.trim().length >= 10;
  bool get organizadorValido => organizador.trim().isNotEmpty;
  bool get categoriaValida => categoriaId != null && categoriaId!.isNotEmpty;
  bool get departamentoValido => departamento != null && departamento!.isNotEmpty;
  bool get municipioValido => municipio != null && municipio!.isNotEmpty;
  bool get frecuenciaValida => true; // Siempre válida ahora que "Ninguna" es la opción por defecto

  List<String> get municipiosDisponibles {
    final d = departamento?.trim();
    if (d == null || d.isEmpty) return [];
    final key = d.toLowerCase();
    final list = municipiosPorDepartamento[key] ?? [];
    // Agregar opción nacional
    if (list.contains('Nicaragua')) return list;
    return [...list, 'Nicaragua'];
  }

  Future<void> init({dynamic initial}) async {
    if (initial != null) {
      titulo = initial.titulo;
      descripcion = initial.descripcion;
      organizador = initial.organizador;
      categoriaId = initial.categoriaId;
      departamento = initial.ubicacion.departamento;
      municipio = initial.ubicacion.municipio;
      fechaInicio = initial.fechaInicio;
      fechaFin = initial.fechaFin;
      esRecurrente = initial.esRecurrente;
      // Convertir la frecuencia existente al nuevo formato
      if (initial.esRecurrente && initial.frecuencia != null) {
        switch (initial.frecuencia.toLowerCase()) {
          case 'semanal':
            frecuencia = 'Semanal';
            break;
          case 'mensual':
            frecuencia = 'Mensual';
            break;
          case 'anual':
            frecuencia = 'Anual';
            break;
          case 'cada 15 días':
            frecuencia = 'Cada 15 días';
            break;
          default:
            frecuencia = initial.frecuencia;
        }
      } else {
        frecuencia = null; // Será mostrado como "Ninguna" en el dropdown
      }
      latitud = initial.ubicacion.latitud;
      longitud = initial.ubicacion.longitud;
    } else {
      // Para eventos nuevos, configurar coordenadas iniciales si ya hay departamento/municipio
      if (departamento != null && departamento!.isNotEmpty) {
        _updateCoordinatesFromLocation();
      }
    }

    await _initCategoriasWithCache();
  }

  Future<void> _loadCategorias() async {
    categoriasLoading = true;
    categoriasError = null;
    notifyListeners();

    try {
      final uc = GetIt.I<ObtenerCategoriasPorTipoUseCase>();
      final result = await uc.execute(TipoContenido.evento);
      result.when(
        success: (cats) {
          categorias = cats.where((c) => c.activa).toList();
          categoriasError = null;
        },
        failure: (f) {
          categoriasError = f.message;
        },
      );
    } catch (e) {
      categoriasError = 'Error al cargar categorías';
    }

    categoriasLoading = false;
    notifyListeners();
  }

  Future<void> _initCategoriasWithCache() async {
    categoriasLoading = true;
    categoriasError = null;
    notifyListeners();

    final bool cacheFresh = _memCacheCategorias.isNotEmpty && (_memCacheAt != null) && DateTime.now().difference(_memCacheAt!) < _memCacheTtl;
    if (cacheFresh) {
      categorias = List.of(_memCacheCategorias);
      categoriasLoading = false;
      notifyListeners();
      // Refresh en background sin bloquear la UI
      // ignore: discarded_futures
      _refreshCategorias();
      return;
    }
    await _refreshCategorias();
  }

  Future<void> _refreshCategorias() async {
    try {
      final uc = GetIt.I<ObtenerCategoriasPorTipoUseCase>();
      final res = await uc.execute(TipoContenido.evento).timeout(const Duration(seconds: 8));
      final data = res.valueOrNull ?? _memCacheCategorias;
      categorias = List.of(data)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      _memCacheCategorias = List.of(categorias);
      _memCacheAt = DateTime.now();
      _catsSub?.cancel();
      _catsSub = uc.observe(TipoContenido.evento).listen((list) {
        categorias = List.of(list)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _memCacheCategorias = List.of(categorias);
        _memCacheAt = DateTime.now();
        notifyListeners();
      });
      categoriasLoading = false;
      categoriasError = null;
      notifyListeners();
    } on TimeoutException {
      if (_memCacheCategorias.isNotEmpty) {
        categorias = List.of(_memCacheCategorias);
        categoriasLoading = false;
        categoriasError = null;
        notifyListeners();
      } else {
        categoriasLoading = false;
        categoriasError = 'Tiempo de espera al cargar categorías';
        notifyListeners();
      }
    } catch (e) {
      categoriasError = e.toString();
      categoriasLoading = false;
      notifyListeners();
    }
  }

  void setTitulo(String value) {
    titulo = value;
    notifyListeners();
  }

  void setDescripcion(String value) {
    descripcion = value;
    notifyListeners();
  }

  void setOrganizador(String value) {
    organizador = value;
    notifyListeners();
  }

  void setCategoria(String? value) {
    categoriaId = value;
    notifyListeners();
  }

  void setDepartamento(String? value) {
    if (departamento != value) {
      departamento = value;
      municipio = null; // Reset municipio when department changes
      
      // Si selecciona "Nacional", automáticamente establecer "Nicaragua" como municipio
      if (value == 'Nacional') {
        municipio = 'Nicaragua';
      }
      
      _updateCoordinatesFromLocation();
      notifyListeners();
    }
  }

  void setMunicipio(String? value) {
    municipio = value;
    _updateCoordinatesFromLocation();
    notifyListeners();
  }

  /// Actualiza las coordenadas basándose en el departamento/municipio seleccionado
  void _updateCoordinatesFromLocation() {
    if (departamento != null && departamento!.isNotEmpty) {
      final coords = NicaraguaCoordinates.getBestCoordinates(departamento, municipio);
      latitud = coords['lat'];
      longitud = coords['lng'];
      debugPrint('[EVENTO_FORM][GEOCODING] $departamento/$municipio -> lat: $latitud, lng: $longitud');
    }
  }

  void setUbicacion({
    String? dep,
    String? mun,
    double? lat,
    double? lng,
  }) {
    departamento = dep;
    municipio = mun;
    latitud = lat;
    longitud = lng;
    notifyListeners();
  }

  void setFechaInicio(DateTime date) {
    fechaInicio = date;
    if (fechaFin.isBefore(date)) {
      fechaFin = date.add(const Duration(hours: 2));
    }
    notifyListeners();
  }

  void setFechaFin(DateTime date) {
    fechaFin = date;
    notifyListeners();
  }

  void setEsRecurrente(bool v) {
    esRecurrente = v;
    if (!esRecurrente) frecuencia = null;
    notifyListeners();
  }

  void setFrecuencia(String? v) {
    frecuencia = v;
    notifyListeners();
  }

  Future<void> _ensureLatLng() async {
    if (latitud != null && longitud != null) return;
    
    // Primero intentar obtener coordenadas basadas en la ubicación seleccionada
    if (departamento != null && departamento!.isNotEmpty) {
      _updateCoordinatesFromLocation();
      if (latitud != null && longitud != null) {
        debugPrint('[EVENTO_FORM][ENSURE_COORDS] Usando coordenadas de $departamento/$municipio: $latitud, $longitud');
        notifyListeners();
        return;
      }
    }
    
    // Si no hay ubicación seleccionada, intentar obtener ubicación actual del dispositivo
    if (GetIt.I.isRegistered<IGeolocationService>()) {
      try {
        final geo = GetIt.I<IGeolocationService>();
        final ub = await geo.obtenerUbicacionActual();
        latitud = ub.latitud;
        longitud = ub.longitud;
        debugPrint('[EVENTO_FORM][ENSURE_COORDS] Usando ubicación actual del dispositivo: $latitud, $longitud');
        notifyListeners();
        return;
      } catch (_) {
        debugPrint('[EVENTO_FORM][ENSURE_COORDS] Error obteniendo ubicación del dispositivo');
      }
    }
    
    // Último fallback: coordenadas de Managua
    final coords = NicaraguaCoordinates.getBestCoordinates('Managua', 'Managua');
    latitud = coords['lat'];
    longitud = coords['lng'];
    debugPrint('[EVENTO_FORM][ENSURE_COORDS] Usando fallback a Managua: $latitud, $longitud');
    notifyListeners();
  }

  // Herramientas / internos
  final ImagePicker _picker = ImagePicker();
  String? _currentUserId;
  final Map<String, http.Client> _clientsByUpload = {};
  StreamSubscription<List<Categoria>>? _catsSub;

  Future<void> addImagenDesdeGaleria() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 90);
      if (files.isEmpty) return;
      for (final x in files) {
        _queueUpload(file: File(x.path));
      }
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        ...TipoMultimedia.imagen.extensionesPermitidas,
      ],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      if (kIsWeb) {
        if (f.bytes == null) continue;
        _queueUploadBytes(bytes: f.bytes!);
      } else {
        if (f.path == null) continue;
        _queueUpload(file: File(f.path!));
      }
    }
  }

  Future<void> addDesdeArchivos() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        ...TipoMultimedia.imagen.extensionesPermitidas,
      ],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      if (kIsWeb) {
        if (f.bytes == null) continue;
        _queueUploadBytes(bytes: f.bytes!);
      } else {
        if (f.path == null) continue;
        _queueUpload(file: File(f.path!));
      }
    }
  }

  void eliminarMedia(String id) {
    uploads.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  void cancelUpload(String id) {
    final client = _clientsByUpload.remove(id);
    client?.close();
    final idx = uploads.indexWhere((u) => u.id == id);
    if (idx != -1) {
      uploads[idx].status = UploadStatus.cancelled;
      uploads[idx].progress = 0;
      notifyListeners();
    }
  }

  void retryUpload(String id) {
    final idx = uploads.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    final item = uploads[idx];
    if (item.file == null && item.bytes == null) return;
    item.status = UploadStatus.queued;
    item.progress = 0;
    item.error = null;
    notifyListeners();
    _uploadInBackground(item);
  }

  void _queueUpload({required File file}) {
    final item = MediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      file: file,
      status: UploadStatus.queued,
      progress: 0,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  void _queueUploadBytes({required Uint8List bytes}) {
    final item = MediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      bytes: bytes,
      status: UploadStatus.queued,
      progress: 0,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  Future<void> _uploadInBackground(MediaUploadItem item) async {
    if (_currentUserId == null) {
      final current = await UseCases.resolve().auth.getCurrentUser.execute();
      _currentUserId = current.valueOrNull?.id;
    }
    if (item.file == null && item.bytes == null) return;
    item.status = UploadStatus.uploading;
    item.progress = 5;
    notifyListeners();

    try {
      final client = http.Client();
      _clientsByUpload[item.id] = client;
      final ds = CloudinaryStorageDataSourceImpl(basePath: 'eventos/${_currentUserId ?? 'anon'}', client: client);
      const String contentType = 'image/jpeg';
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (item.progress < 90 && item.status == UploadStatus.uploading) {
          item.progress += 2;
          notifyListeners();
        }
      });

      final String url;
      if (kIsWeb || item.bytes != null) {
        url = await ds.uploadData(
          data: item.bytes ?? await item.file!.readAsBytes(),
          path: fileName,
          contentType: contentType,
        );
      } else {
        url = await ds.uploadFile(
          file: item.file!,
          path: fileName,
          contentType: contentType,
        );
      }
      progressTimer.cancel();

      item.url = url;
      item.progress = 100;
      item.status = UploadStatus.done;
      notifyListeners();
    } catch (e) {
      item.error = e.toString();
      item.status = UploadStatus.error;
      notifyListeners();
    } finally {
      _clientsByUpload.remove(item.id)?.close();
    }
  }

  Future<EventoFormResult> submitForm({required bool publicarDirecto, dynamic initial}) async {
    if (!_validateForm()) {
      debugPrint('[EVENTO_FORM][INVALID] tituloValido=$tituloValido descripcionValida=$descripcionValida organizadorValido=$organizadorValido categoriaValida=$categoriaValida departamentoValido=$departamentoValido municipioValido=$municipioValido frecuenciaValida=$frecuenciaValida');
      return const EventoFormResult.error('Por favor completa todos los campos requeridos');
    }
    if (hasPendingUploads) {
      debugPrint('[EVENTO_FORM][PENDING_UPLOADS] uploads=${uploads.length}');
      return const EventoFormResult.error('Espera a que terminen de subir las imágenes');
    }

    isSaving = true;
    notifyListeners();

    try {
      // Asegurar lat/lng válidas dentro de Nicaragua
      await _ensureLatLng();
      final double? lat = latitud;
      final double? lng = longitud;
      debugPrint('[EVENTO_FORM][START] publicarDirecto=$publicarDirecto edit=${initial != null} tituloLen=${titulo.length} descLen=${descripcion.length} orgLen=${organizador.length} cat=$categoriaId dep=$departamento mun=$municipio fechaInicio=$fechaInicio fechaFin=$fechaFin esRec=$esRecurrente freq=$frecuencia lat=$lat lng=$lng');
      String? error;
      final List<String> imagenesUrls = uploads
          .where((u) => u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      debugPrint('[EVENTO_FORM][MEDIA] imagenesUrls=${imagenesUrls.length}');

      if (initial != null) {
        // Actualizar evento existente (solo admins)
        debugPrint('[EVENTO_FORM][CALL] actualizar');
        final err = await UseCases.resolve().eventos.actualizar.execute(
          adminId: (await UseCases.resolve().auth.getCurrentUser.execute()).valueOrNull?.id ?? '',
          eventoId: initial.id as String,
          nombre: titulo,
          descripcion: descripcion,
          categoriaId: categoriaId,
          tipo: TipoEvento.otro,
          departamento: departamento,
          municipio: municipio,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          organizador: organizador,
          esRecurrente: esRecurrente,
          frecuencia: frecuencia,
          imagenesUrls: imagenesUrls.isNotEmpty ? imagenesUrls : null,
        );
        if (err.isFailure) {
          debugPrint('[EVENTO_FORM][FAIL] actualizar type=${err.errorOrNull?.runtimeType} msg=${err.errorOrNull?.message}');
          error = err.errorOrNull?.message ?? 'Error';
        }
      } else if (publicarDirecto) {
        // Crear evento directamente (solo admins)
        final me = await UseCases.resolve().auth.getCurrentUser.execute();
        final adminId = me.valueOrNull?.id;
        if (adminId == null) {
          error = 'No autorizado';
        } else {
          debugPrint('[EVENTO_FORM][CALL] crear');
          final res = await UseCases.resolve().eventos.crear.execute(
            adminId: adminId,
            nombre: titulo,
            descripcion: descripcion,
            tipo: TipoEvento.otro,
            categoriaId: categoriaId!,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            organizador: organizador,
            departamento: departamento,
            municipio: municipio,
            esRecurrente: esRecurrente,
            frecuencia: frecuencia,
            latitud: lat,
            longitud: lng,
            imagenesUrls: imagenesUrls,
          );
          if (res.isFailure) {
            debugPrint('[EVENTO_FORM][FAIL] crear type=${res.errorOrNull?.runtimeType} msg=${res.errorOrNull?.message}');
            error = res.errorOrNull?.message ?? 'Error';
          }
        }
      } else {
        // Crear sugerencia
        final me = await UseCases.resolve().auth.getCurrentUser.execute();
        final uid = me.valueOrNull?.id;
        if (uid == null) {
          error = 'Inicia sesión para sugerir';
        } else {
          debugPrint('[EVENTO_FORM][CALL] crearSugerencia');
          final res = await UseCases.resolve().eventos.crearSugerencia.execute(
            usuarioId: uid,
            nombre: titulo,
            descripcion: descripcion,
            categoriaId: categoriaId!,
            tipo: TipoEvento.otro,
            departamento: departamento!,
            municipio: municipio!,
            fechaInicio: fechaInicio,
            fechaFin: fechaFin,
            organizador: organizador,
            esRecurrente: esRecurrente,
            frecuencia: frecuencia,
            latitud: lat,
            longitud: lng,
            imagenesUrls: imagenesUrls,
          );
          if (res.isFailure) {
            debugPrint('[EVENTO_FORM][FAIL] crearSugerencia type=${res.errorOrNull?.runtimeType} msg=${res.errorOrNull?.message}');
            error = res.errorOrNull?.message ?? 'Error';
          }
        }
      }

      isSaving = false;
      notifyListeners();

      if (error != null) {
        debugPrint('[EVENTO_FORM][END][ERROR] $error');
        return EventoFormResult.error(error);
      } else {
        debugPrint('[EVENTO_FORM][END][SUCCESS]');
        return const EventoFormResult.success();
      }
    } catch (e) {
      isSaving = false;
      notifyListeners();
      debugPrint('[EVENTO_FORM][EXCEPTION] $e');
      return EventoFormResult.error('Error inesperado: $e');
    }
  }

  bool _validateForm() {
    return tituloValido &&
        descripcionValida &&
        organizadorValido &&
        categoriaValida &&
        departamentoValido &&
        municipioValido &&
        frecuenciaValida;
  }

  @override
  void dispose() {
    _catsSub?.cancel();
    for (final c in _clientsByUpload.values) {
      try { c.close(); } catch (_) {}
    }
    _clientsByUpload.clear();
    super.dispose();
  }
}