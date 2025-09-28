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

import '../../../data/datasources/impl/cloudinary_storage_datasource_impl.dart';
import '../../../domain/entities/categoria.dart';
import '../../../domain/entities/saber_popular.dart';
import '../../../domain/factories/usecases.dart';
import '../../../domain/usecases/categorias/obtener_categorias_por_tipo_usecase.dart';
import '../../../domain/validators/contenido_validator.dart';
import '../../../domain/enums/tipos_contenido.dart';
import '../../../domain/value_objects/multimedia.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/failures/result.dart';
import '../../../domain/services/i_geolocation_service.dart';
import '../../../utils/nicaragua_coordinates.dart';
import '../../../domain/value_objects/ubicacion.dart';
import '../../../domain/enums/departamentos.dart';

enum SaberUploadStatus { queued, uploading, done, error, cancelled }

class SaberMediaUploadItem {
  final String id;
  final TipoMultimedia tipo;
  final File? file;
  final Uint8List? bytes; // usado en Web
  String? url;
  String? displayName; // para documentos u otros archivos
  SaberUploadStatus status;
  double progress; // 0..100 (best-effort)
  String? error;

  SaberMediaUploadItem({
    required this.id,
    required this.tipo,
    this.file,
    this.bytes,
    this.url,
    this.displayName,
    this.status = SaberUploadStatus.queued,
    this.progress = 0,
    this.error,
  });
}

class SaberFormProvider extends ChangeNotifier {
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

  // Sembrar cache desde otras capas (por ejemplo FeedProvider)
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
  final List<SaberMediaUploadItem> uploads = [];

  // Estado general
  bool isPublishing = false;
  String? errorMessage;
  bool get hasPendingUploads => uploads.any((u) => u.status == SaberUploadStatus.queued || u.status == SaberUploadStatus.uploading);
  bool lastPublishOffline = false;
  SaberPopular? lastCreatedSaber;

  // Modo edición
  bool isEditing = false;
  String? saberId;
  SaberPopular? _originalSaber;

  // Herramientas
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();

  // Internos
  String? _currentUserId;
  bool _currentUserIsAdmin = false;
  StreamSubscription<List<Categoria>>? _catsSub;
  final Map<String, http.Client> _clientsByUpload = {};
  bool _isDisposed = false;

  void _notify() {
    if (!_isDisposed) {
      try { notifyListeners(); } catch (_) {}
    }
  }

  Future<void> init() async {
    // Cargar usuario actual ANTES de cargar categorías para aplicar filtros por rol correctamente
    await _ensureCurrentUser();

    // Cargar categorías con cache en memoria y refresh en background
    categoriasLoading = true;
    categoriasError = null;
    _notify();

    final bool cacheFresh = _memCacheCategorias.isNotEmpty && (_memCacheAt != null) && DateTime.now().difference(_memCacheAt!) < _memCacheTtl;
    if (cacheFresh) {
      categorias = _filtrarCategoriasPorRol(_memCacheCategorias);
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
      final res = await uc.execute(TipoContenido.saber).timeout(const Duration(seconds: 8));
      final data = res.valueOrNull ?? _memCacheCategorias;
      categorias = _filtrarCategoriasPorRol(data)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      // Guardar SIEMPRE la lista sin filtrar en caché
      _memCacheCategorias = List.of(data);
      _memCacheAt = DateTime.now();
      _catsSub?.cancel();
      _catsSub = uc.observe(TipoContenido.saber).listen((data) {
        categorias = _filtrarCategoriasPorRol(data)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        // Mantener caché sin filtrar
        _memCacheCategorias = List.of(data);
        _memCacheAt = DateTime.now();
        _notify();
      });
      categoriasLoading = false;
      categoriasError = null;
      _notify();
    } on TimeoutException {
      if (_memCacheCategorias.isNotEmpty) {
        categorias = _filtrarCategoriasPorRol(_memCacheCategorias)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
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

  // Edición
  void loadSaberForEditIfNeeded(SaberPopular? saber) {
    if (saber != null) {
      loadSaberForEdit(saber);
    }
  }

  void loadSaberForEdit(SaberPopular saber) {
    isEditing = true;
    saberId = saber.id;
    _originalSaber = saber;
    titulo = saber.titulo;
    contenido = saber.contenido;
    categoriaId = saber.categoriaId;
    etiquetas
      ..clear()
      ..addAll(saber.etiquetas);
    departamento = saber.ubicacion?.departamento;
    municipio = saber.ubicacion?.municipio;
    latitud = saber.ubicacion?.latitud;
    longitud = saber.ubicacion?.longitud;
    uploads.clear(); // no cargar multimedia en edición
    notifyListeners();
  }

  void resetEditMode() {
    isEditing = false;
    saberId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _catsSub?.cancel();
    _recorder.dispose();
    _isDisposed = true;
    super.dispose();
  }

  // Validaciones simples en UI (usar límites del validador)
  bool get tituloValido => titulo.trim().length >= ContenidoValidator.MIN_TITULO_LENGTH && titulo.trim().length <= ContenidoValidator.MAX_TITULO_LENGTH;
  bool get contenidoValido => contenido.trim().length >= ContenidoValidator.MIN_DESCRIPCION_LENGTH && contenido.trim().length <= ContenidoValidator.MAX_DESCRIPCION_LENGTH;
  bool get categoriaValida => categoriaId != null && categoriaId!.isNotEmpty;
  bool get formularioValido => tituloValido && contenidoValido && categoriaValida && !hasPendingUploads;

  void setTitulo(String v) { titulo = v; notifyListeners(); }
  void setContenido(String v) { contenido = v; notifyListeners(); }
  
  
  bool get isLocationAllowed {
    final String? id = categoriaId;
    if (id != null) {
      if (id == 'saber_musica_danza' || id == 'saber_gastronomia') return true;
    }
    try {
      final cat = categorias.firstWhere((c) => c.id == categoriaId, orElse: () => categorias.firstWhere((_) => false));
      final name = cat.nombre.toLowerCase();
      if (name.contains('danza') && (name.contains('música') || name.contains('musica'))) return true;
      if (name.contains('gastronomía') || name.contains('gastronomia')) return true;
    } catch (_) {}
    return false;
  }

  void _applyLocationPolicy() {
    if (isLocationAllowed) return;
    // Ubicación nacional por defecto
    departamento = 'Nacional';
    municipio = 'Nicaragua';
    final n = NicaraguaCoordinates.getDepartamentoCoordinates('Nacional') ?? {'lat': 12.8654, 'lng': -85.2072};
    latitud = n['lat'];
    longitud = n['lng'];
  }

  @override
  void setCategoria(String? id) {
    categoriaId = id;
    _applyLocationPolicy();
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
  void removeEtiqueta(String tag) { etiquetas.remove(tag); notifyListeners(); }

  void setUbicacion({String? dep, String? mun, double? lat, double? lng}) {
    if (!isLocationAllowed) return;
    // Canonicalizar departamento a nombre usado en Dropdown (enum.nombre)
    String? depFinal = dep;
    if (dep != null && dep.trim().isNotEmpty) {
      final d = tryDepartamentoFromString(dep);
      depFinal = d?.nombre ?? dep;
    }
    // Resolver alias de municipio según departamento canónico
    String? munFinal = mun;
    if (depFinal != null && mun != null && mun.trim().isNotEmpty) {
      final depKey = canonicalizarDepartamento(depFinal);
      final aliasMap = municipioAliasPorDepartamento[depKey];
      final repl = aliasMap != null ? aliasMap[mun.toLowerCase().trim()] : null;
      munFinal = repl ?? mun;
    }
    departamento = depFinal;
    municipio = (depFinal == 'Nacional') ? 'Nicaragua' : munFinal;
    latitud = lat;
    longitud = lng;
    notifyListeners();
  }

  void setDepartamento(String? dep) {
    if (!isLocationAllowed) return;
    // Canonicalizar a nombre de enum para coincidir con Dropdown items
    String? newDep = dep;
    if (dep != null && dep.trim().isNotEmpty) {
      final d = tryDepartamentoFromString(dep);
      newDep = d?.nombre ?? dep;
    }
    final bool changed = departamento != newDep;
    departamento = newDep;
    if (changed) {
      if (departamento == 'Nacional') {
        municipio = 'Nicaragua';
      } else {
        // Limpiar municipio si no pertenece al nuevo departamento
        final depKey = canonicalizarDepartamento(departamento ?? '');
        final list = municipiosPorDepartamento[depKey] ?? const <String>[];
        if (municipio == null || !list.contains(municipio)) {
          municipio = null;
        }
      }
    }
    // Autocoords si hay municipio también
    final coords = NicaraguaCoordinates.getBestCoordinates(departamento, municipio);
    latitud = coords['lat'];
    longitud = coords['lng'];
    notifyListeners();
  }

  void setMunicipio(String? mun) {
    if (!isLocationAllowed) return;
    municipio = mun;
    final coords = NicaraguaCoordinates.getBestCoordinates(departamento, municipio);
    latitud = coords['lat'];
    longitud = coords['lng'];
    notifyListeners();
  }

  // Pickers
  Future<void> addImagenDesdeGaleria() async {
    await _ensureCurrentUser();
    bool isLibro = false;
    try {
      final c = categorias.firstWhere((c) => c.id == categoriaId);
      final name = c.nombre.toLowerCase();
      isLibro = (name == 'libro' || name == 'libros');
    } catch (_) {}
    final bool allowDocs = _currentUserIsAdmin && isLibro;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final List<XFile> files = await _picker.pickMultipleMedia(imageQuality: 90);
      if (files.isEmpty) return;
      for (final x in files) {
        final String pathOrName = x.path.isNotEmpty ? x.path : x.name;
        final String ext = pathOrName.split('.').last.toLowerCase();
        final bool isVideo = TipoMultimedia.video.extensionesPermitidas.contains(ext);
        final TipoMultimedia tipo = isVideo ? TipoMultimedia.video : TipoMultimedia.imagen;
        if (!_canAdd(tipo)) continue;
        _queueUpload(tipo: tipo, file: File(x.path), displayName: x.name);
      }
      return;
    }

    final allowedExtensions = [
      ...TipoMultimedia.imagen.extensionesPermitidas,
      ...TipoMultimedia.video.extensionesPermitidas,
      if (allowDocs) ...TipoMultimedia.documento.extensionesPermitidas,
    ];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    for (final f in result.files) {
      final name = f.name.toLowerCase();
      final bool isVideo = TipoMultimedia.video.extensionesPermitidas.any((e) => name.endsWith('.$e'));
      final bool isDoc = TipoMultimedia.documento.extensionesPermitidas.any((e) => name.endsWith('.$e'));
      if (isDoc && !allowDocs) continue;
      final TipoMultimedia tipo = isVideo
          ? TipoMultimedia.video
          : (isDoc ? TipoMultimedia.documento : TipoMultimedia.imagen);
      if (!_canAdd(tipo)) continue;
      if (kIsWeb) {
        if (f.bytes == null) continue;
        _queueUploadBytes(tipo: tipo, bytes: f.bytes!, displayName: f.name);
      } else {
        if (f.path == null) continue;
        _queueUpload(tipo: tipo, file: File(f.path!), displayName: f.name);
      }
    }
  }

  Future<void> addImagenDesdeCamara() async {
    if (kIsWeb) { return addImagenDesdeGaleria(); }
    final XFile? xfile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (xfile == null) return;
    if (!_canAdd(TipoMultimedia.imagen)) return;
    _queueUpload(tipo: TipoMultimedia.imagen, file: File(xfile.path), displayName: xfile.name);
  }

  Future<void> addDesdeArchivos() async {
    await _ensureCurrentUser();
    // Solo admin con categoría Libro puede subir documentos (pdf/epub/doc/docx/rtf/txt)
    bool isLibro = false;
    try {
      final c = categorias.firstWhere((c) => c.id == categoriaId);
      final name = c.nombre.toLowerCase();
      isLibro = (name == 'libro' || name == 'libros');
    } catch (_) {}
    final bool allowDocs = _currentUserIsAdmin && isLibro;
    final allowedExtensions = [
      ...TipoMultimedia.imagen.extensionesPermitidas,
      ...TipoMultimedia.video.extensionesPermitidas,
      ...TipoMultimedia.audio.extensionesPermitidas,
      if (allowDocs) ...TipoMultimedia.documento.extensionesPermitidas,
    ];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: allowedExtensions,
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
      } else if (TipoMultimedia.audio.extensionesPermitidas.any((e) => name.endsWith('.$e'))) {
        tipo = TipoMultimedia.audio;
      } else {
        // Documento: sólo si allowDocs
        if (!allowDocs) continue;
        tipo = TipoMultimedia.documento;
      }
      if (!_canAdd(tipo)) continue;
      if (kIsWeb) {
        if (file.bytes == null) continue;
        _queueUploadBytes(tipo: tipo, bytes: file.bytes!, displayName: file.name);
      } else {
        if (file.path == null) continue;
        _queueUpload(tipo: tipo, file: File(file.path!), displayName: file.name);
      }
    }
  }

  bool _grabando = false;
  bool get grabando => _grabando;

  Future<void> iniciarGrabacionAudio() async {
    if (kIsWeb) return; // degradar en web
    if (!_canAdd(TipoMultimedia.audio)) return;
    if (await _recorder.hasPermission()) {
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
    if (!_canAdd(TipoMultimedia.audio)) return;
    final file = File(path);
    _queueUpload(tipo: TipoMultimedia.audio, file: file, displayName: path.split('/').last);
  }

  void eliminarMedia(String id) {
    uploads.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  // Límites por tipo alineados a ContenidoValidator
  bool _canAdd(TipoMultimedia tipo) {
    final imagenes = uploads.where((u) => u.tipo == TipoMultimedia.imagen && u.status != SaberUploadStatus.cancelled).length;
    final videos = uploads.where((u) => u.tipo == TipoMultimedia.video && u.status != SaberUploadStatus.cancelled).length;
    final audios = uploads.where((u) => u.tipo == TipoMultimedia.audio && u.status != SaberUploadStatus.cancelled).length;
    final docs = uploads.where((u) => u.tipo == TipoMultimedia.documento && u.status != SaberUploadStatus.cancelled).length;
    switch (tipo) {
      case TipoMultimedia.imagen:
        return imagenes < ContenidoValidator.MAX_IMAGENES;
      case TipoMultimedia.video:
        return videos < ContenidoValidator.MAX_VIDEOS;
      case TipoMultimedia.audio:
        return audios < ContenidoValidator.MAX_AUDIOS;
      case TipoMultimedia.documento:
        return docs < ContenidoValidator.MAX_DOCUMENTOS;
    }
  }

  void _queueUpload({required TipoMultimedia tipo, required File file, String? displayName}) {
    final item = SaberMediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      tipo: tipo,
      file: file,
      status: SaberUploadStatus.queued,
      progress: 0,
      displayName: displayName,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  void _queueUploadBytes({required TipoMultimedia tipo, required Uint8List bytes, String? displayName}) {
    final item = SaberMediaUploadItem(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      tipo: tipo,
      bytes: bytes,
      status: SaberUploadStatus.queued,
      progress: 0,
      displayName: displayName,
    );
    uploads.add(item);
    notifyListeners();
    _uploadInBackground(item);
  }

  Future<void> _uploadInBackground(SaberMediaUploadItem item) async {
    if (_currentUserId == null) {
      final current = await _useCases.auth.getCurrentUser.execute();
      _currentUserId = current.valueOrNull?.id;
    }
    if (item.file == null && item.bytes == null) return;
    item.status = SaberUploadStatus.uploading;
    item.progress = 5;
    notifyListeners();

    try {
      final client = http.Client();
      _clientsByUpload[item.id] = client;
      final ds = CloudinaryStorageDataSourceImpl(basePath: 'saberes/${_currentUserId ?? 'anon'}', client: client);
      final String ext = () {
        switch (item.tipo) {
          case TipoMultimedia.imagen: return 'jpg';
          case TipoMultimedia.audio: return 'm4a';
          case TipoMultimedia.video: return 'mp4';
          case TipoMultimedia.documento: return 'pdf';
        }
      }();
      final String contentType = () {
        switch (item.tipo) {
          case TipoMultimedia.imagen: return 'image/jpeg';
          case TipoMultimedia.audio: return 'audio/aac';
          case TipoMultimedia.video: return 'video/mp4';
          case TipoMultimedia.documento: return 'application/octet-stream';
        }
      }();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

      final progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (item.progress < 90 && item.status == SaberUploadStatus.uploading) {
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
      item.status = SaberUploadStatus.done;
      notifyListeners();
    } catch (e) {
      item.error = e.toString();
      item.status = SaberUploadStatus.error;
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
      uploads[idx].status = SaberUploadStatus.cancelled;
      uploads[idx].progress = 0;
      notifyListeners();
    }
  }

  void retryUpload(String id) {
    final idx = uploads.indexWhere((u) => u.id == id);
    if (idx == -1) return;
    final item = uploads[idx];
    if (item.file == null && item.bytes == null) return;
    item.status = SaberUploadStatus.queued;
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
    // Aplicar política de ubicación por categoría antes de enviar
    _applyLocationPolicy();
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      errorMessage = 'Debes iniciar sesión para publicar.';
      notifyListeners();
      return false;
    }
    debugPrint('[SABER_FORM][INICIO_SUBMIT] t=' + DateTime.now().toIso8601String());
    isPublishing = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Recolectar multimedia listos por tipo
      final imagenes = uploads
          .where((u) => u.tipo == TipoMultimedia.imagen && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final audios = uploads
          .where((u) => u.tipo == TipoMultimedia.audio && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final videos = uploads
          .where((u) => u.tipo == TipoMultimedia.video && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final documentos = uploads
          .where((u) => u.tipo == TipoMultimedia.documento && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();

      debugPrint('[SABER_FORM][MEDIA_OK] imgs=' + imagenes.length.toString() + ' auds=' + audios.length.toString() + ' vids=' + videos.length.toString() + ' docs=' + documentos.length.toString());

      // Ubicación por defecto si no eligió
      String? dep = departamento;
      String? mun = municipio;
      double? lat = latitud;
      double? lng = longitud;
      if (dep == null || mun == null) {
        try {
          if (_getIt.isRegistered<IGeolocationService>()) {
            final geo = _getIt<IGeolocationService>();
            final ub = await geo.obtenerUbicacionActual();
            dep = ub.departamento;
            mun = ub.municipio;
            lat = ub.latitud;
            lng = ub.longitud;
          }
        } catch (_) {}
      }

      final res = isEditing && saberId != null
          ? await _useCases.saberes.actualizar.execute(
              saberId: saberId!,
              usuarioId: _currentUserId!,
              titulo: titulo.trim(),
              contenido: contenido.trim(),
              categoriaId: categoriaId!,
              departamento: dep,
              municipio: mun,
              latitud: lat,
              longitud: lng,
              // Solo reemplazar multimedia si el usuario agregó nuevas subidas
              imagenesUrls: (imagenes.isNotEmpty || audios.isNotEmpty || videos.isNotEmpty || documentos.isNotEmpty) ? imagenes : null,
              audiosUrls: (imagenes.isNotEmpty || audios.isNotEmpty || videos.isNotEmpty || documentos.isNotEmpty) ? audios : null,
              videosUrls: (imagenes.isNotEmpty || audios.isNotEmpty || videos.isNotEmpty || documentos.isNotEmpty) ? videos : null,
              documentosUrls: (imagenes.isNotEmpty || audios.isNotEmpty || videos.isNotEmpty || documentos.isNotEmpty) ? documentos : null,
              etiquetas: List.of(etiquetas),
            )
          : await _useCases.saberes.crear.execute(
              titulo: titulo.trim(),
              contenido: contenido.trim(),
              autorId: _currentUserId!,
              categoriaId: categoriaId!,
              departamento: dep,
              municipio: mun,
              latitud: lat,
              longitud: lng,
              imagenesUrls: imagenes,
              audiosUrls: audios,
              videosUrls: videos,
              documentosUrls: documentos,
              etiquetas: List.of(etiquetas),
            );

      isPublishing = false;
      bool queuedOffline = false;
      if (res.isFailure) {
        final failure = res.errorOrNull;
        if (failure is NetworkFailure) {
          queuedOffline = true;
        }
        debugPrint('[SABER_FORM][USECASE_FAIL] code=' + (failure?.code ?? 'null') + ' msg=' + (failure?.message ?? ''));
      }
      lastPublishOffline = queuedOffline;
      if (!isEditing && res.isSuccess) {
        final created = (res as Result<SaberPopular, Failure>).valueOrNull;
        lastCreatedSaber = created;
        debugPrint('[SABER_FORM][USECASE_OK] createdId=' + (created?.id ?? 'null'));
      }
      if (res.isFailure && !queuedOffline) {
        errorMessage = res.errorOrNull?.message ?? 'No se pudo publicar el saber popular.';
        notifyListeners();
        return false;
      }
      if (queuedOffline) {
        debugPrint('[SABER_FORM][OFFLINE_ENQUEUED]');
      }
      notifyListeners();
      return res.isSuccess || queuedOffline;
    } catch (e) {
      isPublishing = false;
      errorMessage = e.toString();
      debugPrint('[SABER_FORM][ERROR] ' + e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureCurrentUser() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      final current = await _useCases.auth.getCurrentUser.execute();
      _currentUserId = current.valueOrNull?.id;
      try {
        _currentUserIsAdmin = (current.valueOrNull?.rol.value == 'admin');
      } catch (_) {
        _currentUserIsAdmin = false;
      }
      // Si ya tenemos categorías en caché, re-aplicar filtro con el rol correcto
      if (_memCacheCategorias.isNotEmpty) {
        categorias = _filtrarCategoriasPorRol(_memCacheCategorias)..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        _notify();
      }
    }
  }

  List<Categoria> _filtrarCategoriasPorRol(List<Categoria> data) {
    if (_currentUserIsAdmin) return List.of(data);
    // Ocultar categoría "Libro" para no admin
    return data.where((c) => c.nombre.toLowerCase() != 'libro' && c.nombre.toLowerCase() != 'libros').toList();
  }

  // Construye un Saber mínimo usando el estado del formulario para UI optimista
  SaberPopular? saberConstruidoMinimo() {
    try {
      if (_currentUserId == null || categoriaId == null) return null;
      final imagenes = uploads
          .where((u) => u.tipo == TipoMultimedia.imagen && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final audios = uploads
          .where((u) => u.tipo == TipoMultimedia.audio && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final videos = uploads
          .where((u) => u.tipo == TipoMultimedia.video && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();
      final documentos = uploads
          .where((u) => u.tipo == TipoMultimedia.documento && u.status == SaberUploadStatus.done && (u.url?.isNotEmpty ?? false))
          .map((u) => u.url!)
          .toList();

      final List<Multimedia> multimedia = [];
      for (final url in imagenes) { multimedia.add(Multimedia(url: url, tipo: TipoMultimedia.imagen)); }
      for (final url in audios) { multimedia.add(Multimedia(url: url, tipo: TipoMultimedia.audio)); }
      for (final url in videos) { multimedia.add(Multimedia(url: url, tipo: TipoMultimedia.video)); }
      for (final url in documentos) { multimedia.add(Multimedia(url: url, tipo: TipoMultimedia.documento)); }

      String catNombre = 'Saber';
      for (final c in categorias) { if (c.id == categoriaId) { catNombre = c.nombre; break; } }

      return SaberPopular.crear(
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
        imagenes: multimedia,
        etiquetas: List.of(etiquetas),
      );
    } catch (_) { return null; }
  }

  // Construye versión editada mínima conservando el ID
  SaberPopular? saberEditadoMinimo() {
    try {
      if (!isEditing || saberId == null || _originalSaber == null || categoriaId == null) return null;
      final SaberPopular base = _originalSaber!;
      String categoriaNombreFinal = base.categoriaNombre;
      final String selCatId = categoriaId!;
      for (final c in categorias) { if (c.id == selCatId) { categoriaNombreFinal = c.nombre; break; } }

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

      return base.copyWith(
        titulo: titulo.trim(),
        contenido: contenido.trim(),
        categoriaId: selCatId,
        categoriaNombre: categoriaNombreFinal,
        ubicacion: ubic,
        etiquetas: List.of(etiquetas.isEmpty ? base.etiquetas : etiquetas),
        fechaActualizacion: DateTime.now().toUtc(),
      );
    } catch (_) { return null; }
  }
}


