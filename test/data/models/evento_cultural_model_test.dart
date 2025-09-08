import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva_nicaragua/data/models/content/evento_cultural_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/multimedia_model.dart';
import 'package:memoria_viva_nicaragua/data/models/value_objects/ubicacion_model.dart';
import 'package:memoria_viva_nicaragua/domain/entities/evento_cultural.dart' as domain;
import 'package:memoria_viva_nicaragua/domain/enums/tipos_evento.dart';
import 'package:memoria_viva_nicaragua/domain/value_objects/multimedia.dart' as vm;
import 'package:memoria_viva_nicaragua/domain/value_objects/ubicacion.dart' as vu;

void main() {
  group('EventoCulturalModel', () {
    late Map<String, dynamic> fullMap;
    late Map<String, dynamic> partialMap;
    final now = Timestamp.fromDate(DateTime.now().toUtc());

    setUp(() {
      fullMap = {
        'id': 'e1',
        'nombre': 'Feria de Agosto',
        'descripcion': 'Tradición',
        'tipo': 'feria',
        'categoriaId': 'catE',
        'categoriaNombre': 'Eventos',
        'ubicacion': UbicacionModel(
          latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
        ).toMap(),
        'imagenes': [
          MultimediaModel(
            url: 'https://example.com/foto.jpg', tipo: 'imagen', fechaSubida: now,
          ).toMap(),
        ],
        'fechaInicio': now,
        'fechaFin': now,
        'esRecurrente': true,
        'frecuencia': 'anual',
        'organizador': 'Alcaldía',
        'contacto': 'info@example.com',
        'creadoPorId': 'admin1',
        'creadoPorNombre': 'Admin',
        'fechaCreacion': now,
        'fechaActualizacion': now,
      };

      partialMap = {
        'id': 'e2',
        'nombre': 'Evento',
        'descripcion': 'Desc',
        'tipo': 'otro',
        'categoriaId': 'catE',
        'categoriaNombre': 'Eventos',
        'ubicacion': UbicacionModel(
          latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
        ).toMap(),
        'fechaInicio': now,
        'fechaFin': now,
        'organizador': 'Org',
        'creadoPorId': 'admin2',
        'creadoPorNombre': 'Admin 2',
        'fechaCreacion': now,
        'fechaActualizacion': now,
      };
    });

    group('fromFirestore', () {
      test('crea modelo correctamente con datos completos', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('eventos').doc('e1').set(fullMap);
        final doc = await firestore.collection('eventos').doc('e1').get();
        final model = EventoCulturalModel.fromFirestore(doc);

        expect(model.id, 'e1');
        expect(model.titulo, 'Feria de Agosto');
        expect(model.descripcion, 'Tradición');
        expect(model.tipo, 'feria');
        expect(model.imagenes, isNotEmpty);
        expect(model.esRecurrente, isTrue);
        expect(model.frecuencia, 'anual');
        expect(model.contacto, 'info@example.com');
      });

      test('maneja campos opcionales nulos con defaults', () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('eventos').doc('e2').set(partialMap);
        final doc = await firestore.collection('eventos').doc('e2').get();
        final model = EventoCulturalModel.fromFirestore(doc);
        expect(model.imagenes, isEmpty);
        expect(model.esRecurrente, isFalse);
        expect(model.frecuencia, isNull);
        expect(model.contacto, isNull);
      });

      test('usa doc.id cuando falta id en datos', () async {
        final firestore = FakeFirebaseFirestore();
        final dataSinId = Map<String, dynamic>.from(partialMap)..remove('id');
        await firestore.collection('eventos').doc('E999').set(dataSinId);
        final doc = await firestore.collection('eventos').doc('E999').get();
        final model = EventoCulturalModel.fromFirestore(doc);
        expect(model.id, 'E999');
      });

      test('lanza excepción para datos inválidos', () {
        final invalid = {...partialMap, 'id': null};
        expect(() => EventoCulturalModel.fromMap(invalid), throwsA(isA<TypeError>()));
      });
    });

    group('toFirestore', () {
      test('serializa todos los campos correctamente', () {
        final model = EventoCulturalModel.fromMap(fullMap);
        final map = model.toMap();
        expect(map['id'], 'e1');
        expect(map['nombre'], 'Feria de Agosto');
        expect(map['tipo'], 'feria');
        expect(map['imagenes'], isA<List<dynamic>>());
        expect(map['fechaInicio'], isA<Timestamp>());
        expect(map['fechaFin'], isA<Timestamp>());
      });

      test('maneja campos nulos apropiadamente', () {
        final model = EventoCulturalModel.fromMap(partialMap);
        final map = model.toMap();
        expect(map['imagenes'], isA<List<dynamic>>());
        expect(map['frecuencia'], isNull);
        expect(map['contacto'], isNull);
      });
    });

    group('conversión con entidad', () {
      test('convierte a entidad sin pérdida de datos', () {
        final model = EventoCulturalModel.fromMap(fullMap);
        final entity = model.toDomain();
        expect(entity.id, model.id);
        expect(entity.titulo, 'Feria de Agosto');
        expect(entity.tipo.value, 'feria');
        expect(entity.imagenes.length, model.imagenes.length);
      });

      test('convierte desde entidad correctamente', () {
        final entity = domain.EventoCultural(
          id: 'eid',
          titulo: 'Nombre',
          descripcion: 'Desc',
          tipo: TipoEvento.festival,
          categoriaId: 'c',
          categoriaNombre: 'Cat',
          ubicacion: vu.Ubicacion(
            latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
          ),
          imagenes: [
            vm.Multimedia(url: 'https://example.com/img.jpg'),
          ],
          fechaInicio: DateTime.utc(2022, 1, 1),
          fechaFin: DateTime.utc(2022, 1, 2),
          esRecurrente: false,
          organizador: 'Org',
          contacto: null,
          creadoPorId: 'a',
          creadoPorNombre: 'A',
          fechaCreacion: DateTime.utc(2022, 1, 1),
          fechaActualizacion: DateTime.utc(2022, 1, 2),
        );
        final model = EventoCulturalModel.fromDomain(entity);
        expect(model.id, entity.id);
        expect(model.ubicacion, isA<Map<String, dynamic>>());
        expect(model.imagenes, isA<List<Map<String, dynamic>>>());
        expect(model.tipo, 'festival');
      });
    });

    group('casos extremos', () {
      test('maneja strings muy largos y caracteres especiales', () {
        final long = 'x' * 8000 + ' ñá@#';
        final model = EventoCulturalModel(
          id: 'eL',
          titulo: long,
          descripcion: long,
          tipo: 'otro',
          categoriaId: 'c',
          categoriaNombre: 'C',
          ubicacion: UbicacionModel(
            latitud: 12.1, longitud: -86.3, departamento: 'Managua', municipio: 'Managua',
          ).toMap(),
          fechaInicio: now,
          fechaFin: now,
          organizador: 'Org',
          creadoPorId: 'a',
          creadoPorNombre: 'A',
          fechaCreacion: now,
          fechaActualizacion: now,
        );
        final map = model.toMap();
        expect(map['nombre'], long);
      });
    });
  });
}


