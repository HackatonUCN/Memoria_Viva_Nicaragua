import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva_nicaragua/data/models/content/saber_popular_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/multimedia_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/ubicacion_model.dart';
import 'package:memoria_viva_nicaragua/domain/entities/saber_popular.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart' as vm;
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart' as vu;
import 'package:memoria_viva_nicaragua/domain/enums/estado_moderacion.dart';

void main() {
  group('SaberPopularModel', () {
    late Map<String, dynamic> fullMap;
    late Map<String, dynamic> partialMap;
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    setUp(() {
      fullMap = {
        'id': 's1',
        'titulo': 'Dicho',
        'contenido': 'Contenido',
        'autorId': 'u1',
        'autorNombre': 'Juan',
        'categoriaId': 'cat1',
        'categoriaNombre': 'Saberes',
        'ubicacion': UbicacionModel(
          latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
        ).toMap(),
        'imagenes': [
          MultimediaModel(
            url: 'https://example.com/foto.jpg', tipo: 'imagen', fechaSubida: now,
          ).toMap(),
        ],
        'etiquetas': ['popular'],
        'fechaCreacion': now,
        'fechaActualizacion': now,
        'estado': 'activo',
        'reportes': 2,
        'procesado': true,
        'likes': 10,
        'compartidos': 1,
        'eliminado': false,
      };

      partialMap = {
        'id': 's2',
        'titulo': 'T',
        'contenido': 'C',
        'autorId': 'u2',
        'autorNombre': 'Ana',
        'categoriaId': 'cat1',
        'categoriaNombre': 'Saberes',
        'fechaCreacion': now,
        'fechaActualizacion': now,
      };
    });

    group('fromFirestore', () {
      test('crea modelo correctamente con datos completos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('saberes').doc('s1').set(fullMap);
        final doc = await firestore.collection('saberes').doc('s1').get();
        final model = SaberPopularModel.fromFirestore(doc);

        expect(model.id, 's1');
        expect(model.titulo, 'Dicho');
        expect(model.contenido, 'Contenido');
        expect(model.imagenes, isNotEmpty);
        expect(model.ubicacion, isNotNull);
        expect(model.estado, 'activo');
      });

      test('maneja campos opcionales nulos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('saberes').doc('s2').set(partialMap);
        final doc = await firestore.collection('saberes').doc('s2').get();
        final model = SaberPopularModel.fromFirestore(doc);
        expect(model.ubicacion, isNull);
        expect(model.imagenes, isEmpty);
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
        await firestore.collection('saberes').doc('docABC').set(dataSinId);
        final doc = await firestore.collection('saberes').doc('docABC').get();
        final model = SaberPopularModel.fromFirestore(doc);
        expect(model.id, 'docABC');
      });

      test('lanza excepción para datos inválidos', () {
        final invalid = {...partialMap, 'id': null};
        expect(() => SaberPopularModel.fromMap(invalid), throwsA(isA<TypeError>()));
      });
    });

    group('toFirestore', () {
      test('serializa todos los campos correctamente', () {
        final model = SaberPopularModel.fromMap(fullMap);
        final map = model.toMap();
        expect(map['id'], 's1');
        expect(map['titulo'], 'Dicho');
        expect(map['imagenes'], isA<List<dynamic>>());
        expect(map['fechaCreacion'], isA<Timestamp>());
        expect(map['estado'], 'activo');
      });

      test('maneja campos nulos apropiadamente', () {
        final model = SaberPopularModel.fromMap(partialMap);
        final map = model.toMap();
        expect(map['ubicacion'], isNull);
        expect(map['imagenes'], isA<List<dynamic>>());
      });
    });

    group('conversión con entidad', () {
      test('convierte a entidad sin pérdida de datos', () {
        final model = SaberPopularModel.fromMap(fullMap);
        final entity = model.toDomain();
        expect(entity.id, model.id);
        expect(entity.titulo, model.titulo);
        expect(entity.estado, EstadoModeracion.activo);
        expect(entity.imagenes.length, model.imagenes.length);
      });

      test('convierte desde entidad correctamente', () {
        final entity = domain.SaberPopular(
          id: 'sid',
          titulo: 'Nombre',
          contenido: 'Contenido',
          categoriaId: 'c',
          categoriaNombre: 'Cat',
          autorId: 'u',
          autorNombre: 'Aut',
          ubicacion: vu.Ubicacion(
            latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
          ),
          imagenes: [
            vm.Multimedia(url: 'https://example.com/img.jpg'),
          ],
          etiquetas: const ['tag'],
          fechaCreacion: DateTime.utc(2022, 1, 1),
          fechaActualizacion: DateTime.utc(2022, 1, 2),
        );
        final model = SaberPopularModel.fromDomain(entity);
        expect(model.id, entity.id);
        expect(model.ubicacion, isA<Map<String, dynamic>?>());
        expect(model.imagenes, isA<List<Map<String, dynamic>>>());
      });
    });

    group('casos extremos', () {
      test('maneja strings muy largos y caracteres especiales', () {
        final long = 'x' * 8000 + ' ñá@#';
        final model = SaberPopularModel(
          id: 'sL',
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


