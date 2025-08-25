# Configuración de Variables de Entorno

Este documento describe cómo manejar las variables de entorno en el proyecto Memoria Viva Nicaragua.

## Variables de Entorno

El proyecto utiliza las siguientes variables de entorno para las claves de API de Firebase:

```
FIREBASE_WEB_API_KEY
FIREBASE_ANDROID_API_KEY
FIREBASE_IOS_API_KEY
```

## Configuración

1. Crea un archivo `.env` en la raíz del proyecto
2. Copia el contenido de `.env.example` a `.env`
3. Rellena las variables con los valores correspondientes

## Seguridad

- NUNCA subas el archivo `.env` al control de versiones
- NUNCA compartas las claves de API en repositorios públicos
- Usa diferentes claves para desarrollo y producción
- Rota las claves periódicamente siguiendo las mejores prácticas de seguridad

## Desarrollo Local

Para desarrollo local, las claves por defecto están configuradas en `lib/core/config/environment.dart`. 
Sin embargo, se recomienda configurar el archivo `.env` con tus propias claves de desarrollo.

## CI/CD

Para CI/CD, configura las variables de entorno en los secretos de tu sistema de integración continua.
No expongas las claves en los logs de CI/CD.
