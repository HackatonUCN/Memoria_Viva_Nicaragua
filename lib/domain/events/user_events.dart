import '../entities/user.dart';
import '../enums/roles_usuario.dart';
import 'domain_event.dart';

class UserRegistrado extends DomainEvent {
  final String nombre;
  final UserRole rol;

  UserRegistrado({
    required String userId,
    required this.nombre,
    required this.rol,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'nombre': nombre,
    'rol': rol.value,
  };
}

class UserRolActualizado extends DomainEvent {
  final UserRole rolAnterior;
  final UserRole rolNuevo;
  final String actualizadoPorId;

  UserRolActualizado({
    required String userId,
    required this.rolAnterior,
    required this.rolNuevo,
    required this.actualizadoPorId,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'rolAnterior': rolAnterior.value,
    'rolNuevo': rolNuevo.value,
    'actualizadoPorId': actualizadoPorId,
  };
}

class UserPerfilActualizado extends DomainEvent {
  final Map<String, dynamic> cambios;

  UserPerfilActualizado({
    required String userId,
    required this.cambios,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'cambios': cambios,
  };
}

class UserLogueado extends DomainEvent {
  final String metodo; // email, google, apple, etc.
  final String? dispositivo;
  final String? ubicacion;

  UserLogueado({
    required String userId,
    required this.metodo,
    this.dispositivo,
    this.ubicacion,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'metodo': metodo,
    'dispositivo': dispositivo,
    'ubicacion': ubicacion,
  };
}

class UserCerroSesion extends DomainEvent {
  final String? razon;
  final int duracionSesionMinutos;

  UserCerroSesion({
    required String userId,
    this.razon,
    required this.duracionSesionMinutos,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'razon': razon,
    'duracionSesionMinutos': duracionSesionMinutos,
  };
}

class UserPreferenciasActualizadas extends DomainEvent {
  final Map<String, dynamic> preferencias;

  UserPreferenciasActualizadas({
    required String userId,
    required this.preferencias,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'preferencias': preferencias,
  };
}

class UserBloqueado extends DomainEvent {
  final String razon;
  final String bloqueadoPorId;
  final DateTime? hasta;

  UserBloqueado({
    required String userId,
    required this.razon,
    required this.bloqueadoPorId,
    this.hasta,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'razon': razon,
    'bloqueadoPorId': bloqueadoPorId,
    'hasta': hasta?.toIso8601String(),
  };
}

class UserDesbloqueado extends DomainEvent {
  final String razon;
  final String desbloqueadoPorId;

  UserDesbloqueado({
    required String userId,
    required this.razon,
    required this.desbloqueadoPorId,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'razon': razon,
    'desbloqueadoPorId': desbloqueadoPorId,
  };
}

class UserLogroObtenido extends DomainEvent {
  final String logroId;
  final String nombreLogro;
  final int puntos;

  UserLogroObtenido({
    required String userId,
    required this.logroId,
    required this.nombreLogro,
    required this.puntos,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'logroId': logroId,
    'nombreLogro': nombreLogro,
    'puntos': puntos,
  };
}

class UserNivelSubido extends DomainEvent {
  final int nivelAnterior;
  final int nivelNuevo;
  final int puntosActuales;

  UserNivelSubido({
    required String userId,
    required this.nivelAnterior,
    required this.nivelNuevo,
    required this.puntosActuales,
    DateTime? timestamp,
  }) : super(userId: userId, timestamp: timestamp);

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'nivelAnterior': nivelAnterior,
    'nivelNuevo': nivelNuevo,
    'puntosActuales': puntosActuales,
  };
}