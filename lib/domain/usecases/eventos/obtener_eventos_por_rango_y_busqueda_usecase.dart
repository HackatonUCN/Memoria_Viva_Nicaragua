import '../../entities/evento_cultural.dart';
import 'dart:async';
import '../../repositories/evento_cultural_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso: obtener eventos para la lista aplicando (rango de fecha) AND (texto)
/// La categoría no aplica a esta lista según los criterios de aceptación.
class ObtenerEventosPorRangoYBusquedaUseCase {
  final IEventoCulturalRepository _eventoRepository;
  static final Map<String, UseCaseResult<List<EventoCultural>>> _inFlight = <String, UseCaseResult<List<EventoCultural>>>{};

  ObtenerEventosPorRangoYBusquedaUseCase(this._eventoRepository);

  UseCaseResult<List<EventoCultural>> execute({
    required DateTime inicio,
    required DateTime fin,
    String? texto,
    int? pageSize,
    Object? pageCursor,
    bool preferCache = false,
  }) async {
    try {
      final String q = (texto ?? '').trim().toLowerCase();
      
      // Sin coalescing por ahora para evitar deadlocks
      return await _executeFetch(
        inicio: inicio,
        fin: fin,
        q: q,
      );
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  Future<Result<List<EventoCultural>, Failure>> _executeFetch({required DateTime inicio, required DateTime fin, required String q}) async {
    try {
      final List<EventoCultural> enRango = await _eventoRepository.obtenerEventosPorRangoFecha(
        inicio: inicio,
        fin: fin,
      );
      final bool hasQuery = q.isNotEmpty;
      List<EventoCultural> filtered = enRango.where((e) => !e.eliminado).toList();
      if (hasQuery) {
        String norm(String s) => s
            .toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ü', 'u')
            .replaceAll('ñ', 'n');
        filtered = filtered.where((e) {
          final title = norm(e.titulo);
          final org = norm(e.organizador);
          final depto = norm(e.ubicacion.departamento ?? '');
          final muni = norm(e.ubicacion.municipio ?? '');
          final autor = norm(e.creadoPorNombre);
          return title.contains(q) || org.contains(q) || depto.contains(q) || muni.contains(q) || autor.contains(q);
        }).toList();
      }

      // Orden: próximos primero por fecha de inicio ascendente
      filtered.sort((a, b) {
        final cmp = a.fechaInicio.compareTo(b.fechaInicio);
        if (cmp != 0) return cmp;
        return a.fechaCreacion.compareTo(b.fechaCreacion);
      });

      return Success<List<EventoCultural>, Failure>(filtered);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }
}


