import '../value_objects/multimedia.dart';

/// Política para validar y limitar archivos multimedia
class MultimediaPolicy {
  static const int MAX_ITEMS_POR_CONTENIDO = 10;
  static const int MAX_MB = Multimedia.MAX_FILE_SIZE_MB; // mantener alineado con VO

  static bool tamanoPermitido(int? bytes) {
    if (bytes == null) return true; // si no se conoce, dejar al VO validar al instanciar
    return bytes <= (MAX_MB * 1024 * 1024);
  }

  static bool cantidadPermitida(int cantidadActual) {
    return cantidadActual <= MAX_ITEMS_POR_CONTENIDO;
  }

  static bool urlSoportada(String url) {
    try {
      TipoMultimedia.detectarTipo(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
