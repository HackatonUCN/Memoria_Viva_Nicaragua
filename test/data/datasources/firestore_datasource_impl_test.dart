import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memoria_viva_nicaragua/data/datasources/impl/firestore_datasource_impl.dart';
import 'package:memoria_viva_nicaragua/core/errors/exception.dart';

class TestModel {
  final String id;
  final String nombre;
  final int edad;
  final bool activo;
  const TestModel({required this.id, required this.nombre, required this.edad, required this.activo});

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre, 'edad': edad, 'activo': activo};
  static TestModel fromMap(Map<String, dynamic> map) => TestModel(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        edad: map['edad'] as int,
        activo: map['activo'] as bool,
      );
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreDataSourceImpl<TestModel> dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreDataSourceImpl<TestModel>(
      collectionPath: 'tests',
      fromMap: TestModel.fromMap,
      toMap: (t) => t.toMap(),
      getId: (t) => t.id,
      firestore: fakeFirestore,
    );
  });

  group('FirestoreDataSourceImpl - CRUD', () {
    test('save y getById', () async {
      final model = TestModel(id: '1', nombre: 'Ana', edad: 20, activo: true);
      await dataSource.save(model);

      final fetched = await dataSource.getById('1');
      expect(fetched, isNotNull);
      expect(fetched!.nombre, 'Ana');
    });

    test('update modifica campos', () async {
      final model = TestModel(id: '1', nombre: 'Ana', edad: 20, activo: true);
      await dataSource.save(model);
      await dataSource.update(id: '1', data: {'edad': 21});
      final fetched = await dataSource.getById('1');
      expect(fetched!.edad, 21);
    });

    test('delete elimina documento', () async {
      final model = TestModel(id: '1', nombre: 'Ana', edad: 20, activo: true);
      await dataSource.save(model);
      await dataSource.delete('1');
      final fetched = await dataSource.getById('1');
      expect(fetched, isNull);
    });

    test('exists devuelve verdadero/falso', () async {
      final model = TestModel(id: '1', nombre: 'Ana', edad: 20, activo: true);
      await dataSource.save(model);
      expect(await dataSource.exists('1'), isTrue);
      await dataSource.delete('1');
      expect(await dataSource.exists('1'), isFalse);
    });
  });

  group('Consultas y streams', () {
    setUp(() async {
      await dataSource.save(TestModel(id: '1', nombre: 'Ana', edad: 20, activo: true));
      await dataSource.save(TestModel(id: '2', nombre: 'Luis', edad: 25, activo: false));
      await dataSource.save(TestModel(id: '3', nombre: 'Beto', edad: 30, activo: true));
    });

    test('getAll con orderBy y limit', () async {
      final all = await dataSource.getAll(orderBy: 'edad', descending: true, limit: 2);
      expect(all.length, 2);
      expect(all.first.nombre, 'Beto');
    });

    test('getWhere por igualdad', () async {
      final activos = await dataSource.getWhere(field: 'activo', isEqualTo: true, orderBy: 'edad');
      expect(activos.map((e) => e.nombre), containsAll(['Ana', 'Beto']));
    });

    test('query con operadores', () async {
      final result = await dataSource.query(
        filters: {
          'edad': ['edad', '>=', 25],
          'activo': true,
        },
        orderBy: 'edad',
        descending: true,
      );
      expect(result.length, 1);
      expect(result.first.nombre, 'Beto');
    });

    test('watchDocument emite cambios', () async {
      final stream = dataSource.watchDocument('1');
      final first = await stream.first;
      expect(first, isNotNull);
      expect(first!.nombre, 'Ana');
    });

    test('watchCollection emite lista', () async {
      final items = await dataSource.watchCollection(orderBy: 'edad').first;
      expect(items.length, 3);
    });

    test('watchWhere emite lista filtrada', () async {
      final items = await dataSource.watchWhere(field: 'activo', isEqualTo: true).first;
      expect(items.length, 2);
    });
  });

  group('Transacciones y lotes', () {
    test('runTransaction set y get', () async {
      await dataSource.runTransaction((tx) async {
        tx.set<Map<String, dynamic>>('tests', '10', TestModel(id: '10', nombre: 'Tx', edad: 1, activo: true).toMap());
      });
      final doc = await fakeFirestore.collection('tests').doc('10').get();
      expect(doc.exists, isTrue);
    });

    test('runBatch set/update/delete', () async {
      await dataSource.runBatch((batch) async {
        batch.set<Map<String, dynamic>>('tests', '20', TestModel(id: '20', nombre: 'B1', edad: 2, activo: true).toMap());
      });
      var doc = await fakeFirestore.collection('tests').doc('20').get();
      expect(doc.exists, isTrue);

      await dataSource.runBatch((batch) async {
        batch.update('tests', '20', {'nombre': 'B2'});
      });
      doc = await fakeFirestore.collection('tests').doc('20').get();
      expect(doc.data()!['nombre'], 'B2');

      await dataSource.runBatch((batch) async {
        batch.delete('tests', '20');
      });
      doc = await fakeFirestore.collection('tests').doc('20').get();
      expect(doc.exists, isFalse);
    });

    test('runTransaction envuelve errores en DatabaseException', () async {
      // Provocar explícitamente un FirebaseException para asegurar el mapeo
      expect(
        () => dataSource.runTransaction((tx) async {
          throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied', message: 'Denied');
        }),
        throwsA(isA<DatabaseException>().having((e) => e.code, 'code', 'permission-denied')),
      );
    });
  });

  group('Manejo de errores', () {
    test('getById re-lanza como DatabaseException ante FirebaseException', () async {
      // Simular error con una instancia real de FirebaseFirestore no es directo con fake
      // Validamos usando una instancia normal y capturamos mediante una operación inválida de rules (permiso denegado)
      // Como alternativa, verificamos que nuestro catch mapea FirebaseException a DatabaseException
      final ds = FirestoreDataSourceImpl<TestModel>(
        collectionPath: 'tests',
        fromMap: TestModel.fromMap,
        toMap: (t) => t.toMap(),
        getId: (t) => t.id,
        firestore: fakeFirestore,
      );

      // FakeFirebaseFirestore no arroja FirebaseException en lecturas válidas, así que probamos vía handler privado
      // Ejecutar una actualización sobre doc inexistente SI arroja FirebaseException
      // Actualizar un documento inexistente debe causar un FirebaseException envuelto en DatabaseException
      expect(() => ds.update(id: 'nope', data: {'x': 1}), throwsA(isA<DatabaseException>()));
    });
  });
}


