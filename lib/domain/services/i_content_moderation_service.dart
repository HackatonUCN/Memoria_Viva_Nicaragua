import 'dart:io';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';
import '../entities/notificacion.dart';
import '../value_objects/multimedia.dart';
import '../enums/estado_moderacion.dart';

/// Interfaz para el servicio de moderación de contenido
abstract class IContentModerationService {
  /// Inicializa el servicio
  Future<void> inicializar();

  /// Analiza texto para detectar contenido inapropiado
  Future<Map<String, dynamic>> analizarTexto(String texto);

  /// Analiza una imagen para detectar contenido inapropiado
  Future<Map<String, dynamic>> analizarImagen(File imagen);

  /// Analiza un video para detectar contenido inapropiado
  Future<Map<String, dynamic>> analizarVideo(File video);

  /// Analiza un audio para detectar contenido inapropiado
  Future<Map<String, dynamic>> analizarAudio(File audio);

  /// Analiza un relato completo
  Future<Map<String, dynamic>> analizarRelato(Relato relato);

  /// Analiza un saber popular completo
  Future<Map<String, dynamic>> analizarSaberPopular(SaberPopular saber);

  /// Analiza un evento cultural completo
  Future<Map<String, dynamic>> analizarEventoCultural(EventoCultural evento);

  /// Analiza un comentario
  Future<Map<String, dynamic>> analizarComentario(String comentario);

  /// Analiza una notificación
  Future<Map<String, dynamic>> analizarNotificacion(Notificacion notificacion);

  /// Analiza un archivo multimedia
  Future<Map<String, dynamic>> analizarMultimedia(Multimedia multimedia);

  /// Verifica si un texto contiene palabras prohibidas
  Future<bool> contienePalabrasProhibidas(String texto);

  /// Verifica si un texto contiene lenguaje ofensivo
  Future<bool> contieneLenguajeOfensivo(String texto);

  /// Verifica si una imagen contiene contenido explícito
  Future<bool> contieneContenidoExplicito(File imagen);

  /// Verifica si una imagen contiene violencia
  Future<bool> contieneViolencia(File imagen);

  /// Obtiene una puntuación de seguridad para un contenido (0-100)
  Future<int> obtenerPuntuacionSeguridad({
    String? texto,
    File? imagen,
    File? video,
    File? audio,
  });

  /// Recomienda una acción de moderación basada en el análisis
  Future<EstadoModeracion> recomendarAccionModeracion(Map<String, dynamic> analisis);

  /// Registra un reporte de contenido inapropiado
  Future<void> registrarReporte({
    required String contenidoId,
    required String tipoContenido,
    required String usuarioId,
    required String razon,
    String? descripcion,
  });

  /// Obtiene reportes pendientes de revisión
  Future<List<Map<String, dynamic>>> obtenerReportesPendientes({
    String? tipoContenido,
    int limite = 50,
  });

  /// Procesa un reporte (aprobar o rechazar)
  Future<void> procesarReporte({
    required String reporteId,
    required bool aprobar,
    required String moderadorId,
    String? comentario,
  });

  /// Obtiene estadísticas de moderación
  Future<Map<String, dynamic>> obtenerEstadisticasModeracion({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  });

  /// Obtiene contenido pendiente de moderación
  Future<List<Map<String, dynamic>>> obtenerContenidoPendiente({
    String? tipoContenido,
    int limite = 50,
  });

  /// Actualiza las reglas de moderación
  Future<void> actualizarReglasModeracion(Map<String, dynamic> reglas);

  /// Obtiene las reglas de moderación actuales
  Future<Map<String, dynamic>> obtenerReglasModeracion();

  /// Verifica si un usuario ha sido reportado frecuentemente
  Future<bool> usuarioReportadoFrecuentemente(String usuarioId);

  /// Obtiene el historial de moderación de un contenido
  Future<List<Map<String, dynamic>>> obtenerHistorialModeracion({
    required String contenidoId,
    required String tipoContenido,
  });

  /// Bloquea temporalmente a un usuario por infracciones
  Future<void> bloquearUsuarioTemporalmente({
    required String usuarioId,
    required int diasBloqueo,
    required String razon,
    required String moderadorId,
  });

  /// Verifica si un usuario está bloqueado
  Future<bool> verificarUsuarioBloqueado(String usuarioId);

  /// Desbloquea a un usuario
  Future<void> desbloquearUsuario({
    required String usuarioId,
    required String moderadorId,
    required String razon,
  });
}
