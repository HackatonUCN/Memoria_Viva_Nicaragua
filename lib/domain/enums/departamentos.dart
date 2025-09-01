/// Departamentos de Nicaragua
enum Departamento {
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
  // Agregar el resto de departamentos y municipios
};