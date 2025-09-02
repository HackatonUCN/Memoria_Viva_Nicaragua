import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/categoria.dart';
import '../../domain/enums/tipos_contenido.dart';
import 'base_model.dart';

/// Modelo para mapear la entidad Categoria a/desde Firestore
class CategoriaModel implements BaseModel<Categoria> {
  final String id;
  final String nombre;
  final String descripcion;
  final String tipo;            // TipoContenido como string
  final String? categoriaPadreId;
  
  // UI/UX
  final String icono;
  final String color;
  final int orden;
  
  // Estado
  final bool activa;
  final Timestamp fechaCreacion;
  final Timestamp fechaActualizacion;

  CategoriaModel({
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

  /// Convierte la entidad de dominio Categoria a CategoriaModel
  factory CategoriaModel.fromDomain(Categoria categoria) {
    return CategoriaModel(
      id: categoria.id,
      nombre: categoria.nombre,
      descripcion: categoria.descripcion,
      tipo: categoria.tipo.value,
      categoriaPadreId: categoria.categoriaPadreId,
      icono: categoria.icono,
      color: categoria.color,
      orden: categoria.orden,
      activa: categoria.activa,
      fechaCreacion: Timestamp.fromDate(categoria.fechaCreacion),
      fechaActualizacion: Timestamp.fromDate(categoria.fechaActualizacion),
    );
  }

  /// Convierte el modelo a la entidad de dominio Categoria
  @override
  Categoria toDomain() {
    return Categoria(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tipo: TipoContenido.fromString(tipo),
      categoriaPadreId: categoriaPadreId,
      icono: icono,
      color: color,
      orden: orden,
      activa: activa,
      fechaCreacion: fechaCreacion.toDate().toUtc(),
      fechaActualizacion: fechaActualizacion.toDate().toUtc(),
    );
  }

  /// Convierte el modelo a un Map para Firestore
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'categoriaPadreId': categoriaPadreId,
      'icono': icono,
      'color': color,
      'orden': orden,
      'activa': activa,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  /// Crea una instancia de CategoriaModel desde un Map de Firestore
  factory CategoriaModel.fromMap(Map<String, dynamic> map) {
    return CategoriaModel(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tipo: map['tipo'] as String,
      categoriaPadreId: map['categoriaPadreId'] as String?,
      icono: map['icono'] as String,
      color: map['color'] as String,
      orden: map['orden'] as int,
      activa: map['activa'] as bool? ?? true,
      fechaCreacion: map['fechaCreacion'] as Timestamp,
      fechaActualizacion: map['fechaActualizacion'] as Timestamp,
    );
  }

  /// Crea una instancia desde un documento de Firestore
  factory CategoriaModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    // Asegurarse de que el id del documento se use como id de la categoría
    // en caso de que no esté presente en los datos
    data['id'] = data['id'] ?? doc.id;
    return CategoriaModel.fromMap(data);
  }

  /// Crear una copia con valores actualizados
  CategoriaModel copyWith({
    String? nombre,
    String? descripcion,
    String? tipo,
    String? categoriaPadreId,
    String? icono,
    String? color,
    int? orden,
    bool? activa,
  }) {
    return CategoriaModel(
      id: id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipo: tipo ?? this.tipo,
      categoriaPadreId: categoriaPadreId ?? this.categoriaPadreId,
      icono: icono ?? this.icono,
      color: color ?? this.color,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: Timestamp.now(),
    );
  }
}
