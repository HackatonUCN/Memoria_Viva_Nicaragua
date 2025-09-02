import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
// TODO: Instalar el paquete mime con: flutter pub add mime
// import 'package:mime/mime.dart';

import '../../../core/errors/exception.dart';
import '../firebase_storage_datasource.dart';

/// Implementación de FirebaseStorageDataSource
class FirebaseStorageDataSourceImpl implements FirebaseStorageDataSource {
  final FirebaseStorage _storage;
  final String _basePath;
  
  FirebaseStorageDataSourceImpl({
    required String basePath,
    FirebaseStorage? storage,
  }) : _basePath = basePath,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  String get basePath => _basePath;
  
  /// Construye la ruta completa en storage
  String _buildFullPath(String path) {
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$_basePath/$path'.replaceAll(RegExp(r'\/+'), '/');
  }
  
  /// Detecta el tipo de contenido de un archivo
  String? _detectContentType(String filePath, [String? providedType]) {
    if (providedType != null) return providedType;
    
    // TODO: Implementar detección de tipo cuando se instale el paquete mime
    // return lookupMimeType(filePath) ?? 'application/octet-stream';
    
    // Mientras tanto, detectar por extensión
    final ext = path.extension(filePath).toLowerCase().replaceAll('.', '');
    switch (ext) {
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp':
        return 'image/${ext == 'jpg' ? 'jpeg' : ext}';
      case 'mp4': case 'mov': case 'webm':
        return 'video/$ext';
      case 'mp3': case 'wav': case 'm4a': case 'ogg':
        return 'audio/${ext == 'm4a' ? 'mp4' : ext}';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Convierte un StorageMetadata a StorageFileMetadata
  StorageFileMetadata _convertMetadata(FullMetadata meta, String path) {
    return StorageFileMetadata(
      name: path.split('/').last,
      path: path,
      size: meta.size ?? 0,
      createdAt: meta.timeCreated ?? DateTime.now(),
      updatedAt: meta.updated ?? DateTime.now(),
      contentType: meta.contentType,
      customMetadata: meta.customMetadata,
      bucket: meta.bucket,
      generation: meta.generation,
      md5Hash: meta.md5Hash,
    );
  }

  @override
  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final fullPath = _buildFullPath(path);
      final fileName = file.path.split('/').last;
      
      // Detectar el tipo de contenido si no se proporciona
      final detectedContentType = _detectContentType(file.path, contentType);
      
      // Preparar los metadatos
      final metaData = SettableMetadata(
        contentType: detectedContentType,
        customMetadata: {
          'originalName': fileName,
          ...?metadata,
        },
      );
      
      // Subir el archivo
      final storageRef = _storage.ref(fullPath);
      await storageRef.putFile(file, metaData);
      
      // Devolver la URL de descarga
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al subir archivo: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al subir archivo: $e',
      );
    }
  }

  @override
  Future<String> uploadData({
    required Uint8List data,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final fullPath = _buildFullPath(path);
      final fileName = path.split('/').last;
      
      // Preparar los metadatos
      final metaData = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
        customMetadata: {
          'originalName': fileName,
          ...?metadata,
        },
      );
      
      // Subir los datos
      final storageRef = _storage.ref(fullPath);
      await storageRef.putData(data, metaData);
      
      // Devolver la URL de descarga
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al subir datos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al subir datos: $e',
      );
    }
  }

  @override
  Future<File> downloadFile({
    required String path,
    required String localPath,
  }) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      final file = File(localPath);
      await storageRef.writeToFile(file);
      
      return file;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al descargar archivo: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al descargar archivo: $e',
      );
    }
  }

  @override
  Future<Uint8List> getData(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      return await storageRef.getData() ?? Uint8List(0);
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al obtener datos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al obtener datos: $e',
      );
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al obtener URL de descarga: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al obtener URL de descarga: $e',
      );
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      await storageRef.delete();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al eliminar archivo: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al eliminar archivo: $e',
      );
    }
  }

  @override
  Future<bool> fileExists(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      // Intentar obtener metadatos, si falla el archivo no existe
      await storageRef.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<StorageFileMetadata>> listFiles(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      final listResult = await storageRef.listAll();
      
      // Procesar los resultados
      final results = <StorageFileMetadata>[];
      
      // Obtener metadatos para cada archivo
      for (final item in listResult.items) {
        try {
          final meta = await item.getMetadata();
          results.add(_convertMetadata(meta, item.fullPath));
        } catch (e) {
          // Ignorar errores individuales y continuar con el siguiente archivo
          print('Error obteniendo metadatos para ${item.fullPath}: $e');
        }
      }
      
      return results;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al listar archivos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al listar archivos: $e',
      );
    }
  }

  @override
  Future<StorageFileMetadata> updateMetadata({
    required String path,
    required Map<String, String> metadata,
  }) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      // Obtener metadatos actuales
      final currentMeta = await storageRef.getMetadata();
      
      // Preparar nuevos metadatos
      final updatedMeta = SettableMetadata(
        contentType: currentMeta.contentType,
        customMetadata: {
          ...?currentMeta.customMetadata,
          ...metadata,
        },
      );
      
      // Actualizar metadatos
      final resultMeta = await storageRef.updateMetadata(updatedMeta);
      
      return _convertMetadata(resultMeta, path);
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al actualizar metadatos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al actualizar metadatos: $e',
      );
    }
  }

  @override
  Future<StorageFileMetadata> getMetadata(String path) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      final meta = await storageRef.getMetadata();
      return _convertMetadata(meta, path);
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al obtener metadatos: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al obtener metadatos: $e',
      );
    }
  }

  @override
  Future<String> getSignedUrl({
    required String path,
    required Duration expiration,
  }) async {
    try {
      final fullPath = _buildFullPath(path);
      final storageRef = _storage.ref(fullPath);
      
      // Crear URL firmada
      return await storageRef.getDownloadURL();
      
      // Firebase Storage en Flutter no soporta directamente URLs firmadas con expiración
      // como en la versión web/admin. Esta es una limitación conocida.
      // Para implementar URLs firmadas con expiración, se necesitaría
      // usar Firebase Cloud Functions.
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Error al generar URL firmada: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error inesperado al generar URL firmada: $e',
      );
    }
  }
}
