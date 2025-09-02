import '../exceptions/value_object_exception.dart';

/// Tipos de multimedia soportados
enum TipoMultimedia {
  imagen('imagen', ['jpg', 'jpeg', 'png', 'webp']),
  audio('audio', ['mp3', 'wav', 'm4a']),
  video('video', ['mp4', 'mov', 'webm']);

  final String value;
  final List<String> extensionesPermitidas;
  const TipoMultimedia(this.value, this.extensionesPermitidas);

  static TipoMultimedia fromString(String value) {
    try {
      return TipoMultimedia.values.firstWhere((t) => t.value == value);
    } catch (_) {
      throw MultimediaInvalidaException.tipoInvalido(
        tipoInvalido: value,
      );
    }
  }

  static TipoMultimedia detectarTipo(String url) {
    final extension = url.split('.').last.toLowerCase();
    for (var tipo in TipoMultimedia.values) {
      if (tipo.extensionesPermitidas.contains(extension)) {
        return tipo;
      }
    }
    throw MultimediaInvalidaException.tipoArchivoNoSoportado(
      url: url,
      extension: extension,
      extensionesPermitidas: TipoMultimedia.values
          .expand((tipo) => tipo.extensionesPermitidas)
          .toList(),
    );
  }
}

class Multimedia {
  static const int MAX_DESCRIPCION_LENGTH = 500;
  static const int MAX_FILE_SIZE_MB = 100;

  final String url;
  final TipoMultimedia tipo;
  final String? descripcion;
  final DateTime fechaSubida;
  final int? tamanoBytes;
  final int orden;

  const Multimedia._({
    required this.url,
    required this.tipo,
    this.descripcion,
    required this.fechaSubida,
    this.tamanoBytes,
    this.orden = 0,
  });

  factory Multimedia({
    required String url,
    TipoMultimedia? tipo,
    String? descripcion,
    DateTime? fechaSubida,
    int? tamanoBytes,
    int orden = 0,
  }) {
    // Validar URL
    if (!url.startsWith('https://')) {
      throw MultimediaInvalidaException.urlInvalida(url: url);
    }

    // Detectar tipo si no se proporciona
    final tipoFinal = tipo ?? TipoMultimedia.detectarTipo(url);

    // Validar descripción
    if (descripcion != null && descripcion.length > MAX_DESCRIPCION_LENGTH) {
      throw MultimediaInvalidaException.descripcionInvalida(
        descripcion: descripcion,
        maxCaracteres: MAX_DESCRIPCION_LENGTH,
      );
    }

    // Validar tamaño
    if (tamanoBytes != null && tamanoBytes > (MAX_FILE_SIZE_MB * 1024 * 1024)) {
      throw MultimediaInvalidaException.tamanoExcedido(
        url: url,
        tamanoBytes: tamanoBytes,
        limiteMegaBytes: MAX_FILE_SIZE_MB,
      );
    }

    return Multimedia._(
      url: url,
      tipo: tipoFinal,
      descripcion: descripcion,
      fechaSubida: fechaSubida ?? DateTime.now(),
      tamanoBytes: tamanoBytes,
      orden: orden,
    );
  }

  String obtenerThumbnailUrl() {
    switch (tipo) {
      case TipoMultimedia.imagen:
        final match = RegExp(r'\.([^.]+)$').firstMatch(url);
        if (match != null) {
          final extension = match.group(1);
          return url.replaceAll(RegExp(r'\.[^.]+$'), '_thumb.$extension');
        }
        return '${url}_thumb.jpg';
      case TipoMultimedia.video:
        return url.replaceAll(RegExp(r'\.[^.]+$'), '_thumb.jpg');
      case TipoMultimedia.audio:
        return 'https://storage.googleapis.com/memoria-viva/assets/audio_thumbnail.png';
    }
  }

  Map<String, dynamic> toMap() => {
    'url': url,
    'tipo': tipo.value,
    'descripcion': descripcion,
    'fechaSubida': fechaSubida.toIso8601String(),
    'tamanoBytes': tamanoBytes,
    'orden': orden,
  };

  factory Multimedia.fromMap(Map<String, dynamic> map) {
    final tipoStr = map['tipo'] as String;
    return Multimedia(
      url: map['url'] as String,
      tipo: TipoMultimedia.fromString(tipoStr),
      descripcion: map['descripcion'] as String?,
      fechaSubida: DateTime.parse(map['fechaSubida'] as String),
      tamanoBytes: map['tamanoBytes'] as int?,
      orden: map['orden'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Multimedia &&
    runtimeType == other.runtimeType &&
    url == other.url &&
    tipo == other.tipo &&
    descripcion == other.descripcion &&
    fechaSubida == other.fechaSubida &&
    tamanoBytes == other.tamanoBytes &&
    orden == other.orden;

  @override
  int get hashCode =>
    url.hashCode ^
    tipo.hashCode ^
    descripcion.hashCode ^
    fechaSubida.hashCode ^
    (tamanoBytes?.hashCode ?? 0) ^
    orden.hashCode;

  @override
  String toString() =>
    'Multimedia(url: $url, tipo: ${tipo.value}, descripcion: $descripcion, fechaSubida: $fechaSubida, tamanoBytes: $tamanoBytes, orden: $orden)';
}