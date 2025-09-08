enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id; // unique op id
  final String resource; // e.g., 'relato', 'saber'
  final String resourceId;
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int priority; // higher first
  final int attempt;
  final DateTime? nextAttemptAt;

  SyncOperation({
    required this.id,
    required this.resource,
    required this.resourceId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.priority = 0,
    this.attempt = 0,
    this.nextAttemptAt,
  });

  SyncOperation copyWith({int? priority, int? attempt, DateTime? nextAttemptAt}) => SyncOperation(
        id: id,
        resource: resource,
        resourceId: resourceId,
        type: type,
        payload: payload,
        createdAt: createdAt,
        priority: priority ?? this.priority,
        attempt: attempt ?? this.attempt,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      );
}

abstract class ISyncQueue {
  Future<void> enqueue(SyncOperation op);
  Future<List<SyncOperation>> peek({int limit = 20});
  Future<void> markDone(String opId);
  Future<void> markFailed(String opId, {Duration? backoff});
  Future<void> requeue(String opId, {int? priority});
  Future<void> clear();
  Future<int> length();
}


