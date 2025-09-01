// Unified Failure hierarchy for domain layer

/// Base class for domain failures.
abstract class Failure implements Exception {
  final String message;
  final String? code;
  final Object? details;

  const Failure(this.message, {this.code, this.details});

  @override
  String toString() => '${runtimeType.toString()}: $message${code != null ? ' (code: $code)' : ''}';
}

/// Validation error (invalid input, value objects, constraints)
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code, Object? details})
      : super(message, code: code ?? 'VALIDATION_ERROR', details: details);
}

/// Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {String? code, Object? details})
      : super(message, code: code ?? 'NOT_FOUND', details: details);
}

/// Permission denied or unauthorized action
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(String message, {String? code, Object? details})
      : super(message, code: code ?? 'PERMISSION_DENIED', details: details);
}

/// Network/connectivity issues, timeouts
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code, Object? details})
      : super(message, code: code ?? 'NETWORK_ERROR', details: details);
}

/// Any unexpected/unknown error
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(String message, {String? code, Object? details})
      : super(message, code: code ?? 'UNEXPECTED_ERROR', details: details);
}


