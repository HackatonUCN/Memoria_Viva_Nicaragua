import 'dart:convert';

import 'package:http/http.dart' as http;

class NominatimResult {
  final String? departamento;
  final String? municipio;

  const NominatimResult({this.departamento, this.municipio});
}

class NominatimGeocodingService {
  static const String _baseHost = 'nominatim.openstreetmap.org';

  Future<NominatimResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(_baseHost, '/reverse', {
      'format': 'jsonv2',
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'addressdetails': '1',
      'accept-language': 'es',
      // Opcional: limitar país si quieres forzar Nicaragua
      // 'countrycodes': 'ni',
    });

    final resp = await http.get(
      uri,
      headers: const {
        // Nominatim requiere un User-Agent identificable
        'User-Agent': 'MemoriaVivaNicaragua/1.0 (geocoding)',
      },
    );

    if (resp.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final address = (data['address'] ?? const {}) as Map<String, dynamic>;

    final String? state = _pickFirstNonEmpty([
      address['state'],
      address['state_district'],
      address['region'],
    ]);

    final String? municipality = _pickFirstNonEmpty([
      address['municipality'],
      address['city'],
      address['town'],
      address['village'],
      address['county'],
    ]);

    return NominatimResult(
      departamento: state,
      municipio: municipality,
    );
  }

  String? _pickFirstNonEmpty(List<dynamic> candidates) {
    for (final item in candidates) {
      if (item is String && item.trim().isNotEmpty) return item.trim();
    }
    return null;
  }
}


