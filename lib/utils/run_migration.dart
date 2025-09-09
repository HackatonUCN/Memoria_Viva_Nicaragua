// Script para ejecutar la migración de categorías de forma independiente
// Uso: flutter run -t lib/utils/run_migration.dart --dart-define=FORCE_UPDATE_CATEGORIAS=true

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'migrate_categorias.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    
    // Parámetro para forzar actualización de categorías existentes
    const bool forceUpdate = bool.fromEnvironment('FORCE_UPDATE_CATEGORIAS', defaultValue: false);
    
    print('Iniciando migración de categorías...');
    print('Modo forzado: $forceUpdate');
    
    // Ejecutar migración
    await CategoriaMigrator.migrateCategorias(forceUpdate: forceUpdate);
    
    print('Migración completada con éxito');
  } catch (e, stackTrace) {
    print('Error durante la migración: $e');
    print('Stack trace: $stackTrace');
  }
  
  // Finalizar la aplicación
  print('Terminando proceso...');
}
