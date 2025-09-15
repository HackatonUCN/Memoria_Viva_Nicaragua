// Script para ejecutar la migración de categorías de forma independiente
// Uso: flutter run -t lib/utils/run_migration.dart --dart-define=FORCE_UPDATE_CATEGORIAS=true

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/infrastructure/services/firebase_options.dart';
import 'migrate_categorias.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializar Firebase con opciones generadas
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Autenticación opcional por variables de entorno
    const String authMethod = String.fromEnvironment('AUTH_METHOD', defaultValue: '');
    const String email = String.fromEnvironment('MIGRATION_EMAIL', defaultValue: '');
    const String password = String.fromEnvironment('MIGRATION_PASSWORD', defaultValue: '');
    if (authMethod.toLowerCase() == 'google') {
      print('Autenticando con Google...');
      await _signInWithGoogle();
    } else if (email.isNotEmpty && password.isNotEmpty) {
      print('Autenticando con email definido por --dart-define...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    } else {
      print('Autenticación anónima para migración...');
      await FirebaseAuth.instance.signInAnonymously();
    }

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

Future<void> _signInWithGoogle() async {
  // Web: usar popup nativo de Firebase Auth
  if (kIsWeb) {
    final provider = GoogleAuthProvider();
    await FirebaseAuth.instance.signInWithPopup(provider);
    return;
  }

  // Android/iOS: usar google_sign_in para obtener credenciales
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
  final GoogleSignInAccount? account = await googleSignIn.signIn();
  if (account == null) {
    throw Exception('Inicio de sesión de Google cancelado por el usuario.');
  }
  final GoogleSignInAuthentication auth = await account.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: auth.accessToken,
    idToken: auth.idToken,
  );
  await FirebaseAuth.instance.signInWithCredential(credential);
}
