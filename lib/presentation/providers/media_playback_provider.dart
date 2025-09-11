import 'package:flutter/foundation.dart';

/// Provider global para coordinar reproducción multimedia por ámbitos (card/overlay)
/// y asegurar que solo una fuente esté activa a la vez.
class MediaPlaybackProvider extends ChangeNotifier {
  /// Registro de handlers de pausa por clave única.
  /// La clave se construye como: "scope::relatoId::sourceId"
  final Map<String, _HandlerEntry> _handlers = {};

  PlaybackEntry? _current;

  PlaybackEntry? get currentPlaying => _current;

  /// Registra un handler de pausa para una fuente concreta.
  /// Devuelve la clave para desregistrar posteriormente.
  String registerHandler({
    required String scope, // 'card' | 'overlay'
    String? relatoId,
    required String sourceId, // normalmente la URL
    required Future<void> Function() onPause,
    String? tipo, // 'audio' | 'video' (opcional, para telemetría/UI)
  }) {
    final key = _buildKey(scope: scope, relatoId: relatoId, sourceId: sourceId);
    _handlers[key] = _HandlerEntry(
      scope: scope,
      relatoId: relatoId,
      sourceId: sourceId,
      tipo: tipo,
      onPause: onPause,
    );
    return key;
  }

  void unregisterHandlerByKey(String key) {
    _handlers.remove(key);
  }

  /// Pausa todas las fuentes registradas.
  Future<void> pauseAll() async {
    final handlers = List.of(_handlers.values);
    for (final h in handlers) {
      try {
        await h.onPause();
      } catch (_) {
        // ignorar errores individuales
      }
    }
    _current = null;
    notifyListeners();
  }

  /// Pausa por ámbito. Si [relatoId] es provisto, limita al relato.
  Future<void> pauseScope(String scope, {String? relatoId}) async {
    final handlers = List.of(_handlers.values).where((h) {
      final scopeMatch = h.scope == scope;
      final relatoMatch = relatoId == null ? true : h.relatoId == relatoId;
      return scopeMatch && relatoMatch;
    });
    for (final h in handlers) {
      try {
        await h.onPause();
      } catch (_) {}
    }
    if (_current != null) {
      final c = _current!;
      final scopeMatch = c.scope == scope;
      final relatoMatch = relatoId == null ? true : c.relatoId == relatoId;
      if (scopeMatch && relatoMatch) {
        _current = null;
        notifyListeners();
      }
    }
  }

  /// Debe llamarse antes de iniciar reproducción para garantizar exclusividad.
  Future<void> willStartPlayback({
    required String scope,
    String? relatoId,
    required String sourceId,
    required String tipo,
  }) async {
    await pauseAll();
    _current = PlaybackEntry(scope: scope, relatoId: relatoId, sourceId: sourceId, tipo: tipo);
    notifyListeners();
  }

  String _buildKey({required String scope, String? relatoId, required String sourceId}) {
    return '$scope::${relatoId ?? ''}::${sourceId}';
  }
}

class PlaybackEntry {
  final String scope; // 'card' | 'overlay'
  final String? relatoId;
  final String sourceId; // típicamente URL
  final String tipo; // 'audio' | 'video'

  const PlaybackEntry({
    required this.scope,
    required this.relatoId,
    required this.sourceId,
    required this.tipo,
  });
}

class _HandlerEntry {
  final String scope;
  final String? relatoId;
  final String sourceId;
  final String? tipo;
  final Future<void> Function() onPause;

  const _HandlerEntry({
    required this.scope,
    required this.relatoId,
    required this.sourceId,
    required this.onPause,
    this.tipo,
  });
}


