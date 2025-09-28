// Web-aware download helper with conditional imports

import 'cloudinary_url.dart';
import 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart' as impl;
import '../core/config/environment.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

String _buildProxyUrl({String? url, String? publicId, String? fileName, String resourceType = 'raw', String format = 'pdf'}) {
  final base = Environment.DOWNLOAD_PROXY_BASE_URL;
  if (base.isEmpty) return '';
  final buf = StringBuffer();
  buf.write(base);
  if (!base.endsWith('/')) buf.write('/');
  buf.write('download?');
  if (publicId != null && publicId.isNotEmpty) {
    buf.write('id=${Uri.encodeComponent(publicId)}&rt=$resourceType&format=$format');
  } else if (url != null && url.isNotEmpty) {
    buf.write('url=${Uri.encodeComponent(url)}');
  }
  if (fileName != null && fileName.isNotEmpty) {
    buf.write('&filename=${Uri.encodeComponent(fileName)}');
  }
  // Log para depuración
  print('[WebDownloader] Proxy URL: ${buf.toString()}');
  return buf.toString();
}

Future<void> triggerWebDownload(String url, {String? fileName, String? publicId}) async {
  // Prefer proxy when configured, otherwise direct
  if (kIsWeb && Environment.DOWNLOAD_PROXY_BASE_URL.isNotEmpty) {
    // Usar siempre url= para evitar rutas que disparen demasiadas subrequests en el worker
    final proxy = _buildProxyUrl(url: url, fileName: fileName);
    if (proxy.isNotEmpty) {
      print('[WebDownloader] Using proxy with direct URL: $proxy');
      return impl.triggerWebDownload(proxy, fileName: fileName);
    }
  }

  print('[WebDownloader] Using direct URL: $url');
  return impl.triggerWebDownload(url, fileName: fileName);
}


