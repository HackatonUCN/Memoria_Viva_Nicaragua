import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exception.dart';
import '../../domain/entities/saber_popular.dart';
import '../../domain/enums/estado_moderacion.dart';
import '../../domain/exceptions/saber_exception.dart';
import '../../domain/repositories/saber_popular_repository.dart';
import '../../domain/value_objects/ubicacion.dart';
import '../../domain/enums/departamentos.dart';
import '../../domain/value_objects/multimedia.dart';
import '../../domain/aggregates/saber_popular_aggregate.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/firebase_storage_datasource.dart';
import '../models/content/saber_popular_model.dart';
import '../models/value_objects/ubicacion_model.dart';
import '../models/value_objects/multimedia_model.dart';

/// Implementación del repositorio de saberes populares con Firebase
class SaberPopularRepositoryImpl implements ISaberPopularRepository {
  /// Fuente de datos para Firestore
  final FirestoreDataSource<SaberPopularModel> _firestoreDataSource;
  
  /// Fuente de datos para Storage
  final FirebaseStorageDataSource _storageDataSource;
  
  /// Colección principal para saberes populares en Firestore
  static const String _saberesCollection = 'saberes_populares';
  
  /// Colección para comentarios de saberes populares
  static const String _comentariosCollection = 'comentarios';
  
  /// Colección para verificaciones de saberes populares
  static const String _verificacionesCollection = 'verificaciones';
  
  /// Ruta base para almacenamiento de multimedia de saberes populares
  static const String _saberesStoragePath = 'saberes_populares';
  
  /// Límite predeterminado para consultas paginadas
  static const int _defaultLimit = 20;
  
  /// Radio de búsqueda predeterminado en kilómetros
  static const double _defaultRadioKm = 10.0;

  /// Constructor principal
  SaberPopularRepositoryImpl({
    required FirestoreDataSource<SaberPopularModel> firestoreDataSource,
    required FirebaseStorageDataSource storageDataSource,
  })  : _firestoreDataSource = firestoreDataSource,
        _storageDataSource = storageDataSource;

  /// Maneja las excepciones de las fuentes de datos y las convierte a excepciones del dominio
  Future<T> _handleExceptions<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      throw SaberException(
        'Error en la base de datos: ${e.message}',
        code: e.code,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw SaberPermissionException('Permiso denegado: ${e.message}');
      }
      throw SaberException(
        'Error en Firebase: ${e.message}',
        code: e.code,
      );
    } on SocketException catch (e) {
      // Manejo específico para errores de conexión
      throw SaberException(
        'Error de conexión: ${e.message}. Verifica tu conexión a Internet.',
        code: 'connection-error',
      );
    } catch (e) {
      if (e is SaberException) rethrow;
      throw SaberException('Error inesperado: $e');
    }
  }

  @override
  Future<List<SaberPopular>> obtenerSaberes({int limit = _defaultLimit}) async {
    return await _handleExceptions(() async {
      // Construir la consulta base
      final filters = {
        'eliminado': false,
        'estado': EstadoModeracion.activo.value,
      };
      
      // Obtener los saberes limitando la cantidad
      final saberes = await _firestoreDataSource.query(
        filters: filters,
        orderBy: 'fechaCreacion',
        descending: true, // Más recientes primero
        limit: limit,
      );

      // Convertir modelos a entidades de dominio
      return saberes.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<SaberPopular?> obtenerSaberPorId(String id) async {
    return await _handleExceptions(() async {
      final saber = await _firestoreDataSource.getById(id);
      return saber?.toDomain();
    });
  }

  @override
  Future<List<SaberPopular>> obtenerSaberesPorCategoria(String categoriaId) async {
    return await _handleExceptions(() async {
      // Consultar saberes activos de una categoría específica
      final saberes = await _firestoreDataSource.query(
        filters: {
          'categoriaId': categoriaId,
          'eliminado': false,
          'estado': EstadoModeracion.activo.value,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return saberes.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<SaberPopular>> obtenerSaberesPorAutor(String autorId) async {
    return await _handleExceptions(() async {
      // Consultar saberes de un autor específico (incluye todos los estados para el autor)
      final saberes = await _firestoreDataSource.query(
        filters: {
          'autorId': autorId,
          'eliminado': false,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return saberes.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<SaberPopular>> obtenerSaberesPorUbicacion({String? departamento, String? municipio}) async {
    return await _handleExceptions(() async {
      // Preparar filtros según los parámetros proporcionados
      final filters = <String, dynamic>{
        'eliminado': false,
        'estado': EstadoModeracion.activo.value,
      };
      
      // Aplicar filtros de ubicación si se proporcionan
      if (departamento != null) {
        filters['ubicacion.departamento'] = departamento;
      }
      
      if (municipio != null) {
        filters['ubicacion.municipio'] = municipio;
      }
      
      // Consultar saberes con los filtros aplicados
      final saberes = await _firestoreDataSource.query(
        filters: filters,
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return saberes.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<void> guardarSaber(SaberPopular saber) async {
    await _handleExceptions(() async {
      // Verificar si ya existe un saber similar para evitar duplicados
      // Si no hay permisos de lectura (permission-denied), continuar sin bloquear la creación
      List<SaberPopular> saberesSimilares = const [];
      try {
        saberesSimilares = await buscarSaberesSimilares(
          titulo: saber.titulo,
          categoriaId: saber.categoriaId,
        );
      } catch (_) {
        // ignore: avoid_print
        print('[SABER_REPO][DUP_CHECK_SKIPPED] read-permission denied or error. Continuing with save.');
      }
      if (saberesSimilares.isNotEmpty) {
        throw SaberDuplicadoException('Ya existe un saber similar con el título "${saber.titulo}" en la misma categoría.');
      }
      
      // Validar la ubicación si se proporciona
      if (saber.ubicacion != null) {
        _validarUbicacionNicaragua(saber.ubicacion!);
      }
      
      // Procesar y validar multimedia
      final multimediaProcesada = await _procesarMultimedia(saber.multimedia, saber.id);
      
      // Crear el modelo para guardar
      final saberModel = SaberPopularModel.fromDomain(
        saber.copyWith(imagenes: multimediaProcesada),
      );
      
      // Guardar en Firestore
      await _firestoreDataSource.save(saberModel);
    });
  }

  @override
  Future<void> actualizarSaber(SaberPopular saber) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saberExistente = await _firestoreDataSource.getById(saber.id);
      if (saberExistente == null) {
        throw SaberNotFoundException('No se encontró el saber con ID ${saber.id}');
      }
      
      // Verificar si está eliminado
      if (saberExistente.eliminado) {
        throw SaberAlreadyDeletedException('El saber ya fue eliminado y no puede ser actualizado');
      }
      
      // Validar la ubicación si se proporciona
      if (saber.ubicacion != null) {
        _validarUbicacionNicaragua(saber.ubicacion!);
      }
      
      // Procesar y validar multimedia
      final multimediaProcesada = await _procesarMultimedia(saber.multimedia, saber.id);
      
      // Crear el modelo para actualizar
      final saberModel = SaberPopularModel.fromDomain(
        saber.copyWith(
          imagenes: multimediaProcesada,
          fechaActualizacion: DateTime.now().toUtc(),
        ),
      );
      
      // Actualizar en Firestore
      await _firestoreDataSource.save(saberModel);
    });
  }

  @override
  Future<void> eliminarSaber(String id) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar si ya está eliminado
      if (saber.eliminado) {
        throw SaberAlreadyDeletedException('El saber ya fue eliminado');
      }
      
      // Realizar soft delete
      final saberEliminado = saber.toDomain().marcarEliminado();
      final saberModel = SaberPopularModel.fromDomain(saberEliminado);
      
      await _firestoreDataSource.save(saberModel);
    });
  }

  @override
  Future<void> restaurarSaber(String id) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar que está eliminado
      if (!saber.eliminado) {
        throw SaberNotDeletedException('El saber no está eliminado');
      }
      
      // Restaurar el saber
      final saberRestaurado = saber.toDomain().restaurar();
      final saberModel = SaberPopularModel.fromDomain(saberRestaurado);
      
      await _firestoreDataSource.save(saberModel);
    });
  }

  @override
  Future<void> reportarSaber(String id, String razon) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar si está eliminado
      if (saber.eliminado) {
        throw SaberAlreadyDeletedException('El saber ya fue eliminado y no puede ser reportado');
      }
      
      // Incrementar contador de reportes y cambiar estado si es necesario
      final saberReportado = saber.toDomain().reportar();
      final saberModel = SaberPopularModel.fromDomain(saberReportado);
      
      // Guardar el reporte en una subcolección (opcional)
      final reporteData = {
        'saberId': id,
        'razon': razon,
        'fechaReporte': FieldValue.serverTimestamp(),
      };
      
      // Actualizar el saber y guardar el reporte
      await _firestoreDataSource.save(saberModel);
      
      // Aquí se podría guardar el reporte en una subcolección específica
    });
  }

  @override
  Future<void> moderarSaber(String id, EstadoModeracion estado) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar si está eliminado
      if (saber.eliminado) {
        throw SaberAlreadyDeletedException('El saber ya fue eliminado y no puede ser moderado');
      }
      
      // Actualizar estado de moderación
      final saberModerado = saber.toDomain().moderar(
        aprobar: estado == EstadoModeracion.activo,
      );
      final saberModel = SaberPopularModel.fromDomain(saberModerado);
      
      await _firestoreDataSource.save(saberModel);
    });
  }

  @override
  Future<void> darLike(String id) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar si está eliminado o no activo
      if (saber.eliminado || saber.estado != 'activo') {
        throw SaberException('No se puede dar like a un saber que no está activo');
      }
      
      // Incrementar contador de likes
      await _firestoreDataSource.update(
        id: id,
        data: {
          'likes': FieldValue.increment(1),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  @override
  Future<void> registrarCompartido(String id) async {
    await _handleExceptions(() async {
      // Verificar que el saber existe
      final saber = await _firestoreDataSource.getById(id);
      if (saber == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Verificar si está eliminado o no activo
      if (saber.eliminado || saber.estado != 'activo') {
        throw SaberException('No se puede compartir un saber que no está activo');
      }
      
      // Incrementar contador de compartidos
      await _firestoreDataSource.update(
        id: id,
        data: {
          'compartidos': FieldValue.increment(1),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  @override
  Stream<List<SaberPopular>> observarSaberes() {
    try {
      // Importante: incluir todos los filtros exigidos por reglas (estado activo y eliminado=false)
      return _firestoreDataSource.watchQuery(
        filters: {
          'estado': EstadoModeracion.activo.value,
          'eliminado': false,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((saberes) => saberes.map((model) => model.toDomain()).toList());
    } catch (e) {
      throw SaberException('Error al observar saberes: $e');
    }
  }

  @override
  Stream<SaberPopular?> observarSaberPorId(String id) { try {
      return _firestoreDataSource.watchDocument(id)
          .map((saber) => saber?.toDomain());
    } catch (e) {
      throw SaberException('Error al observar el saber: $e');
    }
  }

  @override
  Stream<List<SaberPopular>> observarSaberesPorCategoria(String categoriaId) {
    try {
      // Incluir filtros requeridos por reglas además de categoría
      return _firestoreDataSource.watchQuery(
        filters: {
          'categoriaId': categoriaId,
          'estado': EstadoModeracion.activo.value,
          'eliminado': false,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((saberes) => saberes.map((model) => model.toDomain()).toList());
    } catch (e) {
      throw SaberException('Error al observar saberes por categoría: $e');
    }
  }

  @override
  Future<List<SaberPopular>> buscarSaberes(String texto) async {
    return await _handleExceptions(() async {
      // Dividir el texto de búsqueda en palabras clave
      final keywords = texto.toLowerCase().split(' ')
          .where((word) => word.trim().isNotEmpty)
          .toList();
      
      if (keywords.isEmpty) {
        return [];
      }
      
      // Traer candidatos (activos y no eliminados)
      final candidatos = await _firestoreDataSource.query(
        filters: {
          'eliminado': false,
          'estado': EstadoModeracion.activo.value,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      // Filtrar resultados que contengan keywords en título, contenido, etiquetas o nombre/id de categoría
      final resultados = candidatos.where((saber) {
        final String tituloLower = saber.titulo.toLowerCase();
        final String contenidoLower = saber.contenido.toLowerCase();
        final List<String> etiquetasLower = (saber.etiquetas).map((e) => e.toLowerCase()).toList();
        final String catNombreLower = (saber.categoriaNombre).toLowerCase();
        final String catIdLower = (saber.categoriaId).toLowerCase();
        
        return keywords.any((k) =>
          tituloLower.contains(k) ||
          contenidoLower.contains(k) ||
          etiquetasLower.any((et) => et.contains(k)) ||
          catNombreLower.contains(k) ||
          catIdLower.contains(k)
        );
      }).toList();
      
      // Convertir a entidades de dominio
      return resultados.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<SaberPopular>> buscarSaberesSimilares({
    required String titulo,
    required String categoriaId,
  }) async {
    return await _handleExceptions(() async {
      // Normalizar el título para la búsqueda
      final tituloNormalizado = titulo.toLowerCase().trim();
      
      // Buscar saberes en la misma categoría
      final saberesMismaCategoria = await _firestoreDataSource.query(
        filters: {
          'categoriaId': categoriaId,
          'eliminado': false,
        },
      );
      
      // Filtrar por similitud en el título
      final saberesSimilares = saberesMismaCategoria.where((saber) {
        final similaridad = _calcularSimilitudTexto(
          saber.titulo.toLowerCase(),
          tituloNormalizado,
        );
        
        // Considerar similar si la similitud es mayor al 70%
        return similaridad > 0.7;
      }).toList();
      
      return saberesSimilares.map((model) => model.toDomain()).toList();
    });
  }

  /// Calcula la similitud entre dos textos (implementación simple)
  double _calcularSimilitudTexto(String texto1, String texto2) {
    if (texto1 == texto2) return 1.0;
    if (texto1.isEmpty || texto2.isEmpty) return 0.0;
    
    // Dividir en palabras
    final palabras1 = texto1.split(' ').where((p) => p.isNotEmpty).toSet();
    final palabras2 = texto2.split(' ').where((p) => p.isNotEmpty).toSet();
    
    // Calcular intersección
    final interseccion = palabras1.intersection(palabras2).length;
    final union = palabras1.union(palabras2).length;
    
    // Índice Jaccard
    return union > 0 ? interseccion / union : 0.0;
  }

  /// Valida que la ubicación esté dentro de Nicaragua
  void _validarUbicacionNicaragua(Ubicacion ubicacion) {
    // Coordenadas aproximadas de Nicaragua
    const double minLat = 10.7;
    const double maxLat = 15.0;
    const double minLng = -87.7;
    const double maxLng = -83.1;
    
    // Validar coordenadas
    if (ubicacion.latitud < minLat || ubicacion.latitud > maxLat ||
        ubicacion.longitud < minLng || ubicacion.longitud > maxLng) {
      throw SaberLocationException.coordenadasInvalidas();
    }
    
    // Validar que el departamento sea válido (aceptando alias y siglas RACCN/RACCS)
    if (ubicacion.departamento != null) {
      final String dep = ubicacion.departamento!;
      final bool valido = tryDepartamentoFromString(dep) != null || dep.trim().toLowerCase() == 'nicaragua';
      if (!valido) {
        throw SaberLocationException(
          'El departamento ${ubicacion.departamento} no es válido en Nicaragua',
          code: 'DEPARTAMENTO_INVALIDO',
        );
      }
    }
  }

  /// Procesa multimedia del saber popular (imagen, audio, video, documento)
  Future<List<Multimedia>> _procesarMultimedia(List<Multimedia> items, String saberId) async {
    if (items.isEmpty) return items;
    final List<Multimedia> procesadas = [];
    
    for (final item in items) {
      // Mantener URLs ya subidas
      if (item.url.startsWith('http')) {
        procesadas.add(item);
        continue;
      }

      if (item.url.startsWith('file://')) {
        final file = File(item.url.replaceFirst('file://', ''));
        final fileSize = await file.length();
        
        // Límites por tipo
        String contentType;
        String prefix;
        int maxSize;
        switch (item.tipo) {
          case TipoMultimedia.imagen:
            contentType = 'image/jpeg';
            prefix = 'img_';
            maxSize = 5 * 1024 * 1024; // 5MB
            break;
          case TipoMultimedia.audio:
            contentType = 'audio/mpeg';
            prefix = 'aud_';
            maxSize = 20 * 1024 * 1024; // 20MB
            break;
          case TipoMultimedia.video:
            contentType = 'video/mp4';
            prefix = 'vid_';
            maxSize = 100 * 1024 * 1024; // 100MB
            break;
          case TipoMultimedia.documento:
            contentType = 'application/octet-stream';
            prefix = 'doc_';
            maxSize = 20 * 1024 * 1024; // 20MB
            break;
        }

        if (fileSize > maxSize) {
          throw SaberMediaException.tamanoExcedido(item.url);
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final nombreArchivo = '${prefix}${timestamp}_${procesadas.length}';
        final path = '$_saberesStoragePath/$saberId/$nombreArchivo';

        final url = await _storageDataSource.uploadFile(
          file: file,
          path: path,
          contentType: contentType,
          metadata: {
            'saberId': saberId,
            'timestamp': timestamp.toString(),
            'tipo': item.tipo.value,
          },
        );

        procesadas.add(Multimedia(
          url: url,
          tipo: item.tipo,
          descripcion: item.descripcion,
          orden: item.orden,
        ));
      } else {
        throw SaberMediaException.formatoInvalido(item.url);
      }
    }
    return procesadas;
  }

  /// Obtiene un agregado completo de saber popular
  Future<SaberPopularAggregate> _obtenerAgregado(String id) async {
    return await _handleExceptions(() async {
      // Obtener el saber
      final saberModel = await _firestoreDataSource.getById(id);
      if (saberModel == null) {
        throw SaberNotFoundException('No se encontró el saber con ID $id');
      }
      
      // Convertir a entidad de dominio
      final saber = saberModel.toDomain();
      
      // Obtener comentarios
      final comentarios = await _obtenerComentarios(id);
      
      // Obtener verificaciones
      final verificaciones = await _obtenerVerificaciones(id);
      
      // Crear y devolver el agregado
      return SaberPopularAggregate(saber, comentarios, verificaciones);
    });
  }

  /// Obtiene los comentarios de un saber popular
  Future<List<ComentarioSaber>> _obtenerComentarios(String saberId) async {
    try {
      // Implementación específica para obtener comentarios de Firestore
      // Esto dependerá de la estructura de datos y cómo se almacenan los comentarios
      final comentariosData = await FirebaseFirestore.instance
          .collection('$_saberesCollection/$saberId/$_comentariosCollection')
          .where('eliminado', isEqualTo: false)
          .orderBy('fechaCreacion', descending: true)
          .get();
      
      return comentariosData.docs
          .map((doc) => ComentarioSaber.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // En caso de error, devolver lista vacía
      return [];
    }
  }

  /// Obtiene las verificaciones de un saber popular
  Future<List<VerificacionSaber>> _obtenerVerificaciones(String saberId) async {
    try {
      // Implementación específica para obtener verificaciones de Firestore
      final verificacionesData = await FirebaseFirestore.instance
          .collection('$_saberesCollection/$saberId/$_verificacionesCollection')
          .orderBy('fechaVerificacion', descending: true)
          .get();
      
      return verificacionesData.docs
          .map((doc) => VerificacionSaber.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // En caso de error, devolver lista vacía
      return [];
    }
  }

  /// Guarda un agregado completo de saber popular
  Future<void> _guardarAgregado(SaberPopularAggregate agregado) async {
    await _handleExceptions(() async {
      // Obtener el saber del agregado
      final saber = agregado.saber;
      
      // Convertir a modelo
      final saberModel = SaberPopularModel.fromDomain(saber);
      
      // Guardar el saber
      await _firestoreDataSource.save(saberModel);
      
      // Procesar eventos del agregado
      final eventos = agregado.obtenerYLimpiarEventos();
      
      // Aquí se podrían procesar los eventos para realizar acciones adicionales
      // como enviar notificaciones, actualizar contadores, etc.
    });
  }
}
