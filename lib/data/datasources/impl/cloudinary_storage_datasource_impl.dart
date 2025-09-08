import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/errors/exception.dart';
import '../../../core/config/environment.dart';
import '../firebase_storage_datasource.dart';

/// Implementación que usa Cloudinary pero respeta la interfaz FirebaseStorageDataSource
class CloudinaryStorageDataSourceImpl implements FirebaseStorageDataSource {
  final String _basePath;
  final String _cloudName;
  final String _uploadPreset;
  final http.Client _client;

  CloudinaryStorageDataSourceImpl({
    required String basePath,
    String? cloudName,
    String? uploadPreset,
    http.Client? client,
  })  : _basePath = basePath,
        _cloudName = cloudName ?? Environment.CLOUDINARY_CLOUD_NAME,
        _uploadPreset = uploadPreset ?? Environment.CLOUDINARY_UPLOAD_PRESET,
        _client = client ?? http.Client();

  @override
  String get basePath => _basePath;

  Uri _endpoint(String resourceType) => Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );

  String _resolveFolderPath(String path) {
    // Normaliza la ruta eliminando el prefijo '/'
    String p = path.startsWith('/') ? path.substring(1) : path;
    // Si ya comienza con el basePath, no lo duplicamos
    if (p == _basePath || p.startsWith('$_basePath/')) {
      return p.replaceAll(RegExp(r'/+'), '/');
    }
    // De lo contrario, lo preprendemos una sola vez
    return '$_basePath/$p'.replaceAll(RegExp(r'/+'), '/');
  }

  String _resourceTypeFromContentType(String? contentType) {
    if (contentType == null) return 'raw';
    if (contentType.startsWith('image/')) return 'image';
    if (contentType.startsWith('video/')) return 'video';
    if (contentType.startsWith('audio/')) return 'video'; // para streaming de audio
    return 'raw';
  }

  Future<String> _uploadMultipart({
    required List<http.MultipartFile> files,
    required String resourceType,
    required String folder,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _endpoint(resourceType))
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.addAll(files);

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw StorageException(
          message: 'Cloudinary upload failed (${response.statusCode}): ${response.body}',
          code: response.statusCode.toString(),
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['secure_url'] as String? ?? (json['url'] as String? ?? '');
    } catch (e) {
      throw StorageException(message: 'Error subiendo a Cloudinary: $e');
    }
  }

  @override
  Future<String> uploadFile({
    required File file,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    final folder = _resolveFolderPath(path);
    final resourceType = _resourceTypeFromContentType(contentType);
    final fileFieldName = 'file';
    final mf = await http.MultipartFile.fromPath(
      fileFieldName,
      file.path,
      contentType: contentType != null ? MediaType.parse(contentType) : null,
    );
    return _uploadMultipart(files: [mf], resourceType: resourceType, folder: folder);
  }

  @override
  Future<String> uploadData({
    required Uint8List data,
    required String path,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    final folder = _resolveFolderPath(path);
    final resourceType = _resourceTypeFromContentType(contentType);
    final mf = http.MultipartFile.fromBytes(
      'file',
      data,
      filename: 'upload',
      contentType: contentType != null ? MediaType.parse(contentType) : null,
    );
    return _uploadMultipart(files: [mf], resourceType: resourceType, folder: folder);
  }

  @override
  Future<File> downloadFile({required String path, required String localPath}) async {
    throw StorageException(message: 'downloadFile no soportado con Cloudinary en cliente');
  }

  @override
  Future<Uint8List> getData(String path) async {
    throw StorageException(message: 'getData no soportado con Cloudinary en cliente');
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    throw StorageException(message: 'getDownloadUrl no aplica; usar secure_url devuelto al subir');
  }

  @override
  Future<void> deleteFile(String path) async {
    // Requiere API firmada (server). No implementar en cliente por seguridad.
    throw StorageException(message: 'deleteFile requiere servidor (firma segura)');
  }

  @override
  Future<bool> fileExists(String path) async {
    return false;
  }

  @override
  Future<List<StorageFileMetadata>> listFiles(String path) async {
    return <StorageFileMetadata>[];
  }

  @override
  Future<StorageFileMetadata> updateMetadata({
    required String path,
    required Map<String, String> metadata,
  }) async {
    throw StorageException(message: 'updateMetadata no soportado en cliente');
  }

  @override
  Future<StorageFileMetadata> getMetadata(String path) async {
    throw StorageException(message: 'getMetadata no soportado en cliente');
  }

  @override
  Future<String> getSignedUrl({required String path, required Duration expiration}) async {
    throw StorageException(message: 'getSignedUrl no aplicable para Cloudinary en cliente');
  }
}

/// Helper mínimo para contentType en http.MultipartFile
// MediaType se usa desde http_parser (no necesitamos parser propio)


