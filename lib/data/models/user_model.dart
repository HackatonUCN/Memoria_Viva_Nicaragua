import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';
import '../../domain/enums/roles_usuario.dart';
import 'base_model.dart';

/// Modelo para mapear la entidad User a/desde Firestore
class UserModel implements BaseModel<User> {
  final String id;                // UID de Firebase Auth
  final String nombre;            // Nombre completo
  final String email;            // Email para autenticación
  final String rol;              // Rol del usuario como string
  final String? avatarUrl;       // URL de Firebase Storage para la foto
  final Timestamp fechaRegistro;   // Timestamp de creación
  final Timestamp ultimaModificacion; // Último update
  
  // Campos de perfil
  final String? departamento;    // Ubicación - importante para contexto cultural
  final String? municipio;       // Ubicación más específica
  final String? biografia;       // Descripción personal
  
  // Estadísticas y métricas
  final int relatosPublicados;   // Contador de historias
  final int saberesCompartidos;  // Contador de saberes populares
  final int puntajeTotal;        // Gamificación
  
  // Estado y preferencias
  final bool activo;             // Estado de la cuenta
  final bool notificacionesActivas; // Preferencias de notificación

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaRegistro,
    required this.ultimaModificacion,
    required this.activo,
    this.avatarUrl,
    this.departamento,
    this.municipio,
    this.biografia,
    this.relatosPublicados = 0,
    this.saberesCompartidos = 0,
    this.puntajeTotal = 0,
    this.notificacionesActivas = true,
  });

  /// Convierte la entidad de dominio User a UserModel
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      nombre: user.nombre,
      email: user.email,
      rol: user.rol.value,
      avatarUrl: user.avatarUrl,
      fechaRegistro: Timestamp.fromDate(user.fechaRegistro),
      ultimaModificacion: Timestamp.fromDate(user.ultimaModificacion),
      departamento: user.departamento,
      municipio: user.municipio,
      biografia: user.biografia,
      activo: user.activo,
      relatosPublicados: user.relatosPublicados,
      saberesCompartidos: user.saberesCompartidos,
      puntajeTotal: user.puntajeTotal,
      notificacionesActivas: user.notificacionesActivas,
    );
  }

  /// Convierte el modelo a la entidad de dominio User
  @override
  User toDomain() {
    return User(
      id: id,
      nombre: nombre,
      email: email,
      rol: UserRole.fromString(rol),
      avatarUrl: avatarUrl,
      fechaRegistro: fechaRegistro.toDate().toUtc(),
      ultimaModificacion: ultimaModificacion.toDate().toUtc(),
      departamento: departamento,
      municipio: municipio,
      biografia: biografia,
      activo: activo,
      relatosPublicados: relatosPublicados,
      saberesCompartidos: saberesCompartidos,
      puntajeTotal: puntajeTotal,
      notificacionesActivas: notificacionesActivas,
    );
  }

  /// Convierte el modelo a un Map para Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'avatarUrl': avatarUrl,
      'fechaRegistro': fechaRegistro,
      'ultimaModificacion': ultimaModificacion,
      'departamento': departamento,
      'municipio': municipio,
      'biografia': biografia,
      'activo': activo,
      'relatosPublicados': relatosPublicados,
      'saberesCompartidos': saberesCompartidos,
      'puntajeTotal': puntajeTotal,
      'notificacionesActivas': notificacionesActivas,
    };
  }

  /// Crea una instancia de UserModel desde un Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      email: map['email'] as String,
      rol: map['rol'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      fechaRegistro: map['fechaRegistro'] as Timestamp,
      ultimaModificacion: map['ultimaModificacion'] as Timestamp,
      departamento: map['departamento'] as String?,
      municipio: map['municipio'] as String?,
      biografia: map['biografia'] as String?,
      activo: map['activo'] as bool,
      relatosPublicados: map['relatosPublicados'] as int? ?? 0,
      saberesCompartidos: map['saberesCompartidos'] as int? ?? 0,
      puntajeTotal: map['puntajeTotal'] as int? ?? 0,
      notificacionesActivas: map['notificacionesActivas'] as bool? ?? true,
    );
  }

  /// Crea una instancia desde un documento de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id del usuario
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return UserModel.fromMap(data);
  }

  /// Crear una copia con valores actualizados
  UserModel copyWith({
    String? nombre,
    String? avatarUrl,
    String? departamento,
    String? municipio,
    String? biografia,
    bool? notificacionesActivas,
    String? rol,
    bool? activo,
    int? relatosPublicados,
    int? saberesCompartidos,
    int? puntajeTotal,
  }) {
    return UserModel(
      id: id,
      email: email,
      nombre: nombre ?? this.nombre,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rol: rol ?? this.rol,
      fechaRegistro: fechaRegistro,
      ultimaModificacion: Timestamp.now(),
      departamento: departamento ?? this.departamento,
      municipio: municipio ?? this.municipio,
      biografia: biografia ?? this.biografia,
      activo: activo ?? this.activo,
      relatosPublicados: relatosPublicados ?? this.relatosPublicados,
      saberesCompartidos: saberesCompartidos ?? this.saberesCompartidos,
      puntajeTotal: puntajeTotal ?? this.puntajeTotal,
      notificacionesActivas: notificacionesActivas ?? this.notificacionesActivas,
    );
  }
}
