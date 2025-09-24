/// Mapeo de coordenadas para departamentos y municipios de Nicaragua
/// Coordenadas aproximadas del centro de cada ubicación
class NicaraguaCoordinates {
  
  /// Coordenadas de departamentos (centro aproximado)
  static const Map<String, Map<String, double>> departamentos = {
    'Nacional': {'lat': 12.8654, 'lng': -85.2072}, // Centro geográfico de Nicaragua
    'Boaco': {'lat': 12.4722, 'lng': -85.6586},
    'Carazo': {'lat': 11.8444, 'lng': -86.2056},
    'Chinandega': {'lat': 12.6294, 'lng': -87.1328},
    'Chontales': {'lat': 12.0494, 'lng': -85.1833},
    'Estelí': {'lat': 13.0919, 'lng': -86.3536},
    'Granada': {'lat': 11.9342, 'lng': -85.9558},
    'Jinotega': {'lat': 13.0919, 'lng': -86.0031},
    'León': {'lat': 12.4353, 'lng': -86.8772},
    'Madriz': {'lat': 13.4731, 'lng': -86.4597},
    'Managua': {'lat': 12.1364, 'lng': -86.2514},
    'Masaya': {'lat': 11.9736, 'lng': -86.0931},
    'Matagalpa': {'lat': 12.9253, 'lng': -85.9175},
    'Nueva Segovia': {'lat': 13.7847, 'lng': -86.1194},
    'Rivas': {'lat': 11.4372, 'lng': -85.8264},
    'Río San Juan': {'lat': 11.1167, 'lng': -84.7833},
    'RAAN': {'lat': 14.0272, 'lng': -83.3828}, // Región Autónoma Atlántico Norte
    'RAAS': {'lat': 12.1628, 'lng': -83.7597}, // Región Autónoma Atlántico Sur
  };

  /// Coordenadas de municipios principales por departamento
  static const Map<String, Map<String, Map<String, double>>> municipios = {
    'Nacional': {
      'Nicaragua': {'lat': 12.8654, 'lng': -85.2072}, // Centro geográfico de Nicaragua
    },
    'Boaco': {
      'Boaco': {'lat': 12.4722, 'lng': -85.6586},
      'Camoapa': {'lat': 12.3833, 'lng': -85.5167},
      'San José de los Remates': {'lat': 12.5833, 'lng': -85.8667},
      'San Lorenzo': {'lat': 12.3833, 'lng': -85.6667},
      'Santa Lucía': {'lat': 12.5333, 'lng': -85.7167},
      'Teustepe': {'lat': 12.4167, 'lng': -85.7833},
    },
    'Chontales': {
      'Juigalpa': {'lat': 12.1067, 'lng': -85.3644},
      'Acoyapa': {'lat': 11.9667, 'lng': -85.1667},
      'Comalapa': {'lat': 12.2833, 'lng': -85.5167},
      'Cuapa': {'lat': 12.2667, 'lng': -85.3833},
      'El Coral': {'lat': 12.1333, 'lng': -85.2833},
      'La Libertad': {'lat': 12.2167, 'lng': -85.1667},
      'San Francisco de Cuapa': {'lat': 12.2667, 'lng': -85.3833},
      'San Pedro de Lóvago': {'lat': 12.0667, 'lng': -85.2333},
      'Santo Domingo': {'lat': 12.2667, 'lng': -85.0833},
      'Santo Tomás': {'lat': 12.0667, 'lng': -85.0833},
    },
    'Jinotega': {
      'Jinotega': {'lat': 13.0919, 'lng': -86.0031},
      'El Cuá': {'lat': 13.4167, 'lng': -85.7500},
      'La Concordia': {'lat': 13.1833, 'lng': -85.8167},
      'San José de Bocay': {'lat': 13.5500, 'lng': -85.6167},
      'San Rafael del Norte': {'lat': 13.2167, 'lng': -86.1167},
      'San Sebastián de Yalí': {'lat': 13.3000, 'lng': -86.1833},
      'Santa María de Pantasma': {'lat': 13.2833, 'lng': -85.9333},
      'Wiwilí de Jinotega': {'lat': 13.6167, 'lng': -85.8167},
    },
    'Matagalpa': {
      'Matagalpa': {'lat': 12.9253, 'lng': -85.9175},
      'Ciudad Darío': {'lat': 12.7333, 'lng': -86.1167},
      'El Tuma - La Dalia': {'lat': 13.1167, 'lng': -85.7167},
      'Esquipulas': {'lat': 13.0833, 'lng': -86.0333},
      'Matiguás': {'lat': 12.8333, 'lng': -85.4667},
      'Muy Muy': {'lat': 12.7667, 'lng': -85.6333},
      'Rancho Grande': {'lat': 12.9167, 'lng': -85.6167},
      'Río Blanco': {'lat': 12.9333, 'lng': -85.2167},
      'San Dionisio': {'lat': 12.7667, 'lng': -86.0500},
      'San Isidro': {'lat': 12.6000, 'lng': -85.8833},
      'San Ramón': {'lat': 12.9167, 'lng': -85.8500},
      'Sébaco': {'lat': 12.8500, 'lng': -86.1000},
      'Terrabona': {'lat': 12.8167, 'lng': -86.1333},
    },
    'Río San Juan': {
      'San Carlos': {'lat': 11.1167, 'lng': -84.7833},
      'El Castillo': {'lat': 11.0167, 'lng': -84.4167},
      'Morrito': {'lat': 11.4167, 'lng': -85.1167},
      'San Juan de Nicaragua': {'lat': 10.9167, 'lng': -83.7000},
      'San Miguelito': {'lat': 11.3500, 'lng': -84.8667},
    },
    'RAAN': {
      'Bilwi': {'lat': 14.0272, 'lng': -83.3828},
      'Bonanza': {'lat': 13.9500, 'lng': -84.5833},
      'Prinzapolka': {'lat': 13.4167, 'lng': -83.5833},
      'Rosita': {'lat': 13.9167, 'lng': -84.4000},
      'Siuna': {'lat': 13.7333, 'lng': -84.7667},
      'Waslala': {'lat': 13.3333, 'lng': -85.3667},
      'Waspam': {'lat': 14.7333, 'lng': -83.9667},
    },
    'RAAS': {
      'Bluefields': {'lat': 12.0092, 'lng': -83.7597},
      'Corn Island': {'lat': 12.1628, 'lng': -83.0628},
      'Desembocadura de la Cruz de Río Grande': {'lat': 11.8167, 'lng': -83.9167},
      'El Ayote': {'lat': 12.0833, 'lng': -85.1167},
      'El Rama': {'lat': 12.1597, 'lng': -84.2197},
      'El Tortuguero': {'lat': 12.8167, 'lng': -83.7167},
      'Kukra Hill': {'lat': 12.2333, 'lng': -83.7500},
      'La Cruz de Río Grande': {'lat': 11.9167, 'lng': -84.1667},
      'Laguna de Perlas': {'lat': 12.3433, 'lng': -83.6717},
      'Muelle de los Bueyes': {'lat': 12.0667, 'lng': -84.5500},
      'Nueva Guinea': {'lat': 11.6833, 'lng': -84.4500},
      'Paiwas': {'lat': 12.7833, 'lng': -85.0167},
    },
    'Managua': {
      'Managua': {'lat': 12.1364, 'lng': -86.2514},
      'Ciudad Sandino': {'lat': 12.1581, 'lng': -86.3444},
      'El Crucero': {'lat': 11.9922, 'lng': -86.3097},
      'Mateare': {'lat': 12.1833, 'lng': -86.4167},
      'San Francisco Libre': {'lat': 12.4167, 'lng': -86.0833},
      'San Rafael del Sur': {'lat': 11.8478, 'lng': -86.4381},
      'Ticuantepe': {'lat': 12.0297, 'lng': -86.2053},
      'Tipitapa': {'lat': 12.1975, 'lng': -86.0972},
      'Villa Carlos Fonseca': {'lat': 12.1167, 'lng': -86.1833},
    },
    'León': {
      'León': {'lat': 12.4353, 'lng': -86.8772},
      'Achuapa': {'lat': 13.0500, 'lng': -86.5833},
      'El Jicaral': {'lat': 12.7167, 'lng': -86.8833},
      'El Sauce': {'lat': 12.8833, 'lng': -86.5333},
      'La Paz Centro': {'lat': 12.3400, 'lng': -86.6747},
      'Larreynaga': {'lat': 12.6833, 'lng': -86.5667},
      'Nagarote': {'lat': 12.2664, 'lng': -86.5650},
      'Quezalguaque': {'lat': 12.5167, 'lng': -86.9000},
      'Santa Rosa del Peñón': {'lat': 12.7833, 'lng': -86.3500},
      'Telica': {'lat': 12.6019, 'lng': -86.8642},
    },
    'Granada': {
      'Granada': {'lat': 11.9342, 'lng': -85.9558},
      'Diriá': {'lat': 11.8833, 'lng': -86.0500},
      'Diriomo': {'lat': 11.8761, 'lng': -86.0539},
      'Nandaime': {'lat': 11.7575, 'lng': -86.0525},
    },
    'Masaya': {
      'Masaya': {'lat': 11.9736, 'lng': -86.0931},
      'Catarina': {'lat': 11.9158, 'lng': -86.0781},
      'La Concepción': {'lat': 11.9367, 'lng': -86.1892},
      'Masatepe': {'lat': 11.9181, 'lng': -86.1444},
      'Nandasmo': {'lat': 11.9167, 'lng': -86.0667},
      'Nindirí': {'lat': 12.0019, 'lng': -86.1194},
      'Niquinohomo': {'lat': 11.9050, 'lng': -86.0942},
      'San Juan de Oriente': {'lat': 11.9058, 'lng': -86.0644},
      'Tisma': {'lat': 12.0833, 'lng': -86.0167},
    },
    'Carazo': {
      'Jinotepe': {'lat': 11.8500, 'lng': -86.2000},
      'Diriamba': {'lat': 11.8583, 'lng': -86.2392},
      'Dolores': {'lat': 11.8500, 'lng': -86.2167},
      'El Rosario': {'lat': 11.7667, 'lng': -86.3667},
      'La Conquista': {'lat': 11.7333, 'lng': -86.1833},
      'La Paz de Carazo': {'lat': 11.8167, 'lng': -86.1333},
      'San Marcos': {'lat': 11.9097, 'lng': -86.2042},
      'Santa Teresa': {'lat': 11.7500, 'lng': -86.2167},
    },
    'Rivas': {
      'Rivas': {'lat': 11.4372, 'lng': -85.8264},
      'Altagracia': {'lat': 11.5500, 'lng': -85.5667},
      'Belén': {'lat': 11.5000, 'lng': -85.8833},
      'Buenos Aires': {'lat': 11.4667, 'lng': -85.8167},
      'Cárdenas': {'lat': 11.0667, 'lng': -85.2833},
      'Moyogalpa': {'lat': 11.5392, 'lng': -85.6919},
      'Potosí': {'lat': 11.4942, 'lng': -85.8575},
      'San Jorge': {'lat': 11.4519, 'lng': -85.8036},
      'San Juan del Sur': {'lat': 11.2531, 'lng': -85.8706},
      'Tola': {'lat': 11.4333, 'lng': -85.9500},
    },
    'Chinandega': {
      'Chinandega': {'lat': 12.6294, 'lng': -87.1328},
      'Chichigalpa': {'lat': 12.5775, 'lng': -87.0267},
      'Cinco Pinos': {'lat': 13.2167, 'lng': -86.8833},
      'Corinto': {'lat': 12.4828, 'lng': -87.1731},
      'El Realejo': {'lat': 12.5419, 'lng': -87.1661},
      'El Viejo': {'lat': 12.6631, 'lng': -87.1664},
      'Posoltega': {'lat': 12.5444, 'lng': -86.9736},
      'Puerto Morazán': {'lat': 12.8500, 'lng': -87.1667},
      'San Francisco del Norte': {'lat': 13.2167, 'lng': -86.7000},
      'San Pedro del Norte': {'lat': 13.0167, 'lng': -86.8167},
      'Santo Tomás del Norte': {'lat': 13.1833, 'lng': -86.9167},
      'Somotillo': {'lat': 13.0439, 'lng': -86.9058},
      'Villanueva': {'lat': 12.9167, 'lng': -86.8833},
    },
    'Estelí': {
      'Estelí': {'lat': 13.0919, 'lng': -86.3536},
      'Condega': {'lat': 13.3650, 'lng': -86.3983},
      'La Trinidad': {'lat': 13.0333, 'lng': -86.2333},
      'Pueblo Nuevo': {'lat': 13.3833, 'lng': -86.4833},
      'San Juan de Limay': {'lat': 13.1667, 'lng': -86.6167},
      'San Nicolás': {'lat': 13.5167, 'lng': -86.5167},
    },
    'Madriz': {
      'Somoto': {'lat': 13.4731, 'lng': -86.5825},
      'Las Sabanas': {'lat': 13.3333, 'lng': -86.3667},
      'Palacagüina': {'lat': 13.4500, 'lng': -86.4000},
      'San José de Cusmapa': {'lat': 13.3167, 'lng': -86.6000},
      'San Juan de Río Coco': {'lat': 13.5333, 'lng': -86.1667},
      'San Lucas': {'lat': 13.4000, 'lng': -86.7167},
      'Telpaneca': {'lat': 13.5167, 'lng': -86.2833},
      'Totogalpa': {'lat': 13.5500, 'lng': -86.4833},
      'Yalagüina': {'lat': 13.6167, 'lng': -86.4833},
    },
    'Nueva Segovia': {
      'Ocotal': {'lat': 13.6350, 'lng': -86.4750},
      'Ciudad Antigua': {'lat': 13.7833, 'lng': -86.2500},
      'Dipilto': {'lat': 13.7167, 'lng': -86.2000},
      'El Jícaro': {'lat': 13.7333, 'lng': -86.1167},
      'Jalapa': {'lat': 13.9167, 'lng': -86.1167},
      'Macuelizo': {'lat': 13.6833, 'lng': -86.0833},
      'Mozonte': {'lat': 13.6500, 'lng': -86.0167},
      'Murra': {'lat': 13.6833, 'lng': -86.4167},
      'Quilalí': {'lat': 13.5667, 'lng': -86.0333},
      'San Fernando': {'lat': 13.6333, 'lng': -86.3167},
      'Santa María': {'lat': 13.8333, 'lng': -86.2833},
      'Wiwilí de Nueva Segovia': {'lat': 13.6167, 'lng': -85.8167},
    },
  };

  /// Obtiene las coordenadas de un departamento
  static Map<String, double>? getDepartamentoCoordinates(String departamento) {
    return departamentos[departamento];
  }

  /// Obtiene las coordenadas de un municipio específico
  static Map<String, double>? getMunicipioCoordinates(String departamento, String municipio) {
    final depMunicipios = municipios[departamento];
    if (depMunicipios == null) return null;
    return depMunicipios[municipio];
  }

  /// Obtiene las coordenadas más específicas disponibles
  /// Prioriza municipio > departamento > coordenadas por defecto de Managua
  static Map<String, double> getBestCoordinates(String? departamento, String? municipio) {
    if (departamento == null || departamento.isEmpty) {
      // Fallback a Managua si no hay departamento
      return {'lat': 12.1364, 'lng': -86.2514};
    }

    // Intentar obtener coordenadas del municipio específico
    if (municipio != null && municipio.isNotEmpty) {
      final municipioCoords = getMunicipioCoordinates(departamento, municipio);
      if (municipioCoords != null) {
        return municipioCoords;
      }
    }

    // Fallback a coordenadas del departamento
    final departamentoCoords = getDepartamentoCoordinates(departamento);
    if (departamentoCoords != null) {
      return departamentoCoords;
    }

    // Último fallback a Managua
    return {'lat': 12.1364, 'lng': -86.2514};
  }

  /// Verifica si las coordenadas están dentro de Nicaragua
  static bool isInNicaragua(double lat, double lng) {
    return lat >= 10.7 && lat <= 15.0 && lng >= -87.7 && lng <= -83.1;
  }
}
