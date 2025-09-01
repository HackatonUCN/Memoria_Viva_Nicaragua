import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/tipos_contenido.dart';

/// Entidad para categorizar el contenido de la aplicación
class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final TipoContenido tipo;
  
  // Jerarquía
  final String? categoriaPadreId;
  
  // UI/UX
  final String icono;            // Nombre del icono
  final String color;            // Color en hex
  final int orden;               // Orden de visualización
  
  // Estado
  final bool activa;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  const Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.icono,
    required this.color,
    required this.orden,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.categoriaPadreId,
    this.activa = true,
  });

  /// Crea una copia con campos actualizados
  Categoria copyWith({
    String? nombre,
    String? descripcion,
    TipoContenido? tipo,
    String? categoriaPadreId,
    String? icono,
    String? color,
    int? orden,
    bool? activa,
  }) {
    return Categoria(
      id: this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      categoriaPadreId: categoriaPadreId ?? this.categoriaPadreId,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      fechaCreacion: this.fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo.value,
      'categoriaPadreId': categoriaPadreId,
      'icono': icono,
      'color': color,
      'orden': orden,
      'activa': activa,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea desde Map de Firestore
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tipo: TipoContenido.fromString(map['tipo'] as String),
      categoriaPadreId: map['categoriaPadreId'] as String?,
      icono: map['icono'] as String,
      color: map['color'] as String,
      orden: map['orden'] as int,
      activa: map['activa'] as bool? ?? true,
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaActualizacion: (map['fechaActualizacion'] as Timestamp).toDate(),
    );
  }

  /// Crea una nueva categoría
  factory Categoria.crear({
    required String nombre,
    required String descripcion,
    required TipoContenido tipo,
    required String icono,
    required String color,
    required int orden,
    String? categoriaPadreId,
  }) {
    return Categoria(
      id: FirebaseFirestore.instance.collection('categorias').doc().id,
      nombre: nombre,
      descripcion: descripcion,
      tipo: tipo,
      categoriaPadreId: categoriaPadreId,
      icono: icono,
      color: color,
      orden: orden,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
  }
}