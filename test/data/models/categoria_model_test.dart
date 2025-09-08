import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva_nicaragua/data/models/categoria_model.dart';
import 'package:memoria_viva_nicaragua/domain/entities/categoria.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/tipos_contenido.dart';

void main() {
  group('CategoriaModel', () {
    late Map<String, dynamic> fullMap;
    late Map<String, dynamic> partialMap;
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    setUp(() {
      fullMap = {
        'id': 'c1',
        'nombre': 'Relatos',
        'descripcion': 'Relatos y Memorias',
        'tipo': 'relato',
        'categoriaPadreId': null,
        'icono': 'relato',
        'color': '#4A6192',
        'orden': 1,
        'activa': true,
        'fechaCreacion': now,
        'fechaActualizacion': now,
      };

      partialMap = {
        'id': 'c2',
        'nombre': 'Saberes',
        'descripcion': 'Saberes Populares',
        'tipo': 'saber',
        'icono': 'saber',
        'color': '#A3B18A',
        'orden': 0,
        'fechaCreacion': now,
        'fechaActualizacion': now,
      };
    });

    group('fromFirestore', () {
      test('crea modelo correctamente con datos completos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('categorias').doc('c1').set(fullMap);
        final doc = await firestore.collection('categorias').doc('c1').get();
        final model = CategoriaModel.fromFirestore(doc);
        expect(model.id, 'c1');
        expect(model.nombre, 'Relatos');
        expect(model.tipo, 'relato');
        expect(model.icono, 'relato');
        expect(model.color, '#4A6192');
        expect(model.orden, 1);
        expect(model.activa, isTrue);
      });

      test('maneja campos opcionales nulos con defaults', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('categorias').doc('c2').set(partialMap);
        final doc = await firestore.collection('categorias').doc('c2').get();
        final model = CategoriaModel.fromFirestore(doc);
        expect(model.categoriaPadreId, isNull);
        expect(model.activa, isTrue);
      });

      test('lanza excepción para datos inválidos', () {
        final invalid = {...partialMap, 'id': null};
        expect(() => CategoriaModel.fromMap(invalid), throwsA(isA<TypeError>()));
      });
    });

    group('toFirestore', () {
      test('serializa todos los campos correctamente', () {
        final model = CategoriaModel.fromMap(fullMap);
        final map = model.toMap();
        expect(map['id'], 'c1');
        expect(map['nombre'], 'Relatos');
        expect(map['tipo'], 'relato');
        expect(map['fechaCreacion'], isA<Timestamp>());
      });

      test('maneja campos nulos apropiadamente', () {
        final model = CategoriaModel.fromMap(partialMap);
        final map = model.toMap();
        expect(map['categoriaPadreId'], isNull);
        expect(map['activa'], isTrue);
      });
    });

    group('conversión con entidad', () {
      test('convierte a entidad sin pérdida de datos', () {
        final model = CategoriaModel.fromMap(fullMap);
        final entity = model.toDomain();
        expect(entity.id, model.id);
        expect(entity.nombre, model.nombre);
        expect(entity.tipo.value, model.tipo);
      });

      test('convierte desde entidad correctamente', () {
        final entity = domain.Categoria(
          id: 'cid',
          nombre: 'Eventos',
          descripcion: 'Eventos',
          tipo: TipoContenido.evento,
          icono: 'evento',
          color: '#2E3A59',
          orden: 2,
          fechaCreacion: DateTime.utc(2022, 1, 1),
          fechaActualizacion: DateTime.utc(2022, 1, 2),
        );
        final model = CategoriaModel.fromDomain(entity);
        expect(model.id, entity.id);
        expect(model.tipo, 'evento');
        expect(model.icono, 'evento');
      });
    });

    group('casos extremos', () {
      test('maneja strings muy largos y caracteres especiales', () {
        final long = 'x' * 3000 + ' ñá@#';
        final model = CategoriaModel(
          id: 'cL',
          nombre: long,
          descripcion: long,
          tipo: 'relato',
          icono: 'i',
          color: '#FFFFFF',
          orden: 0,
          fechaCreacion: now,
          fechaActualizacion: now,
        );
        expect(model.nombre.length, greaterThan(3000));
      });
    });
  });
}


