import 'package:cloud_firestore/cloud_firestore.dart';

/// Entidad para manejar las preferencias del usuario
class UserPreferences {
  final String userId;              // ID del usuario al que pertenecen las preferencias
  
  // Tema y UI
  final bool isDarkMode;           // Modo oscuro
  final String language;           // Idioma de la app (es, en)
  final bool notificationsEnabled; // Notificaciones activadas
  
  // Personalización
  final List<String> favoriteRelatos;    // IDs de relatos favoritos
  final List<String> favoriteCategories; // IDs de categorías favoritas
  final List<String> favoriteSaberes;    // IDs de saberes favoritos
  final List<String> favoriteEventos;    // IDs de eventos guardados
  
  // Preferencias de contenido
  final List<String> departamentosInteres;  // Departamentos que le interesan
  final List<String> municipiosInteres;     // Municipios que le interesan
  final double radioNotificaciones;         // Radio en km para notificaciones de eventos cercanos
  
  // Privacidad
  final bool perfilPublico;          // Si otros pueden ver su perfil
  final bool mostrarUbicacion;       // Si se muestra su ubicación en relatos
  final bool permitirComentarios;    // Si permite comentarios en sus relatos
  
  // Timestamps
  final DateTime fechaActualizacion;

  const UserPreferences({
    required this.userId,
    this.isDarkMode = false,
    this.language = 'es',
    this.notificationsEnabled = true,
    this.favoriteRelatos = const [],
    this.favoriteCategories = const [],
    this.favoriteSaberes = const [],
    this.favoriteEventos = const [],
    this.departamentosInteres = const [],
    this.municipiosInteres = const [],
    this.radioNotificaciones = 10.0,
    this.perfilPublico = true,
    this.mostrarUbicacion = true,
    this.permitirComentarios = true,
    required this.fechaActualizacion,
  });

  /// Crea una copia con campos actualizados
  UserPreferences copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    List<String>? favoriteRelatos,
    List<String>? favoriteCategories,
    List<String>? favoriteSaberes,
    List<String>? favoriteEventos,
    List<String>? departamentosInteres,
    List<String>? municipiosInteres,
    double? radioNotificaciones,
    bool? perfilPublico,
    bool? mostrarUbicacion,
    bool? permitirComentarios,
  }) {
    return UserPreferences(
      userId: this.userId,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      favoriteRelatos: favoriteRelatos ?? this.favoriteRelatos,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      favoriteSaberes: favoriteSaberes ?? this.favoriteSaberes,
      favoriteEventos: favoriteEventos ?? this.favoriteEventos,
      departamentosInteres: departamentosInteres ?? this.departamentosInteres,
      municipiosInteres: municipiosInteres ?? this.municipiosInteres,
      radioNotificaciones: radioNotificaciones ?? this.radioNotificaciones,
      perfilPublico: perfilPublico ?? this.perfilPublico,
      mostrarUbicacion: mostrarUbicacion ?? this.mostrarUbicacion,
      permitirComentarios: permitirComentarios ?? this.permitirComentarios,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'favoriteRelatos': favoriteRelatos,
      'favoriteCategories': favoriteCategories,
      'favoriteSaberes': favoriteSaberes,
      'favoriteEventos': favoriteEventos,
      'departamentosInteres': departamentosInteres,
      'municipiosInteres': municipiosInteres,
      'radioNotificaciones': radioNotificaciones,
      'perfilPublico': perfilPublico,
      'mostrarUbicacion': mostrarUbicacion,
      'permitirComentarios': permitirComentarios,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea desde Map de Firestore
  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      userId: map['userId'] as String,
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      language: map['language'] as String? ?? 'es',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      favoriteRelatos: List<String>.from(map['favoriteRelatos'] ?? []),
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? []),
      favoriteSaberes: List<String>.from(map['favoriteSaberes'] ?? []),
      favoriteEventos: List<String>.from(map['favoriteEventos'] ?? []),
      departamentosInteres: List<String>.from(map['departamentosInteres'] ?? []),
      municipiosInteres: List<String>.from(map['municipiosInteres'] ?? []),
      radioNotificaciones: (map['radioNotificaciones'] as num?)?.toDouble() ?? 10.0,
      perfilPublico: map['perfilPublico'] as bool? ?? true,
      mostrarUbicacion: map['mostrarUbicacion'] as bool? ?? true,
      permitirComentarios: map['permitirComentarios'] as bool? ?? true,
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
    );
  }


  factory UserPreferences.defaults(String userId) {
    return UserPreferences(
      userId: userId,
      fechaActualizacion: DateTime.now(),
    );
  }
}
