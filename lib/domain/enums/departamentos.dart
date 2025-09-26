/// Departamentos de Nicaragua
enum Departamento {
  nacional('Nacional'), // Para eventos de toda Nicaragua
  boaco('Boaco'),
  carazo('Carazo'),
  chinandega('Chinandega'),
  chontales('Chontales'),
  esteli('Estelí'),
  granada('Granada'),
  jinotega('Jinotega'),
  leon('León'),
  madriz('Madriz'),
  managua('Managua'),
  masaya('Masaya'),
  matagalpa('Matagalpa'),
  nuevaSegovia('Nueva Segovia'),
  raccs('RACCS'), // Región Autónoma de la Costa Caribe Sur
  raccn('RACCN'), // Región Autónoma de la Costa Caribe Norte
  rioSanJuan('Río San Juan'),
  rivas('Rivas');

  final String nombre;
  const Departamento(this.nombre);

  /// Obtiene el departamento desde un string
  static Departamento? fromString(String nombre) {
    try {
      return Departamento.values.firstWhere(
        (d) => d.nombre.toLowerCase() == nombre.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Municipios por departamento
const municipiosPorDepartamento = {
  'nacional': [
    'Nicaragua', // Para eventos que abarcan todo el país
  ],
  'managua': [
    'Managua',
    'Ciudad Sandino',
    'El Crucero',
    'Mateare',
    'San Francisco Libre',
    'San Rafael del Sur',
    'Ticuantepe',
    'Tipitapa',
    'Villa El Carmen',
  ],
  'león': [
    'León',
    'Achuapa',
    'El Jicaral',
    'El Sauce',
    'La Paz Centro',
    'Larreynaga',
    'Nagarote',
    'Quezalguaque',
    'Santa Rosa del Peñón',
    'Telica',
  ],
  'masaya': [
    'Masaya',
    'Catarina',
    'La Concepción',
    'Masatepe',
    'Nandasmo',
    'Nindirí',
    'Niquinohomo',
    'San Juan de Oriente',
    'Tisma',
  ],
  'granada': [
    'Granada',
    'Diriá',
    'Diriomo',
    'Nandaime',
  ],
  'rivas': [
    'Rivas',
    'Altagracia',
    'Belén',
    'Buenos Aires',
    'Cárdenas',
    'Moyogalpa',
    'Potosí',
    'San Jorge',
    'San Juan del Sur',
    'Tola',
  ],
  'boaco': [
    'Boaco',
    'Camoapa',
    'San José de los Remates',
    'San Lorenzo',
    'Santa Lucía',
    'Teustepe',
  ],
  'carazo': [
    'Diriamba',
    'Dolores',
    'El Rosario',
    'Jinotepe',
    'La Conquista',
    'La Paz de Carazo',
    'San Marcos',
    'Santa Teresa',
  ],
  'chinandega': [
    'Chinandega',
    'Chichigalpa',
    'Cinco Pinos',
    'Corinto',
    'El Realejo',
    'El Viejo',
    'Posoltega',
    'Puerto Morazán',
    'San Francisco del Norte',
    'San Pedro del Norte',
    'Santo Tomás del Norte',
    'Somotillo',
    'Villanueva',
  ],
  'chontales': [
    'Juigalpa',
    'Acoyapa',
    'Comalapa',
    'Cuapa',
    'El Coral',
    'La Libertad',
    'San Pedro de Lóvago',
    'Santo Domingo',
    'Santo Tomás',
    'Villa Sandino',
  ],
  'estelí': [
    'Estelí',
    'Condega',
    'La Trinidad',
    'Pueblo Nuevo',
    'San Juan de Limay',
    'San Nicolás',
  ],
  'jinotega': [
    'Jinotega',
    'El Cuá',
    'La Concordia',
    'San José de Bocay',
    'San Rafael del Norte',
    'Santa María de Pantasma',
    'Wiwilí de Jinotega',
  ],
  'madriz': [
    'Somoto',
    'Las Sabanas',
    'Palacagüina',
    'San José de Cusmapa',
    'San Juan de Río Coco',
    'San Lucas',
    'Telpaneca',
    'Totogalpa',
    'Yalagüina',
  ],
  'matagalpa': [
    'Matagalpa',
    'Ciudad Darío',
    'El Tuma-La Dalia',
    'Esquipulas',
    'Matiguás',
    'Muy Muy',
    'Rancho Grande',
    'Río Blanco',
    'San Dionisio',
    'San Isidro',
    'San Ramón',
    'Sébaco',
    'Terrabona',
  ],
  'nueva segovia': [
    'Ocotal',
    'Ciudad Antigua',
    'Dipilto',
    'El Jícaro',
    'Jalapa',
    'Macuelizo',
    'Mozonte',
    'Murra',
    'Quilalí',
    'San Fernando',
    'Santa María',
    'Wiwilí de Nueva Segovia',
  ],
  'río san juan': [
    'San Carlos',
    'El Almendro',
    'El Castillo',
    'Morrito',
    'San Juan de Nicaragua',
    'San Miguelito',
  ],
  'raccn': [
    'Puerto Cabezas (Bilwi)',
    'Waspam',
    'Prinzapolka',
    'Bonanza',
    'Rosita',
    'Siuna',
    'Mulukukú',
    'Waslala',
  ],
  'raccs': [
    'Bluefields',
    'Corn Island (Islas del Maíz)',
    'Desembocadura de Río Grande',
    'El Rama',
    'El Tortuguero',
    'Kukra Hill',
    'La Cruz de Río Grande',
    'Laguna de Perlas',
    'Muelle de los Bueyes',
    'Nueva Guinea',
    'Paiwas',
  ],
};

/// Mapa de alias -> clave canónica usada en [municipiosPorDepartamento]
/// Permite aceptar nombres alternos como "Costa Caribe Norte" (RACCN) y
/// "Costa Caribe Sur" (RACCS), así como variantes históricas (RAAN/RAAS).
const Map<String, String> _departamentoAlias = {
  // Costa Caribe Norte (RACCN)
  'costa caribe norte': 'raccn',
  'región autónoma de la costa caribe norte': 'raccn',
  'region autonoma de la costa caribe norte': 'raccn',
  'raacn': 'raccn',
  'raan': 'raccn', // denominación histórica

  // Costa Caribe Sur (RACCS)
  'costa caribe sur': 'raccs',
  'región autónoma de la costa caribe sur': 'raccs',
  'region autonoma de la costa caribe sur': 'raccs',
  'raacs': 'raccs',
  'raas': 'raccs', // denominación histórica
};

/// Devuelve una clave canónica en minúsculas para un nombre de departamento.
/// Si existe un alias mapeado (p. ej., "Costa Caribe Norte"), retorna
/// la clave compatible con [municipiosPorDepartamento] (p. ej., "raccn").
/// En otro caso, retorna el nombre en minúsculas trim.
String canonicalizarDepartamento(String nombre) {
  final String lower = nombre.toLowerCase().trim();
  return _departamentoAlias[lower] ?? lower;
}

/// Intenta resolver un [Departamento] desde texto, aceptando alias.
Departamento? tryDepartamentoFromString(String nombre) {
  final String canon = canonicalizarDepartamento(nombre);
  // Coincidir contra `nombre` del enum (por ejemplo, 'RACCN' -> 'raccn')
  for (final d in Departamento.values) {
    if (d.nombre.toLowerCase() == canon) return d;
  }
  return null;
}

/// Normaliza texto para comparaciones laxas: minúsculas, sin tildes,
/// sin contenido entre paréntesis y espacios colapsados.
String normalizeTexto(String input) {
  String out = input.toLowerCase().trim();
  // Eliminar contenido entre paréntesis para permitir 'Puerto Cabezas'
  // vs 'Puerto Cabezas (Bilwi)'
  int open = out.indexOf('(');
  if (open != -1) {
    out = out.substring(0, open).trim();
  }
  // Reemplazar tildes y caracteres comunes en español
  const Map<String, String> repl = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
    'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u',
    'ä': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ñ': 'n',
  };
  final StringBuffer buf = StringBuffer();
  for (final ch in out.split('')) {
    buf.write(repl[ch] ?? ch);
  }
  out = buf.toString();
  // Colapsar espacios múltiples
  out = out.replaceAll(RegExp(r'\s+'), ' ');
  return out;
}

/// Alias de municipios por departamento (clave canónica)
const Map<String, Map<String, String>> municipioAliasPorDepartamento = {
  'raccn': {
    // Waspán / Waspan -> Waspam (grafías frecuentes)
    'waspan': 'Waspam',
    'waspam': 'Waspam',
    'waspan ': 'Waspam',
    'wasp an': 'Waspam',
    'waspan (bilwi)': 'Waspam',
    // Bilwi / Puerto Cabezas
    'bilwi': 'Puerto Cabezas (Bilwi)',
    'puerto cabezas': 'Puerto Cabezas (Bilwi)',
  },
  'raccs': {
    'corn island': 'Corn Island (Islas del Maíz)',
    'islas del maiz': 'Corn Island (Islas del Maíz)',
  },
};