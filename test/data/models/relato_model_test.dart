import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva_nicaragua/data/models/content/relato_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/multimedia_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/ubicacion_model.dart';
import 'package:memoria_viva_nicaragua/domain/entities/relato.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart' as vm;
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart' as vu;

void main() {
  group('RelatoModel', () {
    late Map<String, dynamic> fullMap;
    late Map<String, dynamic> partialMap;
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    setUp(() {
      fullMap = {
        'id': 'r1',
        'titulo': 'Tradición',
        'contenido': 'Contenido extenso',
        'autorId': 'u1',
        'autorNombre': 'Juan',
        'categoriaId': 'cat1',
        'categoriaNombre': 'Relatos',
        'ubicacion': UbicacionModel(
          latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
        ).toMap(),
        'multimedia': [
          MultimediaModel(
            url: 'https://example.com/foto.jpg',
            tipo: 'imagen',
            fechaSubida: now,
          ).toMap(),
        ],
        'etiquetas': ['cultura'],
        'fechaCreacion': now,
        'fechaActualizacion': now,
        'estado': 'activo',
        'reportes': 1,
        'procesado': true,
        'likes': 2,
        'compartidos': 3,
        'eliminado': false,
      };

      partialMap = {
        'id': 'r2',
        'titulo': 'T',
        'contenido': 'C',
        'autorId': 'u2',
        'autorNombre': 'Ana',
        'categoriaId': 'cat1',
        'categoriaNombre': 'Relatos',
        'fechaCreacion': now,
        'fechaActualizacion': now,
        // faltan opcionales
      };
    });

    group('fromFirestore', () {
      test('crea modelo correctamente con datos completos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('relatos').doc('r1').set(fullMap);
        final doc = await firestore.collection('relatos').doc('r1').get();
        final model = RelatoModel.fromFirestore(doc);

        expect(model.id, 'r1');
        expect(model.titulo, 'Tradición');
        expect(model.contenido, 'Contenido extenso');
        expect(model.multimedia, isNotEmpty);
        expect(model.ubicacion, isNotNull);
        expect(model.estado, 'activo');
      });

      test('maneja campos opcionales nulos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('relatos').doc('r2').set(partialMap);
        final doc = await firestore.collection('relatos').doc('r2').get();
        final model = RelatoModel.fromFirestore(doc);
        expect(model.ubicacion, isNull);
        expect(model.multimedia, isEmpty);
        expect(model.etiquetas, isEmpty);
        expect(model.reportes, 0);
        expect(model.procesado, isFalse);
        expect(model.likes, 0);
        expect(model.compartidos, 0);
        expect(model.eliminado, isFalse);
        expect(model.fechaEliminacion, isNull);
      });

      test('usa doc.id cuando falta id en datos', () async {
        final firestore = FakeFirebaseFirestore();
        final dataSinId = Map<String, dynamic>.from(partialMap)..remove('id');
        await firestore.collection('relatos').doc('docXYZ').set(dataSinId);
        final doc = await firestore.collection('relatos').doc('docXYZ').get();
        final model = RelatoModel.fromFirestore(doc);
        expect(model.id, 'docXYZ');
      });

      test('lanza excepción para datos inválidos', () {
        final invalid = {...partialMap, 'id': null};
        expect(() => RelatoModel.fromMap(invalid), throwsA(isA<TypeError>()));
      });
    });

    group('toFirestore', () {
      test('serializa todos los campos correctamente', () {
        final model = RelatoModel.fromMap(fullMap);
        final map = model.toMap();
        expect(map['id'], 'r1');
        expect(map['titulo'], 'Tradición');
        expect(map['multimedia'], isA<List<dynamic>>());
        expect(map['fechaCreacion'], isA<Timestamp>());
        expect(map['estado'], 'activo');
      });

      test('maneja campos nulos apropiadamente', () {
        final model = RelatoModel.fromMap(partialMap);
        final map = model.toMap();
        expect(map['ubicacion'], isNull);
        expect(map['multimedia'], isA<List<dynamic>>());
      });
    });

    group('conversión con entidad', () {
      test('convierte a entidad sin pérdida de datos', () {
        final model = RelatoModel.fromMap(fullMap);
        final entity = model.toDomain();
        expect(entity.id, model.id);
        expect(entity.titulo, model.titulo);
        expect(entity.estado, EstadoModeracion.activo);
        expect(entity.multimedia.length, model.multimedia.length);
      });

      test('convierte desde entidad correctamente', () {
        final entity = domain.Relato(
          id: 'rid',
          titulo: 'Nombre',
          contenido: 'Contenido',
          autorId: 'u',
          autorNombre: 'Aut',
          categoriaId: 'c',
          categoriaNombre: 'Cat',
          ubicacion: vu.Ubicacion(
            latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
          ),
          multimedia: [
            vm.Multimedia(url: 'https://example.com/img.jpg'),
          ],
          etiquetas: const ['tag'],
          fechaCreacion: DateTime.utc(2022, 1, 1),
          fechaActualizacion: DateTime.utc(2022, 1, 2),
        );
        final model = RelatoModel.fromDomain(entity);
        expect(model.id, entity.id);
        expect(model.ubicacion, isA<Map<String, dynamic>?>());
        expect(model.multimedia, isA<List<Map<String, dynamic>>>());
      });
    });

    group('casos extremos', () {
      test('maneja strings muy largos y caracteres especiales', () {
        final long = 'x' * 8000 + ' ñá@#';
        final model = RelatoModel(
          id: 'rL',
          titulo: long,
          contenido: long,
          autorId: 'u',
          autorNombre: 'N',
          categoriaId: 'c',
          categoriaNombre: 'C',
          fechaCreacion: now,
          fechaActualizacion: now,
        );
        final map = model.toMap();
        expect(map['titulo'], long);
      });
    });
  });
}


