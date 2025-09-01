import '../entities/user.dart';
import '../enums/roles_usuario.dart';
import '../entities/relato.dart';
import '../entities/saber_popular.dart';
import '../entities/evento_cultural.dart';

/// Política de permisos por rol para acciones sobre el dominio
class PermisosPolicy {
  /// Un invitado solo puede visualizar. Usuarios activos pueden crear.
  static bool puedePublicar(User usuario) {
    return usuario.activo && usuario.rol != UserRole.invitado;
  }

  static bool esAdmin(User usuario) => usuario.rol == UserRole.admin;

  // Relatos
  static bool puedeCrearRelato(User usuario) => puedePublicar(usuario);

  static bool puedeEditarRelato(User usuario, Relato relato) {
    return esAdmin(usuario) || relato.autorId == usuario.id;
  }

  static bool puedeEliminarRelato(User usuario, Relato relato) {
    return esAdmin(usuario) || relato.autorId == usuario.id;
  }

  // Saberes
  static bool puedeCrearSaber(User usuario) => puedePublicar(usuario);

  static bool puedeEditarSaber(User usuario, SaberPopular saber) {
    return esAdmin(usuario) || saber.autorId == usuario.id;
  }

  static bool puedeEliminarSaber(User usuario, SaberPopular saber) {
    return esAdmin(usuario) || saber.autorId == usuario.id;
  }

  // Eventos
  /// Cualquier usuario activo puede crear; aprobación se define en moderación.
  static bool puedeCrearEvento(User usuario) => usuario.activo;

  static bool puedeEditarEvento(User usuario, EventoCultural evento) {
    return esAdmin(usuario) || evento.creadoPorId == usuario.id;
  }

  static bool puedeEliminarEvento(User usuario, EventoCultural evento) {
    return esAdmin(usuario) || evento.creadoPorId == usuario.id;
  }

  // Comentarios / reportes / reacciones
  static bool puedeComentar(User usuario) => usuario.activo && usuario.rol != UserRole.invitado;

  static bool puedeReaccionar(User usuario) => usuario.activo && usuario.rol != UserRole.invitado;

  static bool puedeReportar(User usuario) => usuario.id.isNotEmpty;
}
