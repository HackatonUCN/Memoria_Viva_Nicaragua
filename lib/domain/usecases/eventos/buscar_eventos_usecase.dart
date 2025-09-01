import '../../entities/evento_cultural.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../failures/result.dart';
import '../../failures/failures.dart';
import '../../failures/exception_mapper.dart';

/// Caso de uso para buscar eventos culturales
class BuscarEventosUseCase {
  final IEventoCulturalRepository _eventoRepository;

  BuscarEventosUseCase(this._eventoRepository);

  /// Busca eventos por texto en nombre, descripción, organizador
  /// 
  /// [texto] - Texto a buscar
  /// 
  /// Throws:
  /// - [EventoException] si hay algún error durante la búsqueda
  UseCaseResult<List<EventoCultural>> execute(String texto) async {
    try {
      if (texto.trim().isEmpty) {
        return const Success<List<EventoCultural>, Failure>(<EventoCultural>[]);
      }
      final data = await _eventoRepository.buscarEventos(texto);
      return Success<List<EventoCultural>, Failure>(data);
    } catch (e) {
      return FailureResult<List<EventoCultural>, Failure>(mapExceptionToFailure(e));
    }
  }

  /// Busca eventos cercanos a una ubicación
  /// 
  /// [latitud], [longitud] - Coordenadas de la ubicación
  /// [radioKm] - Radio de búsqueda en kilómetros
  /// 
  /// Throws:
  /// - [EventoLocationException] si hay un error con las coordenadas
  /// - [EventoException] si hay algún otro error
  UseCaseResult<List<EventoCultural>> buscarCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
  }) async {
    try {
      if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
        throw EventoLocationException.coordenadasInvalidas();
      }
      
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
}
