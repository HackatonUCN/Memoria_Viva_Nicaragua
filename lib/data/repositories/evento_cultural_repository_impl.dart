import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exception.dart';
import '../../domain/entities/evento_cultural.dart';
import '../../domain/enums/tipos_evento.dart';
import '../../domain/exceptions/evento_exception.dart';
import '../../domain/repositories/evento_cultural_repository.dart';
import '../../domain/value_objects/ubicacion.dart';
import '../../domain/value_objects/multimedia.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/firebase_storage_datasource.dart';
import '../models/content/content_model.dart';
import '../models/content/evento_cultural_model.dart';
import '../models/content/sugerencia_evento_model.dart';
import '../models/value_objects/ubicacion_model.dart';
import '../models/value_objects/multimedia_model.dart';

/// Implementación del repositorio de eventos culturales con Firebase
class EventoCulturalRepositoryImpl implements IEventoCulturalRepository {
  /// Fuente de datos para Firestore de eventos
  final FirestoreDataSource<EventoCulturalModel> _firestoreEventos;

  /// Fuente de datos para Firestore de sugerencias
  final FirestoreDataSource<SugerenciaEventoModel> _firestoreSugerencias;

  /// Fuente de datos para Storage
  final FirebaseStorageDataSource _storageDataSource;


  /// Colecciones
  static const String _eventosCollection = 'eventos_culturales';
  static const String _sugerenciasCollection = 'sugerencias_eventos';

  /// Storage base path
  static const String _eventosStoragePath = 'eventos_culturales';

  /// Límite por defecto
  static const int _defaultLimit = 20;

  EventoCulturalRepositoryImpl({
    required FirestoreDataSource<EventoCulturalModel> firestoreEventos,
    required FirestoreDataSource<SugerenciaEventoModel> firestoreSugerencias,
    required FirebaseStorageDataSource storageDataSource,
  })  : _firestoreEventos = firestoreEventos,
        _firestoreSugerencias = firestoreSugerencias,
        _storageDataSource = storageDataSource;

  /// Envuelve y mapea excepciones a las del dominio de eventos
  Future<T> _handleExceptions<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      throw EventoException('Error en la base de datos: ${e.message}', code: e.code);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw EventoPermissionException('Permiso denegado: ${e.message}');
      }
      throw EventoException('Error en Firebase: ${e.message}', code: e.code);
    } on SocketException catch (e) {
      throw EventoException(
        'Error de conexión: ${e.message}. Verifica tu conexión a Internet.',
        code: 'connection-error',
      );
    } catch (e) {
      if (e is EventoException) rethrow;
      throw EventoException('Error inesperado: $e');
    }
  }

  // -----------------------------
  // Eventos oficiales (CRUD + consultas)
  // -----------------------------

  @override
  Future<List<EventoCultural>> obtenerEventos() async {
    return await _handleExceptions(() async {
      final eventos = await _firestoreEventos.query(
        filters: {
          'eliminado': false,
        },
        orderBy: 'fechaInicio',
        descending: false,
        limit: _defaultLimit,
      );
      return eventos.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<EventoCultural?> obtenerEventoPorId(String id) async {
    return await _handleExceptions(() async {
      final model = await _firestoreEventos.getById(id);
      return model?.toDomain();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosPorCategoria(String categoriaId) async {
    return await _handleExceptions(() async {
      final eventos = await _firestoreEventos.query(
        filters: {
          'categoriaId': categoriaId,
          'eliminado': false,
        },
        orderBy: 'fechaInicio',
        descending: false,
      );
      return eventos.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosPorTipo(TipoEvento tipo) async {
    return await _handleExceptions(() async {
      final eventos = await _firestoreEventos.query(
        filters: {
          'tipo': tipo.value,
          'eliminado': false,
        },
        orderBy: 'fechaInicio',
        descending: false,
      );
      return eventos.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosPorFecha(DateTime fecha) async {
    return await _handleExceptions(() async {
      // Traer eventos cuyo rango incluya la fecha, considerando recurrentes
      final inicio = DateTime.utc(fecha.year, fecha.month, fecha.day, 0, 0, 0);
      final fin = DateTime.utc(fecha.year, fecha.month, fecha.day, 23, 59, 59);

      final modelos = await _firestoreEventos.query(
        filters: {
          // fechaInicio <= fin
          'fechaInicio': ['fechaInicio', '<=', ContentModel.dateTimeToTimestamp(fin)],
          // fechaFin >= inicio
          'fechaFin': ['fechaFin', '>=', ContentModel.dateTimeToTimestamp(inicio)],
          'eliminado': false,
        },
        orderBy: 'fechaInicio',
        descending: false,
        limit: 200,
      );

      final eventos = modelos.map((m) => m.toDomain()).toList();
      // Extender lógica para recurrentes anuales: aparece si mes/día coincide dentro del rango pedido
      return eventos.where((e) => _eventoCoincideEnFecha(e, fecha)).toList();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosPorRangoFecha({
    required DateTime inicio,
    required DateTime fin,
  }) async {
    return await _handleExceptions(() async {
      final modelos = await _firestoreEventos.query(
        filters: {
          'fechaInicio': ['fechaInicio', '<=', ContentModel.dateTimeToTimestamp(fin)],
          'fechaFin': ['fechaFin', '>=', ContentModel.dateTimeToTimestamp(inicio)],
          'eliminado': false,
        },
        orderBy: 'fechaInicio',
        descending: false,
        limit: 500,
      );
      final eventos = modelos.map((m) => m.toDomain()).toList();
      return eventos.where((e) => _eventoSeSolapaConRango(e, inicio, fin)).toList();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosPorUbicacion({String? departamento, String? municipio}) async {
    return await _handleExceptions(() async {
      final filters = <String, dynamic>{
        'eliminado': false,
      };
      if (departamento != null) {
        filters['ubicacion.departamento'] = departamento;
      }
      if (municipio != null) {
        filters['ubicacion.municipio'] = municipio;
      }
      final modelos = await _firestoreEventos.query(
        filters: filters,
        orderBy: 'fechaInicio',
        descending: false,
      );
      return modelos.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<void> guardarEvento(EventoCultural evento) async {
    return await _handleExceptions(() async {
      _validarEvento(evento);

      // Prevenir duplicados por título/fecha/lugar aproximado
      final similares = await buscarEventos(evento.titulo);
      for (final s in similares) {
        if (s.id == evento.id) continue;
        final mismoDia = _mismoDia(s.fechaInicio, evento.fechaInicio);
        final mismoLugar = s.ubicacion.departamento.toLowerCase() == evento.ubicacion.departamento.toLowerCase() &&
            s.ubicacion.municipio.toLowerCase() == evento.ubicacion.municipio.toLowerCase();
        if (mismoDia && mismoLugar && _similitudTitulos(evento.titulo, s.titulo) > 0.8) {
          throw EventoDuplicadoException('Ya existe un evento similar en esa fecha y lugar');
        }
      }

      // Subir multimedia y reemplazar URLs locales
      final imagenes = await _procesarImagenes(evento.imagenes, evento.id);
      final model = EventoCulturalModel.fromDomain(
        evento.copyWith(
          imagenes: imagenes,
        ),
      );
      await _firestoreEventos.save(model);
    });
  }

  @override
  Future<void> actualizarEvento(EventoCultural evento) async {
    return await _handleExceptions(() async {
      final existente = await _firestoreEventos.getById(evento.id);
      if (existente == null) {
        throw EventoNotFoundException('No se encontró el evento con ID ${evento.id}');
      }

      _validarEvento(evento);

      final imagenes = await _procesarImagenes(evento.imagenes, evento.id);
      final actualizado = evento.copyWith(
        imagenes: imagenes,
        fechaActualizacion: DateTime.now().toUtc(),
      );
      await _firestoreEventos.save(EventoCulturalModel.fromDomain(actualizado));
    });
  }

  @override
  Future<void> eliminarEvento(String id) async {
    return await _handleExceptions(() async {
      final model = await _firestoreEventos.getById(id);
      if (model == null) throw EventoNotFoundException('No se encontró el evento con ID $id');
      if (model.eliminado) throw EventoAlreadyDeletedException();

      final eliminado = model.toDomain().marcarEliminado();
      await _firestoreEventos.save(EventoCulturalModel.fromDomain(eliminado));
    });
  }

  @override
  Future<void> restaurarEvento(String id) async {
    return await _handleExceptions(() async {
      final model = await _firestoreEventos.getById(id);
      if (model == null) throw EventoNotFoundException('No se encontró el evento con ID $id');
      if (!model.eliminado) return;
      final restaurado = model.toDomain().restaurar();
      await _firestoreEventos.save(EventoCulturalModel.fromDomain(restaurado));
    });
  }

  @override
  Stream<List<EventoCultural>> observarEventos() {
    try {
      return _firestoreEventos.watchCollection(
        orderBy: 'fechaInicio',
        descending: false,
      ).map((docs) => docs
          .where((m) => !m.eliminado)
          .map((m) => m.toDomain())
          .toList());
    } catch (e) {
      throw EventoException('Error al observar eventos: $e');
    }
  }

  @override
  Stream<EventoCultural?> observarEventoPorId(String id) {
    try {
      return _firestoreEventos.watchDocument(id).map((m) => m?.toDomain());
    } catch (e) {
      throw EventoException('Error al observar evento: $e');
    }
  }

  @override
  Stream<List<EventoCultural>> observarEventosPorCategoria(String categoriaId) {
    try {
      return _firestoreEventos.watchWhere(
        field: 'categoriaId',
        isEqualTo: categoriaId,
        orderBy: 'fechaInicio',
        descending: false,
      ).map((docs) => docs
          .where((m) => !m.eliminado)
          .map((m) => m.toDomain())
          .toList());
    } catch (e) {
      throw EventoException('Error al observar eventos por categoría: $e');
    }
  }

  // -----------------------------
  // Sugerencias de eventos
  // -----------------------------

  @override
  Future<List<SugerenciaEvento>> obtenerSugerenciasPendientes() async {
    return await _handleExceptions(() async {
      debugPrint('[REPO_SUGERENCIAS] Consultando sugerencias pendientes...');
      final models = await _firestoreSugerencias.query(
        filters: {'estado': 'pendiente'},
        orderBy: 'fechaCreacion',
        descending: true,
        limit: 100,
      );
      debugPrint('[REPO_SUGERENCIAS] Encontrados ${models.length} documentos');
      for (int i = 0; i < models.length; i++) {
        debugPrint('[REPO_SUGERENCIAS][$i] id=${models[i].id} nombre="${models[i].nombre}" estado=${models[i].estado}');
      }
      final sugerencias = models.map((m) => m.toDomain()).toList();
      debugPrint('[REPO_SUGERENCIAS] Convertidas ${sugerencias.length} sugerencias a dominio');
      return sugerencias;
    });
  }

  @override
  Future<List<SugerenciaEvento>> obtenerSugerenciasPorUsuario(String usuarioId) async {
    return await _handleExceptions(() async {
      final models = await _firestoreSugerencias.query(
        filters: {
          'sugeridoPorId': usuarioId,
        },
        orderBy: 'fechaCreacion',
        descending: true,
        limit: 100,
      );
      return models.map((m) => m.toDomain()).toList();
    });
  }

  @override
  Future<SugerenciaEvento?> obtenerSugerenciaPorId(String id) async {
    return await _handleExceptions(() async {
      final model = await _firestoreSugerencias.getById(id);
      return model?.toDomain();
    });
  }

  @override
  Future<void> guardarSugerencia(SugerenciaEvento sugerencia) async {
    return await _handleExceptions(() async {
      // Validar ubicación Nicaragua
      _validarUbicacionNicaragua(sugerencia.ubicacion);
      // Guardar
      await _firestoreSugerencias.save(SugerenciaEventoModel.fromDomain(sugerencia));
    });
  }

  @override
  Future<void> aprobarSugerencia({
    required String sugerenciaId,
    required String adminId,
  }) async {
    return await _handleExceptions(() async {
      final sugerenciaModel = await _firestoreSugerencias.getById(sugerenciaId);
      if (sugerenciaModel == null) throw SugerenciaNotFoundException();
      final sugerencia = sugerenciaModel.toDomain();

      // Construir evento a partir de sugerencia
      // El autor del evento es quien lo sugirió, no el admin que lo aprobó
      final nuevoEvento = EventoCultural(
        id: sugerencia.eventoId ?? sugerencia.id,
        titulo: sugerencia.nombre,
        descripcion: sugerencia.descripcion,
        tipo: sugerencia.tipo,
        categoriaId: sugerencia.categoriaId,
        categoriaNombre: sugerencia.categoriaNombre,
        ubicacion: sugerencia.ubicacion,
        imagenes: sugerencia.imagenes,
        fechaInicio: sugerencia.fechaInicio,
        fechaFin: sugerencia.fechaFin,
        esRecurrente: sugerencia.esRecurrente,
        frecuencia: sugerencia.frecuencia,
        organizador: sugerencia.organizador,
        contacto: sugerencia.contacto,
        creadoPorId: sugerencia.sugeridoPorId,  // Autor original de la sugerencia
        creadoPorNombre: sugerencia.sugeridoPorNombre,  // Nombre del autor original
        fechaCreacion: DateTime.now().toUtc(),
        fechaActualizacion: DateTime.now().toUtc(),
      );

      // Guardar en transacción: crear evento y marcar sugerencia como aprobada
      await _firestoreEventos.runTransaction((tx) async {
        final eventoModel = EventoCulturalModel.fromDomain(nuevoEvento);
        tx.set(_firestoreEventos.collectionPath, eventoModel.id, eventoModel.toMap());

        final aprobada = sugerencia.copyWith(
          estado: EstadoSugerencia.aprobada,
          eventoId: eventoModel.id,
          fechaActualizacion: DateTime.now().toUtc(),
        );
        final sugModel = SugerenciaEventoModel.fromDomain(aprobada);
        tx.set(_firestoreSugerencias.collectionPath, sugModel.id, sugModel.toMap());
      });
    });
  }

  @override
  Future<void> rechazarSugerencia({
    required String sugerenciaId,
    required String razon,
    required String adminId,
  }) async {
    return await _handleExceptions(() async {
      final sugerenciaModel = await _firestoreSugerencias.getById(sugerenciaId);
      if (sugerenciaModel == null) throw SugerenciaNotFoundException();
      final rechazada = sugerenciaModel
          .toDomain()
          .copyWith(estado: EstadoSugerencia.rechazada, razonRechazo: razon, fechaActualizacion: DateTime.now().toUtc());
      await _firestoreSugerencias.save(SugerenciaEventoModel.fromDomain(rechazada));
    });
  }

  @override
  Stream<List<SugerenciaEvento>> observarSugerenciasPendientes() {
    try {
      return _firestoreSugerencias.watchWhere(
        field: 'estado',
        isEqualTo: 'pendiente',
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((docs) => docs.map((m) => m.toDomain()).toList());
    } catch (e) {
      throw EventoException('Error al observar sugerencias: $e');
    }
  }

  @override
  Stream<List<SugerenciaEvento>> observarSugerenciasPorUsuario(String usuarioId) {
    try {
      return _firestoreSugerencias.watchWhere(
        field: 'sugeridoPorId',
        isEqualTo: usuarioId,
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((docs) => docs.map((m) => m.toDomain()).toList());
    } catch (e) {
      throw EventoException('Error al observar sugerencias por usuario: $e');
    }
  }

  // -----------------------------
  // Búsquedas y proximidad
  // -----------------------------

  @override
  Future<List<EventoCultural>> buscarEventos(String texto) async {
    return await _handleExceptions(() async {
      final q = texto.toLowerCase().trim();
      if (q.isEmpty) return [];

      final docs = await _firestoreEventos.query(
        filters: {
          'eliminado': false,
        },
        orderBy: 'fechaCreacion',
        descending: true,
        limit: 200,
      );

      return docs
          .where((m) {
            final t = m.titulo.toLowerCase();
            final d = m.descripcion.toLowerCase();
            return t.contains(q) || d.contains(q);
          })
          .map((m) => m.toDomain())
          .toList();
    });
  }

  @override
  Future<List<EventoCultural>> obtenerEventosCercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    return await _handleExceptions(() async {
      // Obtener candidatos y filtrar por distancia en memoria (sin geohash en este repo)
      final docs = await _firestoreEventos.query(
        filters: {'eliminado': false},
        limit: 200,
      );
      final eventos = docs.map((m) => m.toDomain()).toList();
      final origen = Ubicacion(
        latitud: latitud,
        longitud: longitud,
        departamento: eventos.isEmpty ? 'Managua' : eventos.first.ubicacion.departamento,
        municipio: eventos.isEmpty ? 'Managua' : eventos.first.ubicacion.municipio,
      );
      return eventos.where((e) => origen.calcularDistanciaA(e.ubicacion) <= radioKm).toList();
    });
  }

  // -----------------------------
  // Helpers
  // -----------------------------

  void _validarEvento(EventoCultural e) {
    if (e.titulo.trim().isEmpty) {
      throw EventoInvalidContentException.fromValidation('El título no puede estar vacío');
    }
    if (e.descripcion.trim().isEmpty) {
      throw EventoInvalidContentException.fromValidation('La descripción no puede estar vacía');
    }
    if (e.fechaInicio.isAfter(e.fechaFin)) {
      throw EventoInvalidDateException.fechaInicioMayorQueFin();
    }
    _validarUbicacionNicaragua(e.ubicacion);
  }

  bool _mismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _validarUbicacionNicaragua(Ubicacion ubicacion) {
    // Usa el validador dentro del VO; si se creó, ya es válida. Aquí defensivo:
    if (ubicacion.latitud.isNaN || ubicacion.longitud.isNaN) {
      throw EventoLocationException.coordenadasInvalidas();
    }
  }

  Future<List<Multimedia>> _procesarImagenes(List<Multimedia> imagenes, String eventoId) async {
    if (imagenes.isEmpty) return imagenes;
    final List<Multimedia> procesadas = [];
    for (final img in imagenes) {
      if (img.url.startsWith('file://')) {
        final filePath = img.url.replaceFirst('file://', '');
        final file = File(filePath);
        if (!await file.exists()) {
          throw EventoMediaException.fromError('Archivo no encontrado: $filePath');
        }
        final ts = DateTime.now().millisecondsSinceEpoch;
        final nombre = 'img_${ts}_${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : ts}';
        final storagePath = '$_eventosStoragePath/$eventoId/$nombre';
        final url = await _storageDataSource.uploadFile(
          file: file,
          path: storagePath,
          contentType: null,
          metadata: {'eventoId': eventoId},
        );
        procesadas.add(Multimedia(url: url, tipo: img.tipo, descripcion: img.descripcion, orden: img.orden));
      } else {
        procesadas.add(img);
      }
    }
    return procesadas;
  }

  bool _eventoCoincideEnFecha(EventoCultural e, DateTime fecha) {
    // Dentro de rango
    final inRange = !fecha.isBefore(e.fechaInicio) && !fecha.isAfter(e.fechaFin);
    if (inRange) return true;
    // Recurrente anual: coincide si mes/día iguales a fecha dentro del rango anual
    if (e.esRecurrente && (e.frecuencia == 'anual' || (e.frecuencia ?? '').toLowerCase() == 'anual')) {
      return e.fechaInicio.month == fecha.month && e.fechaInicio.day == fecha.day;
    }
    return false;
  }

  bool _eventoSeSolapaConRango(EventoCultural e, DateTime inicio, DateTime fin) {
    final solapa = e.fechaInicio.isBefore(fin) && e.fechaFin.isAfter(inicio);
    if (solapa) return true;
    if (e.esRecurrente && (e.frecuencia == 'anual' || (e.frecuencia ?? '').toLowerCase() == 'anual')) {
      // Si el rango incluye el mes/día del evento en cualquier año, considerarlo
      for (DateTime d = DateTime.utc(inicio.year, inicio.month, inicio.day);
          !d.isAfter(fin);
          d = d.add(const Duration(days: 1))) {
        if (e.fechaInicio.month == d.month && e.fechaInicio.day == d.day) return true;
      }
    }
    return false;
  }

  double _similitudTitulos(String a, String b) {
    final s1 = a.toLowerCase().trim();
    final s2 = b.toLowerCase().trim();
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    // Distancia de Levenshtein simple normalizada
    final len1 = s1.length;
    final len2 = s2.length;
    final d = List.generate(len1 + 1, (i) => List<int>.filled(len2 + 1, 0));
    for (int i = 0; i <= len1; i++) d[i][0] = i;
    for (int j = 0; j <= len2; j++) d[0][j] = j;
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        final del = d[i - 1][j] + 1;
        final ins = d[i][j - 1] + 1;
        final sub = d[i - 1][j - 1] + cost;
        d[i][j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
    }
    final maxLen = len1 > len2 ? len1 : len2;
    return 1.0 - (d[len1][len2] / maxLen);
  }
}


