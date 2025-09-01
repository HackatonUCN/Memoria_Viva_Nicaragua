import '../../entities/evento_cultural.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';

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
  Future<List<EventoCultural>> execute(String texto) async {
    try {
      if (texto.trim().isEmpty) {
        return [];
      }
      
      return await _eventoRepository.buscarEventos(texto);
    } catch (e) {
      throw EventoException('Error al buscar eventos: $e');
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
  Future<List<EventoCultural>> buscarCercanos({
    required double latitud,
    required double longitud,
    double radioKm = 10,
  }) async {
    try {
      if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
        throw EventoLocationException.coordenadasInvalidas();
      }
      
      return await _eventoRepository.obtenerEventosCercanos(
        latitud: latitud,
        longitud: longitud,
        radioKm: radioKm,
      );
    } catch (e) {
      if (e is EventoLocationException) {
        rethrow;
      }
      throw EventoException('Error al buscar eventos cercanos: $e');
    }
  }
}
