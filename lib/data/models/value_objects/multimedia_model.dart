import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../domain/value_objects/multimedia.dart';

/// Modelo para mapear el value object Multimedia a/desde Firestore
class MultimediaModel {
  final String url;
  final String tipo; // TipoMultimedia como string
  final String? descripcion;
  final Timestamp fechaSubida;
  final int? tamanoBytes;
  final int orden;

  MultimediaModel({
    required this.url,
    required this.tipo,
    this.descripcion,
    required this.fechaSubida,
    this.tamanoBytes,
    this.orden = 0,
  });

  /// Convierte el modelo a la entidad de dominio Multimedia
  Multimedia toDomain() {
    return Multimedia(
      url: url,
      tipo: TipoMultimedia.fromString(tipo),
      descripcion: descripcion,
      fechaSubida: fechaSubida.toDate().toUtc(),
      tamanoBytes: tamanoBytes,
      orden: orden,
    );
  }

  /// Convierte la entidad de dominio Multimedia a MultimediaModel
  factory MultimediaModel.fromDomain(Multimedia multimedia) {
    return MultimediaModel(
      url: multimedia.url,
      tipo: multimedia.tipo.value,
      descripcion: multimedia.descripcion,
      fechaSubida: Timestamp.fromDate(multimedia.fechaSubida),
      tamanoBytes: multimedia.tamanoBytes,
      orden: multimedia.orden,
    );
  }

  /// Convierte el modelo a un Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'tipo': tipo,
      'descripcion': descripcion,
      'fechaSubida': fechaSubida,
      'tamanoBytes': tamanoBytes,
      'orden': orden,
    };
  }

  /// Crea una instancia de MultimediaModel desde un Map de Firestore
  factory MultimediaModel.fromMap(Map<String, dynamic> map) {
    return MultimediaModel(
      url: map['url'] as String,
      tipo: map['tipo'] as String,
      descripcion: map['descripcion'] as String?,
      fechaSubida: map['fechaSubida'] as Timestamp,
      tamanoBytes: map['tamanoBytes'] as int?,
      orden: map['orden'] as int? ?? 0,
    );
  }
}
