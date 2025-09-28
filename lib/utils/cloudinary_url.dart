String addCloudinaryFlag(String url, String flag) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('res.cloudinary.com')) return url;
    final segments = List<String>.from(uri.pathSegments);
    final uploadIdx = segments.indexOf('upload');
    if (uploadIdx == -1) return url;

    final nextIdx = uploadIdx + 1;
    if (nextIdx >= segments.length) {
      segments.add(flag);
    } else {
      final next = segments[nextIdx];
      // Cloudinary version segments look like v123456789
      final bool isVersion = RegExp(r'^v\d+$').hasMatch(next);
      if (isVersion || next.isEmpty) {
        // Insert flag before version or when empty
        segments.insert(nextIdx, flag);
      } else {
        // There is already a transformation segment
        if (!next.contains(flag)) {
          segments[nextIdx] = next.contains(',') ? '$next,$flag' : '$next,$flag';
        }
      }
    }
    return uri.replace(pathSegments: segments).toString();
  } catch (_) {
    return url;
  }
}

String ensureAttachment(String url) => addCloudinaryFlag(url, 'fl_attachment');


/// Best-effort fix for malformed Cloudinary RAW URLs that contain duplicated
/// "/something.pdf/<id>.pdf" segments. Keeps only the last ".pdf" segment.
String sanitizeCloudinaryRawPdfUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('res.cloudinary.com')) return url;
    final segments = List<String>.from(uri.pathSegments);
    final uploadIdx = segments.indexOf('upload');
    if (uploadIdx == -1) return url;
    // Collect indexes of segments that end with .pdf after the upload segment
    final pdfIdxs = <int>[];
    for (int i = uploadIdx + 1; i < segments.length; i++) {
      if (segments[i].toLowerCase().endsWith('.pdf')) {
        pdfIdxs.add(i);
      }
    }
    if (pdfIdxs.length <= 1) return url; // nothing to sanitize
    // Keep only the last .pdf segment, remove earlier ones
    final keep = pdfIdxs.last;
    for (int i = pdfIdxs.length - 2; i >= 0; i--) {
      final idx = pdfIdxs[i];
      if (idx >= 0 && idx < segments.length) {
        segments.removeAt(idx);
      }
    }
    final newUri = uri.replace(pathSegments: segments);
    return newUri.toString();
  } catch (_) {
    return url;
  }
}

/// Derive Cloudinary public_id (without extension) from a secure_url.
/// Works for URLs like:
///   https://res.cloudinary.com/<cloud>/<resourceType>/upload/v123/<folders>/<name>.pdf
///   https://res.cloudinary.com/<cloud>/raw/upload/<folders>/<maybe.pdf>/<id>.pdf
String? derivePublicIdFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    if (!uri.host.contains('res.cloudinary.com')) return null;
    final segments = List<String>.from(uri.pathSegments);
    final uploadIdx = segments.indexOf('upload');
    if (uploadIdx == -1) return null;
    List<String> after = segments.sublist(uploadIdx + 1);
    if (after.isEmpty) return null;
    // Strip version segment v123 if present
    if (RegExp(r'^v\d+$').hasMatch(after.first)) {
      after = after.sublist(1);
    }
    if (after.isEmpty) return null;
    // Remove any trailing .pdf from intermediates
    after = after
        .map((s) => s.toLowerCase().endsWith('.pdf') ? s.substring(0, s.length - 4) : s)
        .toList(growable: false);
    // Remove extension from last if still present
    final last = after.last;
    final dot = last.lastIndexOf('.');
    final lastNoExt = dot > 0 ? last.substring(0, dot) : last;
    final pathParts = <String>[];
    if (after.length > 1) {
      pathParts.addAll(after.sublist(0, after.length - 1));
    }
    pathParts.add(lastNoExt);
    return pathParts.join('/');
  } catch (_) {
    return null;
  }
}


