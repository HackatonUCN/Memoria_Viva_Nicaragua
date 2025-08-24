# Guía de Contribución

¡Gracias por tu interés en contribuir a Memoria Viva Nicaragua! 🎉

## 📝 Proceso de Contribución

1. Fork del repositorio
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit de tus cambios (`git commit -m 'Add: AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📋 Convenciones de Código

### Estilo de Código
- Seguimos [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Usamos el formatter de Dart (`dart format .`)
- Mantenemos un máximo de 80 caracteres por línea

### Convenciones de Commit
Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva característica
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `style:` Cambios de formato
- `refactor:` Refactorización de código
- `test:` Añadir o modificar tests
- `chore:` Cambios en el proceso de build o herramientas

### Estructura de Branches
- `main`: Producción
- `develop`: Desarrollo
- `feature/*`: Nuevas características
- `bugfix/*`: Correcciones
- `hotfix/*`: Correcciones urgentes

## 🧪 Testing

- Escribe tests para todo el código nuevo
- Mantén la cobertura de tests > 80%
- Ejecuta `flutter test` antes de commit

## 📱 UI/UX

- Sigue el Material Design 3
- Usa los colores definidos en `lib/core/theme`
- Asegura que la UI sea responsive
- Implementa modo oscuro

## 🔒 Seguridad

- No expongas información sensible
- No comitees archivos de configuración
- Usa variables de entorno para secrets

## 📝 Documentación

- Documenta todas las clases y métodos públicos
- Mantén el README actualizado
- Añade ejemplos de uso cuando sea relevante

## ❓ ¿Preguntas?

¿Tienes dudas? Abre un issue o contacta al equipo.

## 📜 Código de Conducta

Este proyecto sigue el [Código de Conducta de Contributor Covenant](https://www.contributor-covenant.org/es/version/2/0/code_of_conduct/).
