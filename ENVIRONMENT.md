# Configuración de variables de entorno

Este proyecto usa constantes en `lib/core/config/environment.dart` que pueden ser sobrescritas en tiempo de ejecución con `--dart-define`. No es necesario un archivo `.env`.

## Variables soportadas

Firebase (cliente):
- `FIREBASE_WEB_API_KEY`
- `FIREBASE_ANDROID_API_KEY`
- `FIREBASE_IOS_API_KEY`
- `FIREBASE_WEB_VAPID_KEY` (FCM Web Push)

Entorno de la app (DI y configuraciones):
- `APP_ENV` → `dev` | `staging` | `prod` (por defecto: `dev`)

Servicios adicionales:
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`
- `FCM_WORKER_ENDPOINT` (Cloudflare Worker opcional para envío de notificaciones)

Scripts utilitarios:
- `FORCE_UPDATE_CATEGORIAS` (bool) para `lib/utils/run_migration.dart`

## Cómo pasar variables con --dart-define

Ejecución local por plataforma:

```bash
# Web
flutter run -d chrome \
  --dart-define=FIREBASE_WEB_API_KEY=TU_API_KEY \
  --dart-define=FIREBASE_WEB_VAPID_KEY=TU_VAPID \
  --dart-define=APP_ENV=dev

# Android
flutter run -d android \
  --dart-define=FIREBASE_ANDROID_API_KEY=TU_API_KEY \
  --dart-define=APP_ENV=dev

# iOS/macOS
flutter run -d ios \
  --dart-define=FIREBASE_IOS_API_KEY=TU_API_KEY \
  --dart-define=APP_ENV=dev

# Windows (usa opciones tipo web en este proyecto)
flutter run -d windows \
  --dart-define=FIREBASE_WEB_API_KEY=TU_API_KEY \
  --dart-define=APP_ENV=dev
```

Builds de producción:

```bash
# Android (APK/AAB)
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=FIREBASE_ANDROID_API_KEY=TU_API_KEY

# iOS (ejecutar en macOS)
flutter build ios --release \
  --dart-define=APP_ENV=prod \
  --dart-define=FIREBASE_IOS_API_KEY=TU_API_KEY

# Web
flutter build web --release \
  --dart-define=APP_ENV=prod \
  --dart-define=FIREBASE_WEB_API_KEY=TU_API_KEY \
  --dart-define=FIREBASE_WEB_VAPID_KEY=TU_VAPID
```

Migración de categorías (opcional):

```bash
flutter run -t lib/utils/run_migration.dart \
  --dart-define=FORCE_UPDATE_CATEGORIAS=true
```

## APP_ENV y contenedor de dependencias

- `APP_ENV` se mapea en `lib/core/config/app_environment.dart` a `dev`, `staging` o `production` y es usado por el Service Locator al inicializar en `main.dart`.
- Si no defines `APP_ENV`, se usa `dev` por defecto.

## Valores por defecto

Si no defines variables, el proyecto usa valores por defecto en `Environment`. Esto permite ejecutar el proyecto de inmediato con la configuración de demostración. Para producción, sobrescribe con `--dart-define` o ejecuta `flutterfire configure` para regenerar `firebase_options.dart`.

## CI/CD (ejemplo)

Define secretos en tu plataforma (p. ej. GitHub Actions) y pásalos al build:

```yaml
- name: Build Android (prod)
  run: |
    flutter build apk --release \
      --dart-define=APP_ENV=prod \
      --dart-define=FIREBASE_ANDROID_API_KEY=${{ secrets.FIREBASE_ANDROID_API_KEY }} \
      --dart-define=CLOUDINARY_CLOUD_NAME=${{ secrets.CLOUDINARY_CLOUD_NAME }} \
      --dart-define=CLOUDINARY_UPLOAD_PRESET=${{ secrets.CLOUDINARY_UPLOAD_PRESET }} \
      --dart-define=FCM_WORKER_ENDPOINT=${{ secrets.FCM_WORKER_ENDPOINT }}
```

## Seguridad

- Las `apiKey` de Firebase en cliente no son secretas, pero debes:
  - Restringirlas en Google Cloud (dominios web, package+SHA Android, bundle iOS).
  - Tener reglas estrictas en Firestore/Storage.
- Nunca imprimas claves en logs ni las subas a repos públicos.
- Usa diferentes valores para `dev`/`staging`/`prod` y rota periódicamente.

## Notas específicas de Web (FCM)

- Para notificaciones push en Web se requiere `FIREBASE_WEB_VAPID_KEY` y el service worker `web/firebase-messaging-sw.js` (incluido en el repo).
