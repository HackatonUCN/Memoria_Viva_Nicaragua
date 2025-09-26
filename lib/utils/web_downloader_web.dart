// Only compiled on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> triggerWebDownload(String url, {String? fileName}) async {
  // Forzar descarga en lugar de abrir en la misma pestaña
  // 1. Asegurar que tiene download attribute (esto fuerza descarga)
  // 2. Usar target='_self' para descargar en la misma pestaña
  // 3. Remover el ancla inmediatamente después de hacer click
  
  // Mostrar log para depuración
  print('[WebDownloader] Downloading: $url with filename: ${fileName ?? "(none)"} ');
  
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName ?? ''
    ..target = '_self'; // Usar _self para evitar abrir nueva pestaña
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}


