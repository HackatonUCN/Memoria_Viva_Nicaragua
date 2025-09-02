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
  const ValidationFailure(super.message, {String? code, super.details})
      : super(code: code ?? 'VALIDATION_ERROR');
}

/// Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {String? code, super.details})
      : super(code: code ?? 'NOT_FOUND');
}

/// Permission denied or unauthorized action
class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure(super.message, {String? code, super.details})
      : super(code: code ?? 'PERMISSION_DENIED');
}

/// Network/connectivity issues, timeouts
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {String? code, super.details})
      : super(code: code ?? 'NETWORK_ERROR');
}

/// Any unexpected/unknown error
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {String? code, super.details})
      : super(code: code ?? 'UNEXPECTED_ERROR');
}


