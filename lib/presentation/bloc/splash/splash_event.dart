import 'package:equatable/equatable.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

class SplashStarted extends SplashEvent {
  const SplashStarted();
}

class SplashAnimationCompleted extends SplashEvent {
  const SplashAnimationCompleted();
}

class SplashDataLoaded extends SplashEvent {
  const SplashDataLoaded();
}

class SplashError extends SplashEvent {
  final String message;
  const SplashError(this.message);

  @override
  List<Object?> get props => [message];
}
