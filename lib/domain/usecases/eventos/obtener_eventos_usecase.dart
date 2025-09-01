import '../../entities/evento_cultural.dart';
import '../../exceptions/evento_exception.dart';
import '../../repositories/evento_cultural_repository.dart';
import '../../enums/tipos_evento.dart';

/// Caso de uso para obtener eventos culturales con diferentes filtros
class ObtenerEventosUseCase {
  final IEventoCulturalRepository _eventoRepository;

  ObtenerEventosUseCase(this._eventoRepository);

  /// Obtiene todos los eventos activos
  Future<List<EventoCultural>> execute() async {
    try {
      return await _eventoRepository.obtenerEventos();
    } catch (e) {
      throw EventoException('Error al obtener eventos: $e');
    }
  }

  /// Obtiene eventos por categoría
  Future<List<EventoCultural>> porCategoria(String categoriaId) async {
    try {
      return await _eventoRepository.obtenerEventosPorCategoria(categoriaId);
    } catch (e) {
      throw EventoException('Error al obtener eventos por categoría: $e');
    }
  }

  /// Obtiene eventos por tipo
  Future<List<EventoCultural>> porTipo(TipoEvento tipo) async {
    try {
      return await _eventoRepository.obtenerEventosPorTipo(tipo);
    } catch (e) {
      throw EventoException('Error al obtener eventos por tipo: $e');
    }
  }

  /// Obtiene eventos por fecha
  Future<List<EventoCultural>> porFecha(DateTime fecha) async {
    try {
      return await _eventoRepository.obtenerEventosPorFecha(fecha);
    } catch (e) {
      throw EventoException('Error al obtener eventos por fecha: $e');
    }
  }

  /// Obtiene eventos por rango de fechas
  Future<List<EventoCultural>> porRangoFecha({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    try {
      return await _eventoRepository.obtenerEventosPorRangoFecha(
        inicio: inicio,
        fin: fin,
      );
    } catch (e) {
      throw EventoException('Error al obtener eventos por rango de fechas: $e');
    }
  }

  /// Obtiene eventos por ubicación
  Future<List<EventoCultural>> porUbicacion({
    String? departamento,
    String? municipio,
  }) async {
    try {
      return await _eventoRepository.obtenerEventosPorUbicacion(
        departamento: departamento,
        municipio: municipio,
      );
    } catch (e) {
      throw EventoException('Error al obtener eventos por ubicación: $e');
    }
  }

  /// Obtiene eventos cercanos a una ubicación
  Future<List<EventoCultural>> cercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    try {
      return await _eventoRepository.obtenerEventosCercanos(
        latitud: latitud,
        longitud: longitud,
        radioKm: radioKm,
      );
    } catch (e) {
      throw EventoException('Error al obtener eventos cercanos: $e');
    }
  }

  /// Busca eventos por texto
  Future<List<EventoCultural>> buscar(String texto) async {
    try {
      return await _eventoRepository.buscarEventos(texto);
    } catch (e) {
      throw EventoException('Error al buscar eventos: $e');
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