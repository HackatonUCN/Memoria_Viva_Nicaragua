# Arquitectura - Memoria Viva Nicaragua

Este documento resume la arquitectura técnica del proyecto para que evaluadores y colaboradores entiendan rápidamente cómo está organizado el sistema.

## Capas y organización

Estructura por capas, simple y mantenible:

```
lib/
├─ config/           # Enrutador y navegación
├─ core/             # Tema, DI, utilidades, configuración de entorno
├─ data/             # Datasources, modelos, repositorios (implementaciones)
├─ domain/           # Entidades, casos de uso, servicios y reglas de negocio
├─ presentation/     # UI (pantallas, widgets) + providers/BLoC
└─ utils/            # Scripts y herramientas
```

- Domain: independiente del framework; define el “qué” y “por qué”.
- Data: implementa acceso a Firebase (Firestore/Storage/Auth/Functions), mapea modelos ↔ entidades.
- Core: cross-cutting concerns (tema, DI via `get_it`, environment), estilos.
- Presentation: UI con Provider (y BLoC puntualmente) siguiendo principios de separación de responsabilidades.

## Flujo de datos (alto nivel)

1) UI (Provider/BLoC) dispara un Caso de Uso del dominio.
2) Caso de Uso orquesta repositorios del dominio.
3) Repositorio del dominio llama a su implementación en `data`.
4) Datasource accede a Firebase/HTTP/Storage y devuelve DTOs.
5) Mappers convierten DTOs ↔ Entidades del dominio.
6) Respuesta vuelve a UI; estado reactivo actualiza widgets.

```
Presentation (UI/Provider) → Domain (UseCase) → Domain (Repository) → Data (RepositoryImpl)
→ Data (Datasource Firebase) → Firebase (Auth/Firestore/Storage/Functions)
← mappers/DTOs/Entities ← ... ← UI actualiza estado
```

## Autenticación

- Firebase Auth (email/password y Google Sign-In).
- `AuthProvider` gestiona sesión, estado (`authenticated`, `initial`, `authenticating`).
- Guardas de ruta en `AppRouter` (_AuthRequired / _RedirectIfAuthenticated) para proteger secciones.
- FCM: se guarda el token por usuario en `users/{uid}/fcmTokens/{token}` (opt-in).

## Integraciones Firebase

- Core: `FirebaseServicesManager` inicializa Firebase, Crashlytics, Performance, Remote Config, Messaging.
- Config por plataforma en `data/infrastructure/services/firebase_options.dart`.
- Variables sobreescribibles vía `--dart-define` (ver `ENVIRONMENT.md`).
- Remote Config: toggles simples (`feature_trivia_enabled`, etc.).
- Crashlytics/Analytics/Performance: habilitados condicionalmente por entorno y consentimiento.

## Mapa interactivo

- UI en `presentation/screens/mapa/` y `map_provider.dart`.
- Muestra relatos geolocalizados; clústers y marcadores (paquetes `flutter_map`, `marker_cluster`).
- Filtrado y foco en `relatoId` vía argumentos de ruta (`/mapa?relatoId=...`).

## Publicación de relatos

- Formulario: texto, imágenes, audio, video y ubicación.
- Upload: Firebase Storage; metadatos en Firestore.
- Optimización de carga: `cached_network_image` para lectura; validación y permisos con `image_picker`/`file_picker`/`permission_handler`.

## Calendario cultural

- `table_calendar` para UI; eventos persistidos en Firestore.
- Vista día/semana/mes; posibilidad de moderación de eventos sugeridos.

## Biblioteca de saberes

- Contenido categorizado (dichos, refranes, recetas) con seed opcional (script en `utils/`).
- Búsqueda simple y carga paginada.

## Juegos didácticos

- Módulo con Trivia/Adivinanzas/Emparejar cartas.
- Remote Config para activar/desactivar características y banners.

## DI (Inversión de dependencias)

- `get_it` como Service Locator.
- `AppEnvironmentMapper` mapea `APP_ENV` (`dev`, `staging`, `production`) para registrar implementaciones/contexto por entorno.

## Responsividad y tema

- `flutter_screenutil`, `MediaQuery` y `LayoutBuilder` para escalado.
- Temas en `core/theme` siguiendo paleta y tipografías del proyecto.

## Seguridad y políticas

- Reglas de Firestore/Storage restringen escrituras a usuarios autenticados y/o roles.
- API keys de Firebase en cliente no son secretas; restringidas en Google Cloud (dominios, package+SHA, bundle).
- Registro de errores en Crashlytics (deshabilitado por defecto en debug).

## Build y entornos

- Desarrollo: `flutter run -d <plataforma>` (APP_ENV=dev por defecto).
- Producción: `flutter build <target> --dart-define=APP_ENV=prod` y claves según plataforma (ver `ENVIRONMENT.md`).

## Roadmap (resumen)

- Mejoras de accesibilidad y performance del mapa.
- Moderación avanzada y analíticas de participación.
- Juegos adicionales y ranking.


