import 'dart:io';
import 'dart:typed_data';

/// Interfaz para la fuente de datos de Firebase Storage
abstract class FirebaseStorageDataSource {
  /// Ruta base del almacenamiento
  String get basePath;
  
  /// Sube un archivo desde una ruta local
  /// Devuelve la URL de descarga
  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  });
  
  /// Sube datos en memoria como archivo
  /// Devuelve la URL de descarga
  Future<String> uploadData({
    required Uint8List data,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  });
  
  /// Descarga un archivo a una ruta local
  Future<File> downloadFile({
    required String path,
    required String localPath,
  });
  
  /// Obtiene los datos de un archivo como bytes
  Future<Uint8List> getData(String path);
  
  /// Obtiene la URL de descarga de un archivo
  Future<String> getDownloadUrl(String path);
  
  /// Elimina un archivo
  Future<void> deleteFile(String path);
  
  /// Verifica si existe un archivo
  Future<bool> fileExists(String path);
  
  /// Lista archivos en una ruta
  Future<List<StorageFileMetadata>> listFiles(String path);
  
  /// Actualiza los metadatos de un archivo
  Future<StorageFileMetadata> updateMetadata({
    required String path,
    required Map<String, String> metadata,
  });
  
  /// Obtiene los metadatos de un archivo
  Future<StorageFileMetadata> getMetadata(String path);
  
  /// Genera una URL firmada con tiempo de expiración
  Future<String> getSignedUrl({
    required String path,
    required Duration expiration,
  });
}

/// Clase para almacenar metadatos de archivos en Firebase Storage
class StorageFileMetadata {
  final String name;
  final String path;
  final String? contentType;
  final Map<String, String>? customMetadata;
  final int size;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? bucket;
  final String? generation;
  final String? md5Hash;
  
  const StorageFileMetadata({
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    required this.updatedAt,
    this.contentType,
    this.customMetadata,
    this.bucket,
    this.generation,
    this.md5Hash,
  });
  
  @override
  String toString() => 'StorageFileMetadata(name: $name, path: $path, size: $size, contentType: $contentType)';
}
