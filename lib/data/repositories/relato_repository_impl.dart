import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/exception.dart';
import '../../domain/entities/relato.dart';
import '../../domain/enums/estado_moderacion.dart';
import '../../domain/exceptions/relato_exception.dart';
import '../../domain/repositories/relato_repository.dart';
import '../../domain/value_objects/ubicacion.dart';
import '../../domain/value_objects/multimedia.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/firebase_storage_datasource.dart';
import '../models/content/relato_model.dart';
import '../models/value_objects/ubicacion_model.dart';
import '../models/value_objects/multimedia_model.dart';

/// Implementación del repositorio de relatos con Firebase
class RelatoRepositoryImpl implements IRelatoRepository {
  /// Fuente de datos para Firestore
  final FirestoreDataSource<RelatoModel> _firestoreDataSource;
  
  /// Fuente de datos para Storage
  final FirebaseStorageDataSource _storageDataSource;
  
  /// Colección principal para relatos en Firestore
  static const String _relatosCollection = 'relatos';
  
  /// Ruta base para almacenamiento de multimedia de relatos
  static const String _relatosStoragePath = 'relatos';
  
  /// Límite predeterminado para consultas paginadas
  static const int _defaultLimit = 20;
  
  /// Radio de búsqueda predeterminado en kilómetros
  static const double _defaultRadioKm = 10.0;

  /// Constructor principal
  RelatoRepositoryImpl({
    required FirestoreDataSource<RelatoModel> firestoreDataSource,
    required FirebaseStorageDataSource storageDataSource,
  })  : _firestoreDataSource = firestoreDataSource,
        _storageDataSource = storageDataSource;

  /// Maneja las excepciones de las fuentes de datos y las convierte a excepciones del dominio
  Future<T> _handleExceptions<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      throw RelatoException(
        'Error en la base de datos: ${e.message}',
        code: e.code,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw RelatoPermissionException('Permiso denegado: ${e.message}');
      }
      throw RelatoException(
        'Error en Firebase: ${e.message}',
        code: e.code,
      );
    } on SocketException catch (e) {
      // Manejo específico para errores de conexión
      throw RelatoException(
        'Error de conexión: ${e.message}. Verifica tu conexión a Internet.',
        code: 'connection-error',
      );
    } catch (e) {
      if (e is RelatoException) rethrow;
      throw RelatoException('Error inesperado: $e');
    }
  }

  @override
  Future<List<Relato>> obtenerRelatos({int limit = _defaultLimit, int? lastIndex}) async {
    return await _handleExceptions(() async {
      // Construir la consulta base
      final filters = {
        'eliminado': false,
        'estado': EstadoModeracion.activo.value,
      };
      
      // Obtener los relatos limitando la cantidad
      final relatos = await _firestoreDataSource.query(
        filters: filters,
        orderBy: 'fechaCreacion',
        descending: true, // Más recientes primero
        limit: limit,
      );

      // Convertir modelos a entidades de dominio
      return relatos.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<Relato?> obtenerRelatoPorId(String id) async {
    return await _handleExceptions(() async {
      final relato = await _firestoreDataSource.getById(id);
      return relato?.toDomain();
    });
  }

  @override
  Future<List<Relato>> obtenerRelatosPorCategoria(String categoriaId) async {
    return await _handleExceptions(() async {
      // Consultar relatos activos de una categoría específica
      final relatos = await _firestoreDataSource.query(
        filters: {
          'categoriaId': categoriaId,
          'eliminado': false,
          'estado': EstadoModeracion.activo.value,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return relatos.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<Relato>> obtenerRelatosPorAutor(String autorId) async {
    return await _handleExceptions(() async {
      // Consultar relatos de un autor específico (incluye todos los estados para el autor)
      final relatos = await _firestoreDataSource.query(
        filters: {
          'autorId': autorId,
          'eliminado': false,
        },
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return relatos.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<List<Relato>> obtenerRelatosPorUbicacion({String? departamento, String? municipio}) async {
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
      
      // Realizar la consulta
      final relatos = await _firestoreDataSource.query(
        filters: filters,
        orderBy: 'fechaCreacion',
        descending: true,
      );
      
      return relatos.map((model) => model.toDomain()).toList();
    });
  }

  @override
  Future<void> guardarRelato(Relato relato) async {
    return await _handleExceptions(() async {
      // Validar el relato antes de guardarlo
      _validarRelato(relato);
      
      // Verificar si ya existe un relato similar (título similar del mismo autor)
      final similares = await buscarRelatosSimilares(
        titulo: relato.titulo,
        autorId: relato.autorId,
      );
      
      // Si hay relatos con título similar del mismo autor, considerarlo posible duplicado
      if (similares.isNotEmpty) {
        for (final similar in similares) {
          // Ignorar el mismo relato (para actualizaciones)
          if (similar.id == relato.id) continue;
          
          // Calcular similitud del título usando la distancia de Levenshtein
          final similitud = _calcularSimilitudTitulos(relato.titulo, similar.titulo);
          if (similitud > 0.8) {
            throw RelatoException(
              'Ya existe un relato con un título muy similar',
              code: 'possible-duplicate',
              value: similar.id,
            );
          }
        }
      }
      
      // Subir archivos multimedia si hay nuevos
      final multimedia = await _procesarMultimedia(relato);
      
      // Crear el modelo con la multimedia actualizada
      final relatoConMultimedia = relato.copyWith(
        multimedia: multimedia ?? relato.multimedia,
      );
      
      // Convertir a modelo y guardar en Firestore
      final relatoModel = RelatoModel.fromDomain(relatoConMultimedia);
      await _firestoreDataSource.save(relatoModel);
    });
  }

  @override
  Future<void> actualizarRelato(Relato relato) async {
    return await _handleExceptions(() async {
      // Verificar que el relato exista
      final existente = await _firestoreDataSource.getById(relato.id);
      if (existente == null) {
        throw RelatoNotFoundException('No se encontró el relato con ID ${relato.id}');
      }
      
      // Validar el relato
      _validarRelato(relato);
      
      // Subir archivos multimedia si hay nuevos
      final multimedia = await _procesarMultimedia(relato);
      
      // Crear el modelo con la multimedia actualizada y la fecha de actualización
      final relatoActualizado = relato.copyWith(
        multimedia: multimedia ?? relato.multimedia,
        fechaActualizacion: DateTime.now().toUtc(),
      );
      
      // Convertir a modelo y guardar
      final relatoModel = RelatoModel.fromDomain(relatoActualizado);
      await _firestoreDataSource.save(relatoModel);
    });
  }

  @override
  Future<void> eliminarRelato(String id) async {
    return await _handleExceptions(() async {
      // Verificar que el relato exista
      final relatoModel = await _firestoreDataSource.getById(id);
      if (relatoModel == null) {
        throw RelatoNotFoundException('No se encontró el relato con ID $id');
      }
      
      // Si ya está eliminado, lanzar excepción
      if (relatoModel.eliminado) {
        throw RelatoAlreadyDeletedException();
      }
      
      // Convertir a entidad, marcar como eliminado y volver a convertir a modelo
      final relato = relatoModel.toDomain().marcarEliminado();
      final actualizadoModel = RelatoModel.fromDomain(relato);
      
      // Guardar cambios
      await _firestoreDataSource.save(actualizadoModel);
    });
  }

  @override
  Future<void> restaurarRelato(String id) async {
    return await _handleExceptions(() async {
      // Verificar que el relato exista
      final relatoModel = await _firestoreDataSource.getById(id);
      if (relatoModel == null) {
        throw RelatoNotFoundException('No se encontró el relato con ID $id');
      }
      
      // Si no está eliminado, no hay nada que restaurar
      if (!relatoModel.eliminado) {
        return;
      }
      
      // Convertir a entidad, restaurar y volver a convertir a modelo
      final relato = relatoModel.toDomain().restaurar();
      final actualizadoModel = RelatoModel.fromDomain(relato);
      
      // Guardar cambios
      await _firestoreDataSource.save(actualizadoModel);
    });
  }

  @override
  Future<void> reportarRelato(String id, String razon) async {
    return await _handleExceptions(() async {
      // Verificar que el relato exista
      final relatoModel = await _firestoreDataSource.getById(id);
      if (relatoModel == null) {
        throw RelatoNotFoundException('No se encontró el relato con ID $id');
      }
      
      // Incrementar conteo de reportes y cambiar estado
      final relato = relatoModel.toDomain().reportar();
      
      // Guardar el reporte en una subcolección para revisión
      final reporteData = {
        'relatoId': id,
        'razon': razon,
        'fecha': FieldValue.serverTimestamp(),
        'procesado': false,
      };
      
      // Crear transacción para actualizar relato y guardar reporte
      await _firestoreDataSource.runTransaction((transaction) async {
        // Actualizar el relato
        final relatoActualizadoModel = RelatoModel.fromDomain(relato);
        transaction.set(_firestoreDataSource.collectionPath, id, relatoActualizadoModel.toMap());
        
        // Crear un ID único para el reporte
        final reporteId = '${id}_${DateTime.now().millisecondsSinceEpoch}';
        
        // Guardar el reporte en subcolección
        transaction.set('${_firestoreDataSource.collectionPath}/$id/reportes', reporteId, reporteData);
      });
    });
  }

  @override
  Future<void> moderarRelato(String id, EstadoModeracion estado) async {
    return await _handleExceptions(() async {
      // Verificar que el relato exista
      final relatoModel = await _firestoreDataSource.getById(id);
      if (relatoModel == null) {
        throw RelatoNotFoundException('No se encontró el relato con ID $id');
      }
      
      // Validar estado de moderación
      if (estado != EstadoModeracion.activo && 
          estado != EstadoModeracion.oculto && 
          estado != EstadoModeracion.pendiente) {
        throw RelatoModerationException.estadoInvalido(estado.value);
      }
      
      // Actualizar estado de moderación
      final relato = relatoModel.toDomain().moderar(aprobar: estado == EstadoModeracion.activo);
      
      // Actualizar con transacción para marcar también los reportes como procesados
      await _firestoreDataSource.runTransaction((transaction) async {
        // Actualizar el relato
        final relatoActualizadoModel = RelatoModel.fromDomain(relato);
        transaction.set(_firestoreDataSource.collectionPath, id, relatoActualizadoModel.toMap());
        
                 // Actualizar reportes como procesados
         // Nota: En una implementación real, se obtendría primero la lista de reportes
         transaction.update('${_firestoreDataSource.collectionPath}/$id/reportes', 'reporte_${DateTime.now().millisecondsSinceEpoch}', {'procesado': true});
      });
    });
  }

  @override
  Future<void> darLike(String id) async {
    return await _handleExceptions(() async {
      // Usar update con incremento atómico de Firestore
      await _firestoreDataSource.update(
        id: id, 
        data: {'likes': FieldValue.increment(1)},
      );
    });
  }

  @override
  Future<void> registrarCompartido(String id) async {
    return await _handleExceptions(() async {
      // Usar update con incremento atómico de Firestore
      await _firestoreDataSource.update(
        id: id, 
        data: {'compartidos': FieldValue.increment(1)},
      );
    });
  }

  @override
  Stream<List<Relato>> observarRelatos() {
    try {
      // Filtrar solo relatos activos y no eliminados
      return _firestoreDataSource.watchWhere(
        field: 'eliminado',
        isEqualTo: false,
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((relatos) {
        // Filtrar por estado activo en memoria
        return relatos
            .where((r) => r.estado == EstadoModeracion.activo.value)
            .map((model) => model.toDomain())
            .toList();
      });
    } catch (e) {
      throw RelatoException('Error al observar relatos: $e');
    }
  }

  @override
  Stream<Relato?> observarRelatoPorId(String id) {
    try {
      return _firestoreDataSource.watchDocument(id)
          .map((model) => model?.toDomain());
    } catch (e) {
      throw RelatoException('Error al observar relato: $e');
    }
  }

  @override
  Stream<List<Relato>> observarRelatosPorCategoria(String categoriaId) {
    try {
      return _firestoreDataSource.watchWhere(
        field: 'categoriaId',
        isEqualTo: categoriaId,
        orderBy: 'fechaCreacion',
        descending: true,
      ).map((relatos) {
        // Filtrar en memoria los relatos activos y no eliminados
        return relatos
            .where((r) => !r.eliminado && r.estado == EstadoModeracion.activo.value)
            .map((model) => model.toDomain())
            .toList();
      });
    } catch (e) {
      throw RelatoException('Error al observar relatos por categoría: $e');
    }
  }

  @override
  Future<List<Relato>> buscarRelatos(String texto) async {
    return await _handleExceptions(() async {
      // Normalizar texto de búsqueda (convertir a minúsculas)
      final textoBusqueda = texto.toLowerCase().trim();
      if (textoBusqueda.isEmpty) {
        return [];
      }
      
      // Implementar búsqueda por título, contenido y etiquetas
      // Nota: Una búsqueda completa requeriría Algolia o Firebase Extensions para búsqueda de texto
      
      // 1. Buscar en títulos (más exacto)
      final relatosPorTitulo = await _firestoreDataSource.query(
        filters: {
          'eliminado': false,
          'estado': EstadoModeracion.activo.value,
          // Búsqueda de contención no está disponible directamente en Firestore
          // Se implementa una aproximación con filtros de igualdad
        },
        limit: 50, // Límite mayor para filtrar en memoria después
      );
      
      // 2. Filtrar resultados en memoria para implementar búsqueda de texto
      final resultados = relatosPorTitulo
          .where((r) {
            final tituloLower = r.titulo.toLowerCase();
            final contenidoLower = r.contenido.toLowerCase();
            final etiquetasLower = r.etiquetas.map((e) => e.toLowerCase()).join(' ');
            
            return tituloLower.contains(textoBusqueda) ||
                   contenidoLower.contains(textoBusqueda) ||
                   etiquetasLower.contains(textoBusqueda);
          })
          .map((model) => model.toDomain())
          .toList();
      
      return resultados;
    });
  }

  @override
  Future<List<Relato>> obtenerRelatosCercanos({
    required double latitud,
    required double longitud,
    required double radioKm,
  }) async {
    return await _handleExceptions(() async {
      // Validar coordenadas
      if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
        throw RelatoLocationException.coordenadasInvalidas();
      }
      
      // Calcular límites aproximados para reducir resultados
      final radio = radioKm > 0 ? radioKm : _defaultRadioKm;
      final aproxGrados = radio / 111.0; // Aproximación: 1 grado ~= 111 km
      
      // Obtener todos los relatos con ubicación
      final relatos = await _firestoreDataSource.query(
        filters: {
          'eliminado': false,
          'estado': EstadoModeracion.activo.value,
        },
        limit: 100, // Límite mayor para filtrar por distancia después
      );
      
      // Filtrar por distancia en memoria
      final List<Relato> relatosCercanos = [];
      for (final model in relatos) {
        final relato = model.toDomain();
        if (relato.ubicacion != null) {
          // Verificar si está dentro del área aproximada
          final double lat = relato.ubicacion!.latitud;
          final double lng = relato.ubicacion!.longitud;
          
          // Filtro rápido por caja
          if (lat > latitud - aproxGrados &&
              lat < latitud + aproxGrados &&
              lng > longitud - aproxGrados &&
              lng < longitud + aproxGrados) {
            
            // Calcular distancia precisa
            final distancia = _calcularDistanciaKm(
              lat1: latitud,
              lon1: longitud,
              lat2: lat,
              lon2: lng,
            );
            
            // Si está dentro del radio, agregar al resultado
            if (distancia <= radio) {
              relatosCercanos.add(relato);
            }
          }
        }
      }
      
      return relatosCercanos;
    });
  }

  @override
  Future<List<Relato>> buscarRelatosSimilares({
    required String titulo,
    required String autorId,
  }) async {
    return await _handleExceptions(() async {
      // Buscar por autor
      final relatosAutor = await _firestoreDataSource.getWhere(
        field: 'autorId',
        isEqualTo: autorId,
      );
      
      // Filtrar por similitud de título en memoria
      final tituloNormalizado = titulo.toLowerCase().trim();
      if (tituloNormalizado.isEmpty) {
        return [];
      }
      
      final similares = relatosAutor
          .where((model) {
            // Calcular similitud
            final similitud = _calcularSimilitudTitulos(
              tituloNormalizado, 
              model.titulo.toLowerCase().trim(),
            );
            // Considerar similar si la similitud es alta
            return similitud > 0.6;
          })
          .map((model) => model.toDomain())
          .toList();
      
      return similares;
    });
  }

  /// Valida un relato antes de guardarlo
  void _validarRelato(Relato relato) {
    // Validar título
    if (relato.titulo.trim().isEmpty) {
      throw RelatoInvalidContentException.tituloInvalido('El título no puede estar vacío');
    }
    
    if (relato.titulo.length < 3 || relato.titulo.length > 100) {
      throw RelatoInvalidContentException.tituloInvalido(
        'El título debe tener entre 3 y 100 caracteres'
      );
    }
    
    // Validar contenido
    if (relato.contenido.trim().isEmpty) {
      throw RelatoInvalidContentException.contenidoInvalido('El contenido no puede estar vacío');
    }
    
    if (relato.contenido.length < 10) {
      throw RelatoInvalidContentException.contenidoInvalido(
        'El contenido debe tener al menos 10 caracteres'
      );
    }
    
    // Validar etiquetas
    if (relato.etiquetas.length > 10) {
      throw RelatoInvalidContentException.etiquetasInvalidas(
        'No se permiten más de 10 etiquetas'
      );
    }
    
    for (final etiqueta in relato.etiquetas) {
      if (etiqueta.trim().isEmpty) {
        throw RelatoInvalidContentException.etiquetasInvalidas(
          'Las etiquetas no pueden estar vacías'
        );
      }
      
      if (etiqueta.length > 30) {
        throw RelatoInvalidContentException.etiquetasInvalidas(
          'Las etiquetas no pueden tener más de 30 caracteres'
        );
      }
    }
    
    // Validar ubicación si está presente
    if (relato.ubicacion != null) {
      final ubicacion = relato.ubicacion!;
      
      if (ubicacion.latitud < -90 || ubicacion.latitud > 90) {
        throw RelatoLocationException.coordenadasInvalidas();
      }
      
      if (ubicacion.longitud < -180 || ubicacion.longitud > 180) {
        throw RelatoLocationException.coordenadasInvalidas();
      }
    }
    
    // Validar multimedia
    if (relato.multimedia.length > 10) {
      throw RelatoMediaException.limiteExcedido();
    }
    
    for (final media in relato.multimedia) {
      // Validar URLs o archivos locales
      if (media.url.trim().isEmpty) {
        throw RelatoMediaException.fromError('URL de multimedia vacía');
      }
      
             // Validar tipos permitidos
       if (media.tipo != TipoMultimedia.imagen && 
           media.tipo != TipoMultimedia.audio && 
           media.tipo != TipoMultimedia.video) {
         throw RelatoMediaException.formatoInvalido(media.url);
       }
    }
  }

  /// Procesa los archivos multimedia de un relato
  /// Sube archivos nuevos y retorna la lista actualizada
  Future<List<Multimedia>?> _procesarMultimedia(Relato relato) async {
    // Si no hay multimedia, retornar null para no actualizar
    if (relato.multimedia.isEmpty) return null;
    
    // Lista para almacenar la multimedia procesada
    final List<Multimedia> multimediaProcesada = [];
    
    // Procesar cada archivo multimedia
    for (final media in relato.multimedia) {
      // Si la URL comienza con "file://" es un archivo local que hay que subir
      if (media.url.startsWith('file://')) {
        // Extraer la ruta del archivo
        final filePath = media.url.replaceFirst('file://', '');
        final file = File(filePath);
        
        if (await file.exists()) {
          try {
            // Construir la ruta destino en Firebase Storage
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final fileName = '${relato.id}_${timestamp}_${file.path.split('/').last}';
            final storagePath = '$_relatosStoragePath/${relato.id}/$fileName';
            
                         // Determinar el tipo de contenido según el tipo de multimedia
             String? contentType;
             switch (media.tipo) {
               case TipoMultimedia.imagen:
                 contentType = 'image/jpeg';
                 break;
               case TipoMultimedia.audio:
                 contentType = 'audio/mpeg';
                 break;
               case TipoMultimedia.video:
                 contentType = 'video/mp4';
                 break;
             }
            
            // Subir el archivo
            final downloadUrl = await _storageDataSource.uploadFile(
              file: file,
              path: storagePath,
              contentType: contentType,
              metadata: {'relatoId': relato.id},
            );
            
            // Crear el objeto multimedia con la URL descargable
            multimediaProcesada.add(Multimedia(
              url: downloadUrl,
              tipo: media.tipo,
              descripcion: media.descripcion,
              orden: media.orden,
            ));
          } catch (e) {
            throw RelatoMediaException.fromError('Error al subir archivo: $e');
          }
        } else {
          throw RelatoMediaException.fromError('Archivo no encontrado: $filePath');
        }
      } else {
        // Si no es un archivo local, mantener la multimedia como está
        multimediaProcesada.add(media);
      }
    }
    
    return multimediaProcesada;
  }

  /// Calcula la similitud entre dos títulos (0.0 - 1.0)
  /// Usa una versión simplificada de la distancia de Levenshtein
  double _calcularSimilitudTitulos(String titulo1, String titulo2) {
    // Normalizar
    final s1 = titulo1.trim().toLowerCase();
    final s2 = titulo2.trim().toLowerCase();
    
    // Casos triviales
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    // Implementación simplificada de la distancia de Levenshtein
    final int len1 = s1.length;
    final int len2 = s2.length;
    
    // Matriz de distancias
    final List<List<int>> d = List.generate(
      len1 + 1, 
      (i) => List.generate(len2 + 1, (j) => 0)
    );
    
    // Inicializar primera fila y columna
    for (int i = 0; i <= len1; i++) d[i][0] = i;
    for (int j = 0; j <= len2; j++) d[0][j] = j;
    
    // Calcular distancia
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,        // eliminación
          d[i][j - 1] + 1,        // inserción
          d[i - 1][j - 1] + cost, // sustitución
        ].reduce((curr, next) => curr < next ? curr : next);
      }
    }
    
    // Calcular similitud normalizada (0.0 - 1.0)
    final maxLen = len1 > len2 ? len1 : len2;
    return 1.0 - (d[len1][len2] / maxLen);
  }

  /// Calcula la distancia entre dos puntos en kilómetros usando la fórmula de Haversine
  double _calcularDistanciaKm({
    required double lat1, 
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double radioTierra = 6371.0; // Radio de la Tierra en km
    final double dLat = _toRadianes(lat2 - lat1);
    final double dLon = _toRadianes(lon2 - lon1);
    
    // Fórmula de Haversine
    final double a = 
      _haversin(dLat) + 
      _haversin(dLon) * _cos(_toRadianes(lat1)) * _cos(_toRadianes(lat2));
      
    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    final double distancia = radioTierra * c;
    
    return distancia;
  }
  
     // Funciones auxiliares para cálculos de distancia
   double _toRadianes(double grados) => grados * 0.017453292519943295; // PI/180
   double _haversin(double theta) => 0.5 * (1 - cos(2 * theta));
   double _cos(double x) => cos(x);
   double _sqrt(double x) => sqrt(x);
   double _atan2(double y, double x) => atan2(y, x);
}
