import 'dart:io';
import '../value_objects/multimedia.dart';

/// Interfaz para el servicio de almacenamiento
abstract class IStorageService {
  /// Sube un archivo y retorna su URL
  Future<String> subirArchivo(File archivo, String path);

  /// Sube un archivo multimedia y retorna el objeto Multimedia
  Future<Multimedia> subirMultimedia(File archivo, TipoMultimedia tipo, {
    String? descripcion,
    String? customPath,
  });

  /// Elimina un archivo por su URL
  Future<void> eliminarArchivo(String url);

  /// Genera una URL de miniatura
  Future<String> generarThumbnail(String url, TipoMultimedia tipo);

  /// Optimiza un archivo multimedia
  Future<String> optimizarArchivo(String url, TipoMultimedia tipo);

  /// Obtiene el tamaño de un archivo
  Future<int> obtenerTamanoArchivo(String url);

  /// Verifica si un archivo existe
  Future<bool> existeArchivo(String url);
}
