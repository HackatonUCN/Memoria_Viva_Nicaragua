import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/roles_usuario.dart';

import 'package:memoria_viva_nicaragua/data/datasources/firebase_auth_datasource.dart';
import 'package:memoria_viva_nicaragua/data/datasources/firebase_storage_datasource.dart';

/// Fake simple de FirebaseAuthDataSource para pruebas
class FakeAuthDataSource implements FirebaseAuthDataSource {
  final Map<String, _AuthUser> _users = {};
  _AuthUser? _current;
  final StreamController<domain.User?> _controller = StreamController.broadcast();

  @override
  domain.User? getCurrentUser() => _current?.toDomain();

  @override
  Stream<domain.User?> get authStateChanges => _controller.stream;

  @override
  Future<domain.User> signInWithEmailAndPassword({required String email, required String password}) async {
    final user = _users.values.firstWhere((u) => u.email == email && u.password == password, orElse: () => throw Exception('user-not-found'));
    _current = user;
    _controller.add(_current!.toDomain());
    return _current!.toDomain();
  }

  @override
  Future<domain.User> registerWithEmailAndPassword({required String email, required String password, required String displayName}) async {
    if (_users.values.any((u) => u.email == email)) {
      throw Exception('email-already-in-use');
    }
    final user = _AuthUser(
      id: 'u_${_users.length + 1}',
      email: email,
      nombre: displayName,
      role: UserRole.normal,
      password: password,
    );
    _users[user.id] = user;
    _current = user;
    _controller.add(user.toDomain());
    return user.toDomain();
  }

  @override
  Future<domain.User> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<domain.User> signInAnonymously() async {
    final user = _AuthUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@memoriaviva',
      nombre: 'Invitado',
      role: UserRole.invitado,
      password: '',
    );
    _current = user;
    _controller.add(user.toDomain());
    return user.toDomain();
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  bool isAnonymous() => _current?.role == UserRole.invitado;

  @override
  bool isAuthenticated() => _current != null;

  @override
  Future<String?> getIdToken() async => 'fake-token';

  /// Utilidad para sembrar un usuario en el fake
  void seedUser({required String id, required String email, required String nombre, UserRole role = UserRole.normal, String password = '123456'}) {
    _users[id] = _AuthUser(id: id, email: email, nombre: nombre, role: role, password: password);
  }
}

class _AuthUser {
  final String id;
  final String email;
  final String nombre;
  final UserRole role;
  final String password;

  _AuthUser({required this.id, required this.email, required this.nombre, required this.role, required this.password});

  domain.User toDomain() => domain.User(
        id: id,
        nombre: nombre,
        email: email,
        rol: role,
        fechaRegistro: DateTime.now().toUtc(),
        ultimaModificacion: DateTime.now().toUtc(),
        activo: true,
      );
}

/// Fake básico de FirebaseStorageDataSource en memoria
class FakeStorageDataSource implements FirebaseStorageDataSource {
  final Map<String, Uint8List> _storage = {};

  @override
  String get basePath => 'test';

  @override
  Future<void> deleteFile(String path) async {
    _storage.remove(path);
  }

  @override
  Future<File> downloadFile({required String path, required String localPath}) async {
    final bytes = _storage[path];
    final file = File(localPath);
    if (bytes != null) await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Future<bool> fileExists(String path) async => _storage.containsKey(path);

  @override
  Future<Uint8List> getData(String path) async => _storage[path] ?? Uint8List(0);

  @override
  Future<String> getDownloadUrl(String path) async => 'memory://$path';

  @override
  Future<StorageFileMetadata> getMetadata(String path) async => StorageFileMetadata(
        name: path.split('/').last,
        path: path,
        size: (_storage[path]?.length ?? 0),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        contentType: 'application/octet-stream',
      );

  @override
  Future<List<StorageFileMetadata>> listFiles(String path) async => _storage.keys
      .where((p) => p.startsWith(path))
      .map((p) => StorageFileMetadata(name: p.split('/').last, path: p, size: _storage[p]!.length, createdAt: DateTime.now(), updatedAt: DateTime.now(), contentType: 'application/octet-stream'))
      .toList();

  @override
  Future<String> uploadData({required Uint8List data, required String path, String? contentType, Map<String, String>? metadata}) async {
    _storage[path] = data;
    return await getDownloadUrl(path);
  }

  @override
  Future<String> uploadFile({required File file, required String path, String? contentType, Map<String, String>? metadata}) async {
    final bytes = await file.readAsBytes();
    _storage[path] = bytes;
    return await getDownloadUrl(path);
  }

  @override
  Future<StorageFileMetadata> updateMetadata({required String path, required Map<String, String> metadata}) async {
    return await getMetadata(path);
  }

  @override
  Future<String> getSignedUrl({required String path, required Duration expiration}) async {
    // En el fake, devolvemos una URL estática con query de expiración simulada
    final until = DateTime.now().add(expiration).millisecondsSinceEpoch;
    return 'memory://$path?exp=$until';
  }
}


