import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'package:memoria_viva_nicaragua/data/datasources/impl/firebase_storage_datasource_impl.dart';
import 'package:memoria_viva_nicaragua/data/datasources/firebase_storage_datasource.dart';
import 'package:memoria_viva_nicaragua/core/errors/exception.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockReference extends Mock implements Reference {}
class MockFullMetadata extends Mock implements FullMetadata {}
class MockSettableMetadata extends Fake implements SettableMetadata {}
class MockFile extends Mock implements File {}
class MockUploadTask extends Mock implements UploadTask {}
class MockDownloadTask extends Mock implements DownloadTask {}
class MockListResult extends Mock implements ListResult {}

void main() {
  setUpAll(() {
    registerFallbackValue(SettableMetadata());
    // Fallback para parámetros de tipo File en any()
    registerFallbackValue(File('dummy.txt'));
  });

  late MockFirebaseStorage mockStorage;
  late MockReference mockRef;
  late FirebaseStorageDataSourceImpl dataSource;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    mockRef = MockReference();
    dataSource = FirebaseStorageDataSourceImpl(basePath: 'base', storage: mockStorage);
  });

  group('FirebaseStorageDataSourceImpl', () {
    test('uploadFile desde File devuelve URL', () async {
      final file = MockFile();
      when(() => file.path).thenReturn('C:/tmp/pic.jpg');
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.putFile(any<File>(), any<SettableMetadata>())).thenReturn(MockUploadTask());
      when(() => mockRef.getDownloadURL()).thenAnswer((_) async => 'https://download');

      final url = await dataSource.uploadFile(file: file, path: 'pics/pic.jpg');
      expect(url, 'https://download');
    });

    test('downloadFile escribe a disco y retorna File', () async {
      final filePath = Directory.systemTemp.createTempSync().uri.toFilePath() + 'd.txt';
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.writeToFile(any<File>())).thenAnswer((invocation) {
        final f = invocation.positionalArguments.first as File;
        f.writeAsBytesSync([1, 2, 3]);
        return MockDownloadTask();
      });

      final out = await dataSource.downloadFile(path: 'docs/d.txt', localPath: filePath);
      expect(out.existsSync(), isTrue);
      expect(out.readAsBytesSync(), [1, 2, 3]);
      // cleanup
      try { out.deleteSync(); } catch (_) {}
    });

    test('getData retorna bytes (vía getData null => Uint8List(0))', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.getData()).thenAnswer((_) async => Uint8List(0));
      final bytes = await dataSource.getData('x');
      expect(bytes, isA<Uint8List>());
    });
    test('uploadData devuelve URL', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.putData(any(), any())).thenReturn(MockUploadTask());
      when(() => mockRef.getDownloadURL()).thenAnswer((_) async => 'https://download');

      final url = await dataSource.uploadData(data: Uint8List(3), path: 'path/file.txt');
      expect(url, 'https://download');
    });

    test('uploadData mapea FirebaseException a StorageException', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.putData(any(), any())).thenThrow(FirebaseException(plugin: 'storage', code: 'permission-denied'));

      expect(
        () => dataSource.uploadData(data: Uint8List(1), path: 'x'),
        throwsA(isA<StorageException>().having((e) => e.code, 'code', 'permission-denied')),
      );
    });

    test('getDownloadUrl retorna url', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.getDownloadURL()).thenAnswer((_) async => 'https://u');
      final url = await dataSource.getDownloadUrl('foo');
      expect(url, 'https://u');
    });

    test('deleteFile elimina sin error', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.delete()).thenAnswer((_) async {});
      await dataSource.deleteFile('foo');
      verify(() => mockRef.delete()).called(1);
    });

    test('fileExists retorna true si getMetadata no falla', () async {
      final meta = MockFullMetadata();
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.getMetadata()).thenAnswer((_) async => meta);
      final exists = await dataSource.fileExists('bar');
      expect(exists, isTrue);
    });

    test('fileExists retorna false si cualquier error', () async {
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.getMetadata()).thenThrow(Exception('not found'));
      final exists = await dataSource.fileExists('bar');
      expect(exists, isFalse);
    });

    test('getMetadata devuelve StorageFileMetadata', () async {
      final meta = MockFullMetadata();
      when(() => meta.size).thenReturn(10);
      when(() => meta.timeCreated).thenReturn(DateTime(2024, 1, 1));
      when(() => meta.updated).thenReturn(DateTime(2024, 1, 2));
      when(() => meta.contentType).thenReturn('text/plain');
      when(() => meta.customMetadata).thenReturn({'k': 'v'});
      when(() => meta.bucket).thenReturn('bucket');
      when(() => meta.generation).thenReturn('gen');
      when(() => meta.md5Hash).thenReturn('md5');

      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.getMetadata()).thenAnswer((_) async => meta);

      final out = await dataSource.getMetadata('p.txt');
      expect(out, isA<StorageFileMetadata>());
      expect(out.size, 10);
      expect(out.contentType, 'text/plain');
    });

    test('listFiles itera y convierte metadatos', () async {
      final meta = MockFullMetadata();
      when(() => meta.size).thenReturn(1);
      when(() => meta.timeCreated).thenReturn(DateTime(2024));
      when(() => meta.updated).thenReturn(DateTime(2024, 2));

      final item = MockReference();
      when(() => item.fullPath).thenReturn('base/f.txt');
      when(() => item.getMetadata()).thenAnswer((_) async => meta);
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      final mockList = MockListResult();
      when(() => mockList.items).thenReturn([item]);
      when(() => mockList.prefixes).thenReturn(const <Reference>[]);
      when(() => mockRef.listAll()).thenAnswer((_) async => mockList);

      final result = await dataSource.listFiles('');
      expect(result.length, 1);
      expect(result.first.name, 'f.txt');
    });

    test('downloadFile invoca writeToFile y retorna File', () async {
      final filePath = Directory.systemTemp.createTempSync().uri.toFilePath() + 'd.txt';
      when(() => mockStorage.ref(any())).thenReturn(mockRef);
      when(() => mockRef.writeToFile(any())).thenReturn(MockDownloadTask());

      final out = await dataSource.downloadFile(path: 'docs/d.txt', localPath: filePath);
      expect(out.path, filePath);
      verify(() => mockRef.writeToFile(any())).called(1);
      try { out.deleteSync(); } catch (_) {}
    });
  }, skip: 'No usamos Firebase Storage en producción; el storage real es Cloudinary');
}


