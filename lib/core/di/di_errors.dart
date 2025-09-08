import 'package:flutter/foundation.dart';

/// Errores y excepciones específicas del contenedor de inyección de dependencias.
class DIException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  DIException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() => 'DIException: $message${cause != null ? ' -> $cause' : ''}';
}

/// Utilidad para logueo seguro durante la inicialización del DI
void diDebugLog(String message, {Object? error}) {
  if (kDebugMode) {
    debugPrint('[DI] $message${error != null ? ' -> $error' : ''}');
  }
}


