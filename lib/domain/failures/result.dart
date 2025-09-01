import 'failures.dart';

/// Lightweight Result type to avoid external deps.
sealed class Result<T, E> {
  const Result();

  R when<R>({required R Function(T value) success, required R Function(E error) failure}) {
    final self = this;
    if (self is Success<T, E>) return success(self.value);
    if (self is FailureResult<T, E>) return failure(self.error);
    throw StateError('Invalid Result state');
  }

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is FailureResult<T, E>;

  T? get valueOrNull => this is Success<T, E> ? (this as Success<T, E>).value : null;
  E? get errorOrNull => this is FailureResult<T, E> ? (this as FailureResult<T, E>).error : null;
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class FailureResult<T, E> extends Result<T, E> {
  final E error;
  const FailureResult(this.error);
}

typedef UseCaseResult<T> = Future<Result<T, Failure>>;


