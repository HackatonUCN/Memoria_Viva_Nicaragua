import '../../entities/evento_cultural.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso: obtener eventos para el carrusel superior filtrados por categoría
/// dentro de la ventana temporal [hoy - 7, hoy + 7] (incluyendo hoy).
/// Ordena: próximos primero por fecha ascendente y luego pasados por fecha descendente.
class ObtenerEventosCarruselPorCategoriaUseCase {
  final IEventoCulturalRepository _eventoRepository;

  ObtenerEventosCarruselPorCategoriaUseCase(this._eventoRepository);

  UseCaseResult<List<EventoCultural>> execute({String? categoriaId, DateTime? referencia}) async {
    try {
      final DateTime now = referencia ?? DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime start = startOfDay.subtract(const Duration(days: 7));
      final DateTime end = startOfDay.add(const Duration(days: 1)).add(const Duration(days: 7));

      // Traer por rango para reducir volumen y luego aplicar categoría si corresponde
      final List<EventoCultural> enRango = await _eventoRepository.obtenerEventosPorRangoFecha(
        inicio: start,
        fin: end,
      );

      List<EventoCultural> list = enRango.where((e) => !e.eliminado).toList();
      if (categoriaId != null) {
        list = list.where((e) => e.categoriaId == categoriaId).toList();
      }

      final List<EventoCultural> upcoming = list
          .where((e) => e.fechaFin.isAfter(now))
          .toList()
        ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
      final List<EventoCultural> past = list
          .where((e) => e.fechaFin.isBefore(now))
          .toList()
        ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

      return Success<List<EventoCultural>, Failure>([...upcoming, ...past]);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }
}


