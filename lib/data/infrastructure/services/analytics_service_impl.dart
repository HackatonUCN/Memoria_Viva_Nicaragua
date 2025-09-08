import 'package:memoria_viva_nicaragua/domain/entities/user.dart' as domain;

import '../../../domain/services/i_analytics_service.dart';
import '../../infrastructure/services/firebase_services_manager.dart';

/// Implementación de IAnalyticsService basada en FirebaseServicesManager
class AnalyticsServiceImpl implements IAnalyticsService {
  final FirebaseServicesManager _firebaseManager;

  AnalyticsServiceImpl(this._firebaseManager);

  Map<String, Object> _p(Map<String, dynamic> map) {
    final out = <String, Object>{};
    map.forEach((key, value) {
      if (value != null) out[key] = value as Object;
    });
    return out;
  }

  @override
  Future<void> inicializar({domain.User? usuario}) async {
    if (usuario != null) {
      await _firebaseManager.setUserContext(
        userId: usuario.id,
        userRole: usuario.rol.value,
      );
    }
  }

  @override
  Future<void> registrarVisualizacion({
    required String contenidoId,
    required String tipoContenido,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent('view_content', parameters: _p({
      'content_id': contenidoId,
      'content_type': tipoContenido,
      ...?propiedades,
    }));
  }

  @override
  Future<void> registrarInteraccion({
    required String contenidoId,
    required String tipoContenido,
    required String tipoInteraccion,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent('interact_content', parameters: _p({
      'content_id': contenidoId,
      'content_type': tipoContenido,
      'interaction_type': tipoInteraccion,
      ...?propiedades,
    }));
  }

  @override
  Future<void> registrarBusqueda({
    required String consulta,
    required String tipoContenido,
    required int resultados,
    Map<String, dynamic>? filtros,
  }) async {
    await _firebaseManager.logEvent('search', parameters: _p({
      'query': consulta,
      'content_type': tipoContenido,
      'results': resultados,
      ...?filtros,
    }));
  }

  @override
  Future<void> registrarNavegacion({
    required String pantalla,
    String? pantallaAnterior,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent('screen_view', parameters: _p({
      'screen_name': pantalla,
      if (pantallaAnterior != null) 'previous_screen': pantallaAnterior,
      ...?propiedades,
    }));
  }

  @override
  Future<void> registrarError({
    required String mensaje,
    required String codigo,
    String? ubicacion,
    Map<String, dynamic>? contexto,
  }) async {
    await _firebaseManager.logError(
      'app_error: $mensaje',
      error: codigo,
    );
    await _firebaseManager.logEvent('app_error', parameters: {
      'code': codigo,
      if (ubicacion != null) 'location': ubicacion,
      ...?contexto,
    });
  }

  @override
  Future<void> registrarEvento({
    required String nombre,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent(nombre, parameters: _p({...?propiedades ?? {}}));
  }

  @override
  Future<void> registrarInicioSesion({
    required String metodo,
    bool esNuevoUsuario = false,
  }) async {
    await _firebaseManager.logEvent('login', parameters: _p({
      'method': metodo,
      'is_new_user': esNuevoUsuario,
    }));
  }

  @override
  Future<void> registrarCierreSesion({int duracionSesionSegundos = 0}) async {
    await _firebaseManager.logEvent('logout', parameters: _p({
      'session_duration_sec': duracionSesionSegundos,
    }));
  }

  @override
  Future<void> registrarCreacionContenido({
    required String tipoContenido,
    required String contenidoId,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent('create_content', parameters: _p({
      'content_type': tipoContenido,
      'content_id': contenidoId,
      ...?propiedades,
    }));
  }

  @override
  Future<void> registrarParticipacionEvento({
    required String eventoId,
    required String tipoParticipacion,
  }) async {
    await _firebaseManager.logEvent('event_participation', parameters: _p({
      'event_id': eventoId,
      'participation_type': tipoParticipacion,
    }));
  }

  @override
  Future<void> registrarRendimiento({
    required String operacion,
    required int duracionMs,
    Map<String, dynamic>? metricas,
  }) async {
    await _firebaseManager.logEvent('performance', parameters: _p({
      'operation': operacion,
      'duration_ms': duracionMs,
      ...?metricas,
    }));
  }

  @override
  Future<void> registrarUsoCaracteristica({
    required String caracteristica,
    Map<String, dynamic>? propiedades,
  }) async {
    await _firebaseManager.logEvent('feature_use', parameters: _p({
      'feature': caracteristica,
      ...?propiedades,
    }));
  }

  @override
  Future<Map<String, dynamic>> obtenerEstadisticasUsuario(String usuarioId) async {
    // Placeholder simple: registrar evento y devolver mapa vacío
    await _firebaseManager.logEvent('get_user_stats', parameters: _p({'user_id': usuarioId}));
    return {};
  }

  @override
  Future<Map<String, dynamic>> obtenerEstadisticasContenido({
    required String contenidoId,
    required String tipoContenido,
  }) async {
    await _firebaseManager.logEvent('get_content_stats', parameters: _p({
      'content_id': contenidoId,
      'content_type': tipoContenido,
    }));
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerTendencias({String? tipoContenido, int limite = 10}) async {
    await _firebaseManager.logEvent('get_trending', parameters: _p({
      if (tipoContenido != null) 'content_type': tipoContenido,
      'limit': limite,
    }));
    return <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>> obtenerMetricasAplicacion({DateTime? fechaInicio, DateTime? fechaFin}) async {
    await _firebaseManager.logEvent('get_app_metrics', parameters: _p({
      if (fechaInicio != null) 'from': fechaInicio.toIso8601String(),
      if (fechaFin != null) 'to': fechaFin.toIso8601String(),
    }));
    return {};
  }

  @override
  Future<void> establecerPropiedadesUsuario(Map<String, dynamic> propiedades) async {
    await _firebaseManager.logEvent('set_user_properties', parameters: _p({...propiedades}));
  }

  @override
  Future<void> desactivarSeguimiento() async {
    await _firebaseManager.logEvent('analytics_disable');
  }

  @override
  Future<void> activarSeguimiento() async {
    await _firebaseManager.logEvent('analytics_enable');
  }
}


