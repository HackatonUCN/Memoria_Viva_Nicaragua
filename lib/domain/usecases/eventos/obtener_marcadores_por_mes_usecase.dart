import '../../entities/evento_cultural.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso: obtener conteos de eventos por día para un rango mensual
/// Retorna un mapa DateTime (solo fecha) -> count.
class ObtenerMarcadoresPorMesUseCase {
  final IEventoCulturalRepository _eventoRepository;

  ObtenerMarcadoresPorMesUseCase(this._eventoRepository);

  UseCaseResult<Map<DateTime, int>> execute({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    try {
      final List<EventoCultural> enRango = await _eventoRepository.obtenerEventosPorRangoFecha(
        inicio: inicio,
        fin: fin,
      );

      final Map<DateTime, int> counts = <DateTime, int>{};
      for (final e in enRango.where((e) => !e.eliminado)) {
        // Para cada día entre fechaInicio y fechaFin del evento, contar uno
        DateTime cursor = DateTime(e.fechaInicio.year, e.fechaInicio.month, e.fechaInicio.day);
        final DateTime endDayExclusive = DateTime(e.fechaFin.year, e.fechaFin.month, e.fechaFin.day).add(const Duration(days: 1));
        while (cursor.isBefore(endDayExclusive)) {
          if (!cursor.isBefore(inicio) && cursor.isBefore(fin)) {
            counts.update(cursor, (v) => v + 1, ifAbsent: () => 1);
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }

      return Success<Map<DateTime, int>, Failure>(counts);
    } catch (e) {
      return FailureResult<Map<DateTime, int>, Failure>(mapExceptionToFailure(e));
    }
  }
}


