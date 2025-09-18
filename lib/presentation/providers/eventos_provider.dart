import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/evento_cultural.dart';
import '../../domain/enums/tipos_evento.dart';
import '../../domain/failures/failures.dart';
import '../../domain/factories/usecases.dart';
import 'auth_provider.dart' as auth;

/// Provider para orquestar calendario/lista de eventos y moderación/admin
class EventosProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve().eventos;

  // Estado de usuario
  String? _currentUserId;
  bool _isAdmin = false;
  bool get isLoggedIn => _currentUserId != null;
  bool get isAdmin => _isAdmin;

  // Eventos
  bool loading = false;
  String? error;
  List<EventoCultural> eventos = [];
  StreamSubscription<List<EventoCultural>>? _eventosSub;

  // Estados para operaciones específicas
  bool isUpdating = false;
  bool isDeleting = false;
  String? _updatingEventId;
  String? _deletingEventId;
  
  bool isEventUpdating(String eventId) => isUpdating && _updatingEventId == eventId;
  bool isEventDeleting(String eventId) => isDeleting && _deletingEventId == eventId;

  // Día seleccionado para agenda
  DateTime selectedDay = DateTime.now();

  // Sugerencias (solo admin)
  bool sugerenciasLoading = false;
  String? sugerenciasError;
  List<SugerenciaEvento> sugerenciasPendientes = [];

  Future<void> init({auth.AuthProvider? authProvider}) async {
    // Leer rol del AuthProvider si lo proveen
    if (authProvider != null) {
      final user = authProvider.user;
      _currentUserId = user?.id;
      _isAdmin = user?.esAdmin ?? false;
      debugPrint('[EVENTOS_PROVIDER][INIT] userId=${_currentUserId} isAdmin=${_isAdmin} (from authProvider)');
    } else {
      final me = await UseCases.resolve().auth.getCurrentUser.execute();
      final user = me.valueOrNull;
      _currentUserId = user?.id;
      _isAdmin = user?.esAdmin ?? false;
      debugPrint('[EVENTOS_PROVIDER][INIT] userId=${_currentUserId} isAdmin=${_isAdmin} (from getCurrentUser)');
    }

    await _loadInitialEventos();
    _observeEventos();
    if (_isAdmin) {
      debugPrint('[EVENTOS_PROVIDER][INIT] Es admin, cargando sugerencias...');
      await loadSugerenciasPendientes();
    } else {
      debugPrint('[EVENTOS_PROVIDER][INIT] No es admin, saltando sugerencias');
    }
  }

  Future<void> _loadInitialEventos() async {
    loading = true;
    error = null;
    notifyListeners();
    final res = await _useCases.obtener.execute();
    res.when(
      success: (data) => eventos = data,
      failure: (f) => error = f.message,
    );
    loading = false;
    notifyListeners();
  }

  void _observeEventos() {
    _eventosSub?.cancel();
    _eventosSub = _useCases.obtener.observe().listen(
      (data) {
        debugPrint('[EVENTOS_PROVIDER][STREAM] recibidos=${data.length}');
        eventos = data;
        notifyListeners();
      },
      onError: (e) {
        error = e is Failure ? e.message : e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    await _loadInitialEventos();
    if (_isAdmin) {
      await loadSugerenciasPendientes();
    }
  }

  void setSelectedDay(DateTime day) {
    selectedDay = DateTime(day.year, day.month, day.day);
    final count = eventosDelDia(selectedDay).length;
    debugPrint('[EVENTOS_PROVIDER][SELECT_DAY] ${selectedDay.toIso8601String()} eventosDelDia=$count');
    notifyListeners();
  }

  List<EventoCultural> eventosDelDia(DateTime day) {
    final d0 = DateTime(day.year, day.month, day.day);
    final d1 = d0.add(const Duration(days: 1));
    return eventos.where((e) => !e.eliminado && e.fechaInicio.isBefore(d1) && e.fechaFin.isAfter(d0)).toList();
  }

  // Crear/editar/eliminar para admins
  Future<String?> crearEvento({
    required String nombre,
    required String descripcion,
    required String categoriaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String organizador,
    String? departamento,
    String? municipio,
    double? latitud,
    double? longitud,
    List<String> imagenesUrls = const [],
    bool esRecurrente = false,
    String? frecuencia,
    String? contacto,
  }) async {
    if (!_isAdmin || _currentUserId == null) return 'No autorizado';
    final res = await _useCases.crear.execute(
      adminId: _currentUserId!,
      nombre: nombre,
      descripcion: descripcion,
      tipo: TipoEvento.otro,
      categoriaId: categoriaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      organizador: organizador,
      departamento: departamento,
      municipio: municipio,
      latitud: latitud,
      longitud: longitud,
      imagenesUrls: imagenesUrls,
      esRecurrente: esRecurrente,
      frecuencia: frecuencia,
      contacto: contacto,
    );
    if (res.isFailure) return res.errorOrNull?.message ?? 'Error';
    return null;
  }

  Future<String?> actualizarEvento({
    required String eventoId,
    String? nombre,
    String? descripcion,
    String? categoriaId,
    TipoEvento? tipo,
    String? departamento,
    String? municipio,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? organizador,
    String? contacto,
    bool? esRecurrente,
    String? frecuencia,
    double? latitud,
    double? longitud,
    List<String>? imagenesUrls,
  }) async {
    if (!_isAdmin || _currentUserId == null) return 'No autorizado';
    
    // Mostrar loader para el evento específico
    isUpdating = true;
    _updatingEventId = eventoId;
    notifyListeners();
    
    try {
      final res = await _useCases.actualizar.execute(
        adminId: _currentUserId!,
        eventoId: eventoId,
        nombre: nombre,
        descripcion: descripcion,
        categoriaId: categoriaId,
        tipo: tipo,
        departamento: departamento,
        municipio: municipio,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        organizador: organizador,
        contacto: contacto,
        esRecurrente: esRecurrente,
        frecuencia: frecuencia,
        latitud: latitud,
        longitud: longitud,
        imagenesUrls: imagenesUrls,
      );
      
      if (res.isFailure) {
        return res.errorOrNull?.message ?? 'Error';
      }
      
      // Refrescar datos automáticamente
      await refresh();
      return null;
    } finally {
      // Ocultar loader
      isUpdating = false;
      _updatingEventId = null;
      notifyListeners();
    }
  }

  Future<String?> eliminarEvento(String eventoId) async {
    if (!_isAdmin || _currentUserId == null) return 'No autorizado';
    
    // Mostrar loader para el evento específico
    isDeleting = true;
    _deletingEventId = eventoId;
    notifyListeners();
    
    try {
      final res = await _useCases.eliminar.execute(adminId: _currentUserId!, eventoId: eventoId);
      
      if (res.isFailure) {
        return res.errorOrNull?.message ?? 'Error';
      }
      
      // Refrescar datos automáticamente
      await refresh();
      return null;
    } finally {
      // Ocultar loader
      isDeleting = false;
      _deletingEventId = null;
      notifyListeners();
    }
  }

  // Sugerencias
  Future<void> loadSugerenciasPendientes() async {
    if (!_isAdmin) {
      debugPrint('[SUGERENCIAS] No es admin, saltando carga');
      return;
    }
    debugPrint('[SUGERENCIAS] Iniciando carga de sugerencias pendientes...');
    sugerenciasLoading = true;
    sugerenciasError = null;
    notifyListeners();
    
    try {
      final res = await _useCases.obtenerSugerenciasPendientes.execute();
      debugPrint('[SUGERENCIAS] Resultado: isSuccess=${res.isSuccess}');
      res.when(
        success: (data) {
          sugerenciasPendientes = data;
          debugPrint('[SUGERENCIAS] Cargadas ${data.length} sugerencias pendientes');
          for (int i = 0; i < data.length; i++) {
            debugPrint('[SUGERENCIAS][$i] id=${data[i].id} nombre="${data[i].nombre}" estado=${data[i].estado}');
          }
        },
        failure: (f) {
          sugerenciasError = f.message;
          debugPrint('[SUGERENCIAS] Error: ${f.message}');
        },
      );
    } catch (e) {
      sugerenciasError = 'Error inesperado: $e';
      debugPrint('[SUGERENCIAS] Excepción: $e');
    }
    
    sugerenciasLoading = false;
    notifyListeners();
  }

  Future<String?> aprobarSugerencia(String sugerenciaId) async {
    if (!_isAdmin || _currentUserId == null) return 'No autorizado';
    final res = await _useCases.procesarSugerencia.execute(
      adminId: _currentUserId!,
      sugerenciaId: sugerenciaId,
      aprobar: true,
    );
    if (res.isFailure) return res.errorOrNull?.message ?? 'Error';
    await loadSugerenciasPendientes();
    return null;
  }

  Future<String?> rechazarSugerencia(String sugerenciaId, {required String razon}) async {
    if (!_isAdmin || _currentUserId == null) return 'No autorizado';
    final res = await _useCases.procesarSugerencia.execute(
      adminId: _currentUserId!,
      sugerenciaId: sugerenciaId,
      aprobar: false,
      razonRechazo: razon,
    );
    if (res.isFailure) return res.errorOrNull?.message ?? 'Error';
    await loadSugerenciasPendientes();
    return null;
  }

  @override
  void dispose() {
    _eventosSub?.cancel();
    super.dispose();
  }
}


