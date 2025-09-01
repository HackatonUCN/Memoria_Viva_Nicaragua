import '../../entities/evento_cultural.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../enums/tipos_evento.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para obtener eventos culturales con diferentes filtros
class ObtenerEventosUseCase {
  final IEventoCulturalRepository _eventoRepository;

  ObtenerEventosUseCase(this._eventoRepository);

  /// Obtiene todos los eventos activos
  UseCaseResult<List<EventoCultural>> execute() async {
    try {
      final data = await _eventoRepository.obtenerEventos();
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos por categoría
  UseCaseResult<List<EventoCultural>> porCategoria(String categoriaId) async {
    try {
      final data = await _eventoRepository.obtenerEventosPorCategoria(categoriaId);
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos por tipo
  UseCaseResult<List<EventoCultural>> porTipo(TipoEvento tipo) async {
    try {
      final data = await _eventoRepository.obtenerEventosPorTipo(tipo);
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos por fecha
  UseCaseResult<List<EventoCultural>> porFecha(DateTime fecha) async {
    try {
      final data = await _eventoRepository.obtenerEventosPorFecha(fecha);
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos por rango de fechas
  UseCaseResult<List<EventoCultural>> porRangoFecha({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    try {
      final data = await _eventoRepository.obtenerEventosPorRangoFecha(
        inicio: inicio,
        fin: fin,
      );
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos por ubicación
  UseCaseResult<List<EventoCultural>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      final data = await _eventoRepository.obtenerEventosPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Obtiene eventos cercanos a una ubicación
  UseCaseResult<List<EventoCultural>> cercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    try {
      final data = await _eventoRepository.obtenerEventosCercanos(
        latitud: latitud,
        longitud: longitud,
        radioKm: radioKm,
      );
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Busca eventos por texto
  UseCaseResult<List<EventoCultural>> buscar(String texto) async {
    try {
      final data = await _eventoRepository.buscarEventos(texto);
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Stream para observar cambios en los eventos
  Stream<List<EventoCultural>> observe() {
    return _eventoRepository.observarEventos();
  }

  /// Stream para observar eventos por categoría
  Stream<List<EventoCultural>> observePorCategoria(String categoriaId) {
    return _eventoRepository.observarEventosPorCategoria(categoriaId);
  }
}