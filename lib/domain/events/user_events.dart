import '../enums/roles_usuario.dart';
import 'domain_event.dart';

class UserRegistrado extends DomainEvent {
  final String nombre;
  final UserRole rol;

  UserRegistrado({
    required super.userId,
    required this.nombre,
    required this.rol,
    super.timestamp,
  });

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
    required super.userId,
    required this.rolAnterior,
    required this.rolNuevo,
    required this.actualizadoPorId,
    super.timestamp,
  });

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
    required super.userId,
    required this.cambios,
    super.timestamp,
  });

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
    required super.userId,
    required this.metodo,
    this.dispositivo,
    this.ubicacion,
    super.timestamp,
  });

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
    required super.userId,
    this.razon,
    required this.duracionSesionMinutos,
    super.timestamp,
  });

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
    required super.userId,
    required this.preferencias,
    super.timestamp,
  });

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
    required super.userId,
    required this.razon,
    required this.bloqueadoPorId,
    this.hasta,
    super.timestamp,
  });

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
    required super.userId,
    required this.razon,
    required this.desbloqueadoPorId,
    super.timestamp,
  });

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
    required super.userId,
    required this.logroId,
    required this.nombreLogro,
    required this.puntos,
    super.timestamp,
  });

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
    required super.userId,
    required this.nivelAnterior,
    required this.nivelNuevo,
    required this.puntosActuales,
    super.timestamp,
  });

  @override
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'timestamp': timestamp,
    'nivelAnterior': nivelAnterior,
    'nivelNuevo': nivelNuevo,
    'puntosActuales': puntosActuales,
  };
}