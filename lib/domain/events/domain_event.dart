abstract class DomainEvent {
  final DateTime timestamp;
  final String userId;

  DomainEvent({
    required this.userId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap();
}
