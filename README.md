# Memoria Viva Nicaragua

[![Flutter](https://img.shields.io/badge/Flutter-stable-blue.svg)](https://flutter.dev/)
[![Style: Effective Dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Aplicación educativa para preservar, registrar y compartir los saberes populares, culturales y tradiciones nicaragüenses. Busca conectar el sistema educativo con familias y comunidades para transmitir el patrimonio cultural a nuevas generaciones.

## ✨ ¿Qué problema resolvemos?

Gran parte de la memoria cultural se pierde al no estar documentada ni disponible para consulta. Esta app permite a estudiantes, docentes y familias publicar relatos (texto, imagen, audio, video), geolocalizarlos en un mapa, descubrir eventos del calendario cultural, consultar una biblioteca de saberes y aprender mediante juegos didácticos.

## 🚀 Guía rápida (3 pasos)

1. Clona el repositorio y entra a la carpeta del proyecto
   ```bash
   git clone https://github.com/HackatonUCN/memoria_viva_nicaragua.git
   cd memoria_viva_nicaragua
   ```
2. Instala dependencias
   ```bash
   flutter pub get
   ```
3. Ejecuta en tu plataforma (Android/iOS/Web/Escritorio)
   ```bash
   flutter run
   ```

> Nota: El proyecto ya incluye configuración de Firebase lista para ejecutar. Si deseas usar tu propio proyecto de Firebase, consulta la sección “Configuración de Firebase”.

## 🧰 Requisitos previos

- Flutter estable (3.22+ recomendado)
- Dart 3.9+ (según tu SDK de Flutter)
- Android Studio o VS Code con extensiones de Flutter/Dart
- Git y Java JDK 17 (para Android)
- Dispositivo/emulador o navegador Chrome para Web

## 🧪 Cómo ejecutar

- Android: `flutter run -d android`
- iOS (macOS): `flutter run -d ios`  (requiere Xcode y CocoaPods)
- Web: `flutter run -d chrome`
- Windows/macOS: habilita desktop si es necesario (`flutter config --enable-windows-desktop`/`--enable-macos-desktop`) y ejecuta con `flutter run -d windows`/`-d macos`.

Comandos útiles:

```bash
flutter analyze           # Análisis estático
flutter test              # Pruebas unitarias
flutter build apk         # Build Android (release)
flutter build web         # Build Web (release)
```

## 🔐 Configuración de Firebase (opcional)

El repo ya viene configurado con `firebase_options.dart` y `google-services.json` para Android. Puedes ejecutar sin cambios. Si quieres apuntar a TU proyecto de Firebase:

1) Instala la CLI de FlutterFire y configura:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

2) (Opcional) Sobrescribe claves en tiempo de ejecución usando `--dart-define`:
```bash
# Web
flutter run -d chrome \
  --dart-define=FIREBASE_WEB_API_KEY=TU_API_KEY \
  --dart-define=FIREBASE_WEB_VAPID_KEY=TU_VAPID_KEY \
  --dart-define=APP_ENV=dev

# Android
flutter run -d android --dart-define=FIREBASE_ANDROID_API_KEY=TU_API_KEY --dart-define=APP_ENV=dev

# iOS/macOS
flutter run -d ios --dart-define=FIREBASE_IOS_API_KEY=TU_API_KEY --dart-define=APP_ENV=dev
```

Más detalles en [ENVIRONMENT.md](ENVIRONMENT.md).

## 🧱 Arquitectura del proyecto

- **Framework**: Flutter + Dart
- **Backend**: Firebase (Auth, Firestore, Storage, Functions, Messaging, Remote Config)
- **Gestión de estado**: Provider + BLoC en pantallas puntuales
- **Estructura**:
  ```
  lib/
  ├── config/       # Enrutamiento y configuración de navegación
  ├── core/         # Tema, DI, utilidades y configuración de entorno
  ├── data/         # Datasources, repositorios e infraestructura
  ├── domain/       # Entidades, casos de uso y reglas de negocio
  ├── presentation/ # UI (pantallas, widgets, providers/blocs)
  └── utils/        # Scripts y utilidades
  ```

## 📚 Funcionalidades clave

- 📱 Multiplataforma: Android, iOS y Web
- 🗺️ Mapa interactivo con relatos geolocalizados
- 📅 Calendario cultural y eventos
- 📚 Biblioteca colaborativa de saberes
- 🎮 Juegos didácticos (Trivia, Adivinanzas, Memoria)
- 🔐 Autenticación y moderación

## 🧩 Tareas de soporte (opcional)

- Migración/seed de categorías:
  ```bash
  flutter run -t lib/utils/run_migration.dart \
    --dart-define=FORCE_UPDATE_CATEGORIAS=false
  ```

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Revisa [CONTRIBUTING.md](CONTRIBUTING.md) para conocer el flujo de trabajo y buenas prácticas.

## 📝 Licencia

Proyecto bajo licencia MIT. Ver [LICENSE](LICENSE).

## 📞 Contacto

hackatonucn@gmail.com

Repositorio: [github.com/HackatonUCN/memoria_viva_nicaragua](https://github.com/HackatonUCN/memoria_viva_nicaragua)

## 🙏 Agradecimientos

- [Flutter](https://flutter.dev/)
- [Firebase](https://firebase.google.com/)
- Comunidad Flutter Nicaragua