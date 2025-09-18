import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/enums/tipos_contenido.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../../core/di/service_locator.dart';

class EventCategoryChips extends StatefulWidget {
  final String? selectedCategoryId;
  final void Function(String? categoryId) onChanged;
  final int maxRecent;

  const EventCategoryChips({super.key, this.selectedCategoryId, required this.onChanged, this.maxRecent = 12});

  @override
  State<EventCategoryChips> createState() => _EventCategoryChipsState();
}

class _EventCategoryChipsState extends State<EventCategoryChips> {
  late final ObtenerCategoriasPorTipoUseCase _obtenerCategoriasPorTipo;
  List<Categoria> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _obtenerCategoriasPorTipo = ServiceLocator.get<ObtenerCategoriasPorTipoUseCase>();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Trae solo categorías del tipo eventos usando el caso de uso con timeout
      final res = await _obtenerCategoriasPorTipo.execute(TipoContenido.evento)
          .timeout(const Duration(seconds: 10));
      
      res.when(
        success: (data) {
          _categorias = data.take(widget.maxRecent).toList();
          debugPrint('[EVENT_CATEGORY_CHIPS] Cargadas ${_categorias.length} categorías');
        },
        failure: (f) {
          _error = f.message;
          debugPrint('[EVENT_CATEGORY_CHIPS] Error del UseCase: $_error');
        },
      );
    } catch (e) {
      debugPrint('[EVENT_CATEGORY_CHIPS] Error: $e');
      _error = e.toString();
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (_, __) => Container(width: 96, height: 36, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18))),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: 6,
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Error cargando categorías', style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.error))),
          TextButton(onPressed: _load, child: const Text('Reintentar')),
        ]),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildChip(context, id: null, nombre: 'Todas', color: AppColors.primary, selected: widget.selectedCategoryId == null),
          const SizedBox(width: 8),
          ..._categorias.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(context, id: c.id, nombre: c.nombre, color: AppColors.categoryColor(categoryId: c.id, hex: c.color), selected: widget.selectedCategoryId == c.id),
              )),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String? id, required String nombre, required Color color, required bool selected}) {
    // Estilo simple solicitado: seleccionado -> fondo accent, texto blanco
    // no seleccionado -> fondo blanco, borde primary, texto primary
    return ChoiceChip(
      label: Text(
        nombre,
        style: AppTypography.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.textLight : AppColors.primary,
        ),
      ),
      selected: selected,
      onSelected: (_) => widget.onChanged(id),
      selectedColor: AppColors.accent,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? Colors.transparent : AppColors.primary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}


