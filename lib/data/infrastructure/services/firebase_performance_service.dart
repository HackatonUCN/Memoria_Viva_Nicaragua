import 'package:firebase_performance/firebase_performance.dart';

class FirebasePerformanceService {
  final FirebasePerformance _performance = FirebasePerformance.instance;
  
  // Trace para medir el tiempo de carga de contenido
  Trace? _contentLoadTrace;
  // Trace para medir el tiempo de carga de imágenes
  Trace? _imageLoadTrace;
  // Trace para medir el tiempo de operaciones de base de datos
  Trace? _databaseOperationTrace;

  Future<void> initialize() async {
    // Habilitar la recopilación de datos de rendimiento
    await _performance.setPerformanceCollectionEnabled(true);
  }

  // Iniciar medición de carga de contenido
  void startContentLoadTrace(String contentType) {
    _contentLoadTrace = _performance.newTrace('content_load_$contentType');
    _contentLoadTrace?.start();
  }

  // Detener medición de carga de contenido
  Future<void> stopContentLoadTrace({Map<String, String>? metrics}) async {
    if (_contentLoadTrace != null) {
      if (metrics != null) {
        metrics.forEach((key, value) {
          _contentLoadTrace!.putAttribute(key, value);
        });
      }
      await _contentLoadTrace!.stop();
      _contentLoadTrace = null;
    }
  }

  // Iniciar medición de carga de imágenes
  void startImageLoadTrace() {
    _imageLoadTrace = _performance.newTrace('image_load');
    _imageLoadTrace?.start();
  }

  // Detener medición de carga de imágenes
  Future<void> stopImageLoadTrace({int? imageSize}) async {
    if (_imageLoadTrace != null) {
      if (imageSize != null) {
        _imageLoadTrace!.putAttribute('image_size', '${imageSize}kb');
      }
      await _imageLoadTrace!.stop();
      _imageLoadTrace = null;
    }
  }

  // Iniciar medición de operaciones de base de datos
  void startDatabaseOperationTrace(String operation) {
    _databaseOperationTrace = _performance.newTrace('database_$operation');
    _databaseOperationTrace?.start();
  }

  // Detener medición de operaciones de base de datos
  Future<void> stopDatabaseOperationTrace({Map<String, String>? metrics}) async {
    if (_databaseOperationTrace != null) {
      if (metrics != null) {
        metrics.forEach((key, value) {
          _databaseOperationTrace!.putAttribute(key, value);
        });
      }
      await _databaseOperationTrace!.stop();
      _databaseOperationTrace = null;
    }
  }

  // Medir tiempo de carga de red
  HttpMetric startNetworkRequest(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // Ejemplo de uso para medir tiempo de respuesta de API
  Future<void> measureApiCall(String url, HttpMethod method, Future<void> Function() apiCall) async {
    final metric = startNetworkRequest(url, method);
    await metric.start();
    
    try {
      await apiCall();
      metric.putAttribute('success', 'true');
    } catch (e) {
      metric.putAttribute('success', 'false');
      metric.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await metric.stop();
    }
  }
}
