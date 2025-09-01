/// Enum que define los roles de usuario disponibles en la aplicación
enum UserRole {
  invitado('invitado', 'Acceso solo lectura'),
  normal('normal', 'Acceso estándar'),
  admin('admin', 'Acceso completo');

  final String value;
  final String descripcion;
  const UserRole(this.value, this.descripcion);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.normal,
    );
  }
}
