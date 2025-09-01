import 'dart:io';
import '../value_objects/multimedia.dart';

/// Interfaz para el servicio de procesamiento de multimedia
abstract class IMediaProcessingService {
  /// Comprime una imagen manteniendo calidad aceptable
  Future<File> comprimirImagen(File imagen, {int calidadPorcentaje = 80});

  /// Genera una miniatura de una imagen
  Future<File> generarMiniaturaImagen(File imagen, {int anchoPixeles = 300});

  /// Extrae un fotograma de un video en un momento específico
  Future<File> extraerFotogramaVideo(File video, {Duration? momento});

  /// Comprime un video manteniendo calidad aceptable
  Future<File> comprimirVideo(File video, {int calidadPorcentaje = 70});

  /// Genera una miniatura de un video (fotograma)
  Future<File> generarMiniaturaVideo(File video);

  /// Recorta una imagen a dimensiones específicas
  Future<File> recortarImagen(
    File imagen, {
    required int anchoPixeles,
    required int altoPixeles,
    int? x,
    int? y,
  });

  /// Recorta un video a una duración específica
  Future<File> recortarVideo(
    File video, {
    required Duration inicio,
    required Duration fin,
  });

  /// Aplica un filtro a una imagen
  Future<File> aplicarFiltroImagen(
    File imagen, {
    required String tipoFiltro,
    Map<String, dynamic>? parametros,
  });

  /// Aplica un filtro a un video
  Future<File> aplicarFiltroVideo(
    File video, {
    required String tipoFiltro,
    Map<String, dynamic>? parametros,
  });

  /// Comprime un archivo de audio
  Future<File> comprimirAudio(File audio, {int calidadPorcentaje = 80});

  /// Recorta un archivo de audio
  Future<File> recortarAudio(
    File audio, {
    required Duration inicio,
    required Duration fin,
  });

  /// Normaliza el volumen de un archivo de audio
  Future<File> normalizarAudio(File audio);

  /// Extrae metadatos de un archivo multimedia
  Future<Map<String, dynamic>> extraerMetadatos(File archivo);

  /// Elimina metadatos de un archivo multimedia (para privacidad)
  Future<File> eliminarMetadatos(File archivo);

  /// Convierte un archivo a otro formato
  Future<File> convertirFormato(
    File archivo, {
    required String formatoDestino,
  });

  /// Añade una marca de agua a una imagen
  Future<File> anadirMarcaAgua(
    File imagen, {
    required File marcaAgua,
    double opacidad = 0.3,
    String posicion = 'centro', // centro, esquina_superior_derecha, etc.
  });

  /// Optimiza un archivo multimedia para la web
  Future<File> optimizarParaWeb(File archivo, TipoMultimedia tipo);

  /// Detecta contenido inapropiado en imágenes
  Future<Map<String, dynamic>> detectarContenidoInapropiado(File imagen);

  /// Reconoce texto en imágenes (OCR)
  Future<String> reconocerTexto(File imagen, {String? idioma});

  /// Detecta objetos en imágenes
  Future<List<Map<String, dynamic>>> detectarObjetos(File imagen);

  /// Detecta rostros en imágenes
  Future<List<Map<String, dynamic>>> detectarRostros(File imagen);

  /// Verifica si un archivo multimedia es válido
  Future<bool> verificarArchivoValido(File archivo, TipoMultimedia tipo);

  /// Obtiene la duración de un archivo de audio o video
  Future<Duration?> obtenerDuracion(File archivo);

  /// Obtiene las dimensiones de una imagen
  Future<Map<String, int>?> obtenerDimensionesImagen(File imagen);

  /// Obtiene el tamaño en bytes de un archivo
  Future<int> obtenerTamanoArchivo(File archivo);
}
