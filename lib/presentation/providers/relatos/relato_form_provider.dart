import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/relato.dart';
import '../../../domain/factories/usecases.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../../domain/usecases/relatos/crear_relato_usecase.dart';
import '../../../domain/validators/contenido_validator.dart';
import '../../../domain/enums/tipos_contenido.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/failures/result.dart';
import '../../../domain/services/i_connectivity_service.dart';
import '../../../domain/services/i_geolocation_service.dart';
import '../../../data/datasources/impl/cloudinary_storage_datasource_impl.dart';
import '../../../domain/value_objects/ubicacion.dart';

enum UploadStatus { queued, uploading, done, error, cancelled }

class MediaUploadItem {
  final String id;
  final TipoMultimedia tipo;
  final File? file;
  final Uint8List? bytes; // usado en Web
  String? url;
  UploadStatus status;
  double progress; // 0..100 (best-effort)
  String? error;

  MediaUploadItem({
    required this.id,
    required this.tipo,
    this.file,
    this.bytes,
    this.url,
    this.status = UploadStatus.queued,
    this.progress = 0,
    this.error,
  });
}

class RelatoFormProvider extends ChangeNotifier {
  final _useCases = UseCases.resolve();
  final GetIt _getIt = GetIt.I;

  // Campos del formulario
  String titulo = '';
  String contenido = '';
  final List<String> etiquetas = [];
  String? categoriaId;

  // Categorías
  List<Categoria> categorias = [];
  bool categoriasLoading = false;
  String? categoriasError;
  static List<Categoria> _memCacheCategorias = [];
  static DateTime? _memCacheAt;
  static const Duration _memCacheTtl = Duration(minutes: 10);

  // Semilla de cache desde otras capas (por ejemplo FeedProvider)
  static void seedCategoriasCache(List<Categoria> cats) {
    _memCacheCategorias = List.of(cats);
    _memCacheAt = DateTime.now();
  }

  // Ubicación elegida o null
  String? departamento;
  String? municipio;
  double? latitud;
  double? longitud;

  // Multimedia
  final List<MediaUploadItem> uploads = [];

  // Estado general
  bool isPublishing = false;
  String? errorMessage;
  bool get hasPendingUploads => uploads.any((u) => u.status == UploadStatus.queued || u.status == UploadStatus.uploading);
  bool lastPublishOffline = false;
  Relato? lastCreatedRelato;

  // Modo edición
  bool isEditing = false;
  String? relatoId;
  Relato? _originalRelato;

  // Herramientas
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  // Internos
  String? _currentUserId;
  StreamSubscription<List<Categoria>>? _catsSub;
  final Map<String, http.Client> _clientsByUpload = {};
  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      try { notifyListeners(); } catch (_) {}
    }
  }

  Future<void> init() async {
    // Cargar usuario actual en segundo plano
    // ignore: discarded_futures
    _ensureCurrentUser();

    // Cargar categorías con cache en memoria y refresh en background
    categoriasLoading = true;
    categoriasError = null;
    _notify();

    final bool cacheFresh = _memCacheCategorias.isNotEmpty && (_memCacheAt != null) && DateTime.now().difference(_memCacheAt!) < _memCacheTtl;
    if (cacheFresh) {
      categorias = List.of(_memCacheCategorias);
      categoriasLoading = false;
      _notify();
      // Refresh en background sin bloquear UI
      // ignore: discarded_futures
      _refreshCategorias();
      return;
    }

    await _refreshCategorias();
  }

  Future<void> _refreshCategorias() async {
    try {
      final uc = _getIt<ObtenerCategoriasPorTipoUseCase>();
      final res = await uc.execute(TipoContenido.relato).timeout(const Duration(seconds: 8));
      final data = res.valueOrNull ?? _memCacheCategorias;
      categorias = List.of(data)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      _memCacheCategorias = List.of(categorias);
      _memCacheAt = DateTime.now();
      _catsSub?.cancel();
      _catsSub = uc.observe(TipoContenido.relato).listen((data) {
        categorias = List.of(data)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _memCacheCategorias = List.of(categorias);
        _memCacheAt = DateTime.now();
        _notify();
      });
      categoriasLoading = false;
      categoriasError = null;
      _notify();
    } on TimeoutException {
      // Mantener cache si existe, mostrar sin bloquear
      if (_memCacheCategorias.isNotEmpty) {
        categorias = List.of(_memCacheCategorias);
        categoriasLoading = false;
        categoriasError = null;
        _notify();
      } else {
        categoriasLoading = false;
        categoriasError = 'Tiempo de espera al cargar categorías';
        _notify();
      }
    } catch (e) {
      categoriasError = e.toString();
      categoriasLoading = false;
      _notify();
    }
  }

  // Helper para inicializar edición si viene un relato
  void loadRelatoForEditIfNeeded(Relato? relato) {
    if (relato != null) {
      loadRelatoForEdit(relato);
    }
  }
  void loadRelatoForEdit(Relato relato) {
    isEditing = true;
    relatoId = relato.id;
    _originalRelato = relato;
    titulo = relato.titulo;
    contenido = relato.contenido;
    categoriaId = relato.categoriaId;
    etiquetas
      ..clear()
      ..addAll(relato.etiquetas);
    departamento = relato.ubicacion?.departamento;
    municipio = relato.ubicacion?.municipio;
    latitud = relato.ubicacion?.latitud;
    longitud = relato.ubicacion?.longitud;
    uploads.clear(); // no cargar multimedia en edición
    notifyListeners();
  }

  void resetEditMode() {
    isEditing = false;
    relatoId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _catsSub?.cancel();
    _recorder.dispose();
    _isDisposed = true;
    super.dispose();
  }

  // Validaciones simples en UI (dominio hace validación fuerte)
  bool get tituloValido => titulo.trim().length >= 5 && titulo.trim().length <= 80;
  bool get contenidoValido => contenido.trim().length >= 20;
  bool get categoriaValida => categoriaId != null && categoriaId!.isNotEmpty;
  bool get formularioValido => tituloValido && contenidoValido && categoriaValida && !hasPendingUploads;

  void setTitulo(String v) {
    titulo = v;
    notifyListeners();
  }

  void setContenido(String v) {
    contenido = v;
    notifyListeners();
  }

  void setCategoria(String? id) {
    categoriaId = id;
    notifyListeners();
  }

  void addEtiqueta(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return;
    if (etiquetas.contains(t)) return;
    if (etiquetas.length >= 10) return;
    etiquetas.add(t);
    notifyListeners();
  }

  void removeEtiqueta(String tag) {
    etiquetas.remove(tag);
    notifyListeners();
  }

  void setUbicacion({String? dep, String? mun, double? lat, double? lng}) {
    departamento = dep;
    municipio = mun;
    latitud = lat;
    longitud = lng;
    notifyListeners();
  }

  // Pickers
  Future<void> addImagenDesdeGaleria() async {
    // Móvil (Android/iOS): usar selector del sistema con múltiples imágenes/videos
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final List<XFile> files = await _picker.pickMultipleMedia(imageQuality: 90);
      if (files.isEmpty) return;
      for (final x in files) {
        final String pathOrName = x.path.isNotEmpty ? x.path : x.name;
        final String ext = pathOrName.split('.').last.toLowerCase();
        final bool isVideo = TipoMultimedia.video.extensionesPermitidas.contains(ext);
        final TipoMultimedia tipo = isVideo ? TipoMultimedia.video : TipoMultimedia.imagen;
        _queueUpload(tipo: tipo, file: File(x.path));
      }
      return;
    }

    // Web y desktop: usar FilePicker con gestor de archivos y selección múltiple
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        ...TipoMultimedia.imagen.extensionesPermitidas,
        ...TipoMultimedia.video.extensionesPermitidas,
      ],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      final name = f.name.toLowerCase();
      final bool isVideo = TipoMultimedia.video.extensionesPermitidas.any((e) => name.endsWith('.$e'));
      final TipoMultimedia tipo = isVideo ? TipoMultimedia.video : TipoMultimedia.imagen;
      if (kIsWeb) {
        if (f.bytes == null) continue;
        _queueUploadBytes(tipo: tipo, bytes: f.bytes!);
      } else {
        if (f.path == null) continue;
        _queueUpload(tipo: tipo, file: File(f.path!));
      }
    }
  }

  Future<void> addImagenDesdeCamara() async {
    if (kIsWeb) {
      // En web, usar cámara abre file picker; tratamos igual que galería
      return addImagenDesdeGaleria();
    }
    final XFile? xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (xfile == null) return;
    _queueUpload(tipo: TipoMultimedia.imagen, file: File(xfile.path));
  }

  Future<void> addDesdeArchivos() async {
    // Permitir audio, video e imagen desde selector de archivos (móvil y web)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: [
        ...TipoMultimedia.imagen.extensionesPermitidas,
        ...TipoMultimedia.video.extensionesPermitidas,
        ...TipoMultimedia.audio.extensionesPermitidas,
      ],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    for (final file in result.files) {
      final String name = (file.name).toLowerCase();
      TipoMultimedia tipo;
      if (TipoMultimedia.imagen.extensionesPermitidas.any((e) => name.endsWith('.$e'))) {
        tipo = TipoMultimedia.imagen;
      } else if (TipoMultimedia.video.extensionesPermitidas.any((e) => name.endsWith('.$e'))) {
        tipo = TipoMultimedia.video;
      } else {
        tipo = TipoMultimedia.audio;
      }
      if (kIsWeb) {
        if (file.bytes == null) continue;
        _queueUploadBytes(tipo: tipo, bytes: file.bytes!);
      } else {
        if (file.path == null) continue;
        _queueUpload(tipo: tipo, file: File(file.path!));
      }
    }
  }

  bool _grabando = false;
  bool get grabando => _grabando;

  Future<void> iniciarGrabacionAudio() async {
    if (kIsWeb) return; // degradar en web
    if (await _recorder.hasPermission()) {
      // Construir un path temporal para la grabación
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/mvn_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );
      _grabando = true;
      notifyListeners();
    }
  }

  Future<void> detenerGrabacionAudio() async {
    if (kIsWeb) return;
    final path = await _recorder.stop();
    _grabando = false;
    notifyListeners();
    if (path == null) return;
    final file = File(path);
    _queueUpload(tipo: TipoMultimedia.audio, file: file);
  }

  void eliminarMedia(String id) {
    uploads.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  void _queueUpload({required TipoMultimedia tipo, required File file}) {
    final item = MediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      tipo: tipo,
      file: file,
      status: UploadStatus.queued,
      progress: 0,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  void _queueUploadBytes({required TipoMultimedia tipo, required Uint8List bytes}) {
    final item = MediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      tipo: tipo,
      bytes: bytes,
      status: UploadStatus.queued,
      progress: 0,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  Future<void> _uploadInBackground(MediaUploadItem item) async {
    if (_currentUserId == null) {
      final current = await _useCases.auth.getCurrentUser.execute();
      _currentUserId = current.valueOrNull?.id;
    }
    if (item.file == null && item.bytes == null) return;
    item.status = UploadStatus.uploading;
    item.progress = 5;
    notifyListeners();

    try {
      // Usar Cloudinary datasource directo (unsigned upload preset)
      final client = http.Client();
      _clientsByUpload[item.id] = client;
      final ds = CloudinaryStorageDataSourceImpl(basePath: 'relatos/${_currentUserId ?? 'anon'}', client: client);
      final ext = item.tipo == TipoMultimedia.imagen
          ? 'jpg'
          : (item.tipo == TipoMultimedia.audio ? 'm4a' : 'mp4');
      final String contentType = item.tipo == TipoMultimedia.imagen
          ? 'image/jpeg'
          : (item.tipo == TipoMultimedia.audio ? 'audio/aac' : 'video/mp4');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

      // Best-effort progress: simular barra mientras sube
      final progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (item.progress < 90 && item.status == UploadStatus.uploading) {
          item.progress += 2;
          notifyListeners();
        }
      });

      final String url;
      if (kIsWeb || item.bytes != null) {
        url = await ds.uploadData(
          data: item.bytes ?? await item.file!.readAsBytes(),
          path: fileName,
          contentType: contentType,
        );
      } else {
        url = await ds.uploadFile(
          file: item.file!,
          path: fileName,
          contentType: contentType,
        );
      }
      progressTimer.cancel();

      item.url = url;
      item.progress = 100;
      item.status = UploadStatus.done;
      notifyListeners();
    } catch (e) {
      item.error = e.toString();
      item.status = UploadStatus.error;
      notifyListeners();
    } finally {
      _clientsByUpload.remove(item.id)?.close();
    }
  }

  void cancelUpload(String id) {
    final client = _clientsByUpload.remove(id);
    client?.close();
    final idx = uploads.indexWhere((u) => u.id == id);
    if (idx != -1) {
      uploads[idx].status = UploadStatus.cancelled;
      uploads[idx].progress = 0;
      notifyListeners();
    }
  }

  void retryUpload(String id) {
    final idx = uploads.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    final item = uploads[idx];
    if (item.file == null) return;
    item.status = UploadStatus.queued;
    item.progress = 0;
    item.error = null;
    notifyListeners();
    _uploadInBackground(item);
  }

  // Publicación
  Future<bool> publicar() async {
    if (isPublishing) return false;
    await _ensureCurrentUser();
    if (!formularioValido) {
      errorMessage = 'Completa título, contenido y categoría.';
      notifyListeners();
      return false;
    }
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      errorMessage = 'Debes iniciar sesión para publicar.';
      notifyListeners();
      return false;
    }
    debugPrint('[RELATO_FORM][INICIO_SUBMIT]');
    isPublishing = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Recolectar multimedia listos
      final imagenes = uploads
          .where((u) => u.tipo == TipoMultimedia.imagen && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final audio = uploads
          .where((u) => u.tipo == TipoMultimedia.audio && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final videos = uploads
          .where((u) => u.tipo == TipoMultimedia.video && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();

      // Nota: El estado offline para el mensaje se determinará según el resultado del caso de uso

      // Ubicación por defecto si no eligió
      String? dep = departamento;
      String? mun = municipio;
      double? lat = latitud;
      double? lng = longitud;
      if ((dep == null || mun == null) && _getIt.isRegistered<IGeolocationService>()) {
        try {
          final geo = _getIt<IGeolocationService>();
          final ub = await geo.obtenerUbicacionActual();
          dep = ub.departamento;
          mun = ub.municipio;
          lat = ub.latitud;
          lng = ub.longitud;
        } catch (_) {
          // fallback: sin ubicación
        }
      }

      debugPrint('[RELATO_FORM][MEDIA_OK] imagenes=${imagenes.length} audio=${audio.isNotEmpty} video=${videos.isNotEmpty}');
      final res = isEditing && relatoId != null
          ? await _useCases.relatos.actualizar.execute(
              relatoId: relatoId!,
              usuarioId: _currentUserId!,
              titulo: titulo.trim(),
              contenido: contenido.trim(),
              categoriaId: categoriaId!,
              departamento: dep,
              municipio: mun,
              latitud: lat,
              longitud: lng,
              etiquetas: List.of(etiquetas),
            )
          : await _useCases.relatos.crear.execute(
              titulo: titulo.trim(),
              contenido: contenido.trim(),
              autorId: _currentUserId!,
              categoriaId: categoriaId!,
              departamento: dep,
              municipio: mun,
              latitud: lat,
              longitud: lng,
              imagenesUrls: imagenes,
              audioUrl: audio.isNotEmpty ? audio.first : null,
              videoUrl: videos.isNotEmpty ? videos.first : null,
              etiquetas: List.of(etiquetas),
            );

      isPublishing = false;
      // Si falló por red, lo consideramos encolado offline; si fue éxito, no es offline
      bool queuedOffline = false;
      if (res.isFailure) {
        final failure = res.errorOrNull;
        if (failure is NetworkFailure) {
          queuedOffline = true;
        }
      }
      lastPublishOffline = queuedOffline;
      if (!isEditing && res.isSuccess) {
        // Guardar el relato creado real para UI optimista sin duplicados
        final created = (res as Result<Relato, Failure>).valueOrNull;
        lastCreatedRelato = created;
      }
      if (res.isFailure && !queuedOffline) {
        errorMessage = res.errorOrNull?.message ?? 'No se pudo publicar el relato.';
        notifyListeners();
        return false;
      }
      debugPrint('[RELATO_FORM][USECASE_OK]');
      notifyListeners();
      // Si fue encolado offline, igual consideramos éxito
      return res.isSuccess || queuedOffline;
    } catch (e) {
      isPublishing = false;
      errorMessage = e.toString();
      debugPrint('[RELATO_FORM][ERROR] $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureCurrentUser() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      final current = await _useCases.auth.getCurrentUser.execute();
      _currentUserId = current.valueOrNull?.id;
    }
  }

  // Construye un Relato mínimo usando el estado del formulario para UI optimista
  Relato? relatoConstruidoMinimo() {
    try {
      if (_currentUserId == null || categoriaId == null) return null;
      // Recolectar URLs ya subidas
      final imagenes = uploads
          .where((u) => u.tipo == TipoMultimedia.imagen && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final audios = uploads
          .where((u) => u.tipo == TipoMultimedia.audio && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final videos = uploads
          .where((u) => u.tipo == TipoMultimedia.video && u.status == UploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();

      final List<Multimedia> multimedia = [];
      for (final url in imagenes) {
        multimedia.add(Multimedia(url: url, tipo: TipoMultimedia.imagen));
      }
      if (audios.isNotEmpty) {
        multimedia.add(Multimedia(url: audios.first, tipo: TipoMultimedia.audio));
      }
      if (videos.isNotEmpty) {
        multimedia.add(Multimedia(url: videos.first, tipo: TipoMultimedia.video));
      }

      // Resolver nombre de categoría seleccionado
      String catNombre = 'Relato';
      for (final c in categorias) {
        if (c.id == categoriaId) { catNombre = c.nombre; break; }
      }
      return Relato.crear(
        titulo: titulo.trim(),
        contenido: contenido.trim(),
        autorId: _currentUserId!,
        autorNombre: 'Yo',
        categoriaId: categoriaId!,
        categoriaNombre: catNombre,
        ubicacion: (departamento != null && municipio != null)
            ? Ubicacion(
                latitud: latitud ?? 0,
                longitud: longitud ?? 0,
                departamento: departamento!,
                municipio: municipio!,
              )
            : null,
        multimedia: multimedia,
        etiquetas: List.of(etiquetas),
      );
    } catch (_) {
      return null;
    }
  }

  // Construye una versión editada mínima conservando el mismo ID
  Relato? relatoEditadoMinimo() {
    try {
      if (!isEditing || relatoId == null || _originalRelato == null || categoriaId == null) return null;
      final Relato base = _originalRelato!;

      // Resolver nombre de categoría actual
      String categoriaNombreFinal = base.categoriaNombre;
      final String selCatId = categoriaId!;
      for (final c in categorias) {
        if (c.id == selCatId) { categoriaNombreFinal = c.nombre; break; }
      }

      // Resolver ubicación (si el usuario cambió)
      Ubicacion? ubic;
      if (departamento != null && municipio != null) {
        ubic = Ubicacion(
          latitud: latitud ?? base.ubicacion?.latitud ?? 0,
          longitud: longitud ?? base.ubicacion?.longitud ?? 0,
          departamento: departamento!,
          municipio: municipio!,
        );
      } else {
        ubic = base.ubicacion;
      }

      return Relato(
        id: base.id,
        titulo: titulo.trim(),
        contenido: contenido.trim(),
        autorId: base.autorId,
        autorNombre: base.autorNombre,
        categoriaId: selCatId,
        categoriaNombre: categoriaNombreFinal,
        fechaCreacion: base.fechaCreacion,
        fechaActualizacion: DateTime.now().toUtc(),
        ubicacion: ubic,
        multimedia: base.multimedia,
        etiquetas: List.of(etiquetas.isEmpty ? base.etiquetas : etiquetas),
        estado: base.estado,
        reportes: base.reportes,
        procesado: base.procesado,
        likes: base.likes,
        compartidos: base.compartidos,
        eliminado: base.eliminado,
        fechaEliminacion: base.fechaEliminacion,
      );
    } catch (_) {
      return null;
    }
  }
}


