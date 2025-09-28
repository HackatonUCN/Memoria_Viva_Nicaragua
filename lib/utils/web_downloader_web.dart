// Only compiled on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> triggerWebDownload(String url, {String? fileName}) async {
  // Forzar descarga en lugar de abrir en la misma pestaña
  // 1. Asegurar que tiene download attribute (esto fuerza descarga)
  // 2. Usar target='_blank' para abrir en nueva pestaña (evita problemas con navegación)
  // 3. Remover el ancla inmediatamente después de hacer click
  
  // Mostrar log para depuración
  print('[WebDownloader] Downloading: $url with filename: ${fileName ?? "(none)"} ');
  
  // Intentar usar fetch API primero para forzar descarga con Content-Disposition
  try {
    final response = await html.window.fetch(url, {
      'method': 'GET',
      'mode': 'cors',
      'cache': 'no-cache',
    });
    
    if (response.status == 200) {
      final blob = await response.blob();
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: blobUrl)
        ..style.display = 'none'
        ..download = fileName ?? 'documento.pdf'
        ..target = '_blank';
      
      html.document.body?.append(anchor);
      anchor.click();
      
      // Limpiar
      Future.delayed(const Duration(seconds: 1), () {
        anchor.remove();
        html.Url.revokeObjectUrl(blobUrl);
      });
      
      return;
    }
  } catch (e) {
    print('[WebDownloader] Fetch error: $e, falling back to anchor');
  }
  
  // Fallback: usar anchor tradicional
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..target = '_blank';
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}


