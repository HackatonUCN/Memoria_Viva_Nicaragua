import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/services/i_sync_queue.dart';

/// Cola persistente simple usando SharedPreferences (se puede migrar a Hive/SQLite)
class SyncQueueImpl implements ISyncQueue {
  static const String _kKey = 'sync_queue_ops';
  final SharedPreferences _prefs;

  SyncQueueImpl(this._prefs);

  @override
  Future<void> enqueue(SyncOperation op) async {
    final list = await _readAll();
    list.add(_encode(op));
    list.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    await _prefs.setString(_kKey, jsonEncode(list));
  }

  @override
  Future<List<SyncOperation>> peek({int limit = 20}) async {
    final list = await _readAll();
    final filtered = list.where((m) {
      final next = m['nextAttemptAt'] as int?;
      return next == null || DateTime.now().millisecondsSinceEpoch >= next;
    }).take(limit);
    return filtered.map(_decode).toList();
  }

  @override
  Future<void> markDone(String opId) async {
    final list = await _readAll();
    list.removeWhere((m) => m['id'] == opId);
    await _prefs.setString(_kKey, jsonEncode(list));
  }

  @override
  Future<void> markFailed(String opId, {Duration? backoff}) async {
    final list = await _readAll();
    for (var i = 0; i < list.length; i++) {
      if (list[i]['id'] == opId) {
        final attempt = (list[i]['attempt'] as int) + 1;
        final delay = backoff ?? Duration(seconds: 2 * (1 << (attempt.clamp(0, 6))));
        final next = DateTime.now().add(delay).millisecondsSinceEpoch;
        list[i]['attempt'] = attempt;
        list[i]['nextAttemptAt'] = next;
        break;
      }
    }
    await _prefs.setString(_kKey, jsonEncode(list));
  }

  @override
  Future<void> requeue(String opId, {int? priority}) async {
    final list = await _readAll();
    for (var i = 0; i < list.length; i++) {
      if (list[i]['id'] == opId) {
        if (priority != null) list[i]['priority'] = priority;
        list[i]['nextAttemptAt'] = null;
        break;
      }
    }
    list.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    await _prefs.setString(_kKey, jsonEncode(list));
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_kKey);
  }

  @override
  Future<int> length() async => (await _readAll()).length;

  // ---- internals ----
  Future<List<Map<String, dynamic>>> _readAll() async {
    final s = _prefs.getString(_kKey);
    if (s == null || s.isEmpty) return <Map<String, dynamic>>[];
    final List<dynamic> raw = jsonDecode(s) as List<dynamic>;
    return raw.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _encode(SyncOperation op) => {
        'id': op.id,
        'resource': op.resource,
        'resourceId': op.resourceId,
        'type': op.type.name,
        'payload': _sanitize(op.payload),
        'createdAt': op.createdAt.millisecondsSinceEpoch,
        'priority': op.priority,
        'attempt': op.attempt,
        'nextAttemptAt': op.nextAttemptAt?.millisecondsSinceEpoch,
      };

  SyncOperation _decode(Map<String, dynamic> m) => SyncOperation(
        id: m['id'] as String,
        resource: m['resource'] as String,
        resourceId: m['resourceId'] as String,
        type: SyncOperationType.values.firstWhere((e) => e.name == m['type']),
        payload: (m['payload'] as Map).cast<String, dynamic>(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        priority: m['priority'] as int,
        attempt: m['attempt'] as int,
        nextAttemptAt: (m['nextAttemptAt'] as int?) != null ? DateTime.fromMillisecondsSinceEpoch(m['nextAttemptAt'] as int) : null,
      );

  /// Convierte estructuras arbitrarias a tipos JSON-encodables
  dynamic _sanitize(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _sanitize(v)));
    }
    if (value is Iterable) {
      return value.map(_sanitize).toList();
    }
    return value;
  }
}


