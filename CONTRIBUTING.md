# Guía de Contribución

¡Gracias por tu interés en contribuir a Memoria Viva Nicaragua! 🎉

## 📝 Flujo de trabajo

1. Haz Fork del repositorio
2. Crea una rama descriptiva: `feat/nombre-corto` o `fix/bug-descriptivo`
3. Implementa y garantiza que pasa el análisis y las pruebas
4. Commit siguiendo Conventional Commits
5. Push a tu fork y abre un Pull Request (PR)

## ✅ Checklist para Pull Requests

- [ ] Sigue la guía de estilo (Effective Dart) y formato (`dart format .`)
- [ ] Linter sin errores: `flutter analyze`
- [ ] Pruebas pasan: `flutter test`
- [ ] Incluye tests para lo nuevo o cambiado
- [ ] Actualiza documentación (README/ENVIRONMENT si aplica)
- [ ] No incluye secretos ni archivos ignorados (.env, keys privadas)

## 📋 Convenciones

### Estilo de Código
- Effective Dart: `https://dart.dev/guides/language/effective-dart`
- Mantén funciones y clases pequeñas, nombres descriptivos y sin abreviaturas crípticas
- Evita anidaciones profundas; usa early-returns

### Commits (Conventional Commits)
- `feat:` nueva funcionalidad
- `fix:` corrección de bug
- `docs:` documentación
- `style:` formato (sin cambios de lógica)
- `refactor:` cambio interno sin cambiar comportamiento
- `test:` pruebas añadidas/ajustadas
- `chore:` herramientas/infraestructura

### Ramas
- `main`: estable/producción
- `develop`: integración de desarrollo
- `feat/*`, `fix/*`, `chore/*`, `refactor/*` según corresponda

## 🧪 Pruebas

- Cubre lógica de negocio en `domain` y `data`
- Usa `mocktail`/`fake_cloud_firestore` donde aplique
- Objetivo de cobertura: ≥ 80%
- Comandos:
  ```bash
  flutter analyze
  flutter test
  ```

## 📱 UI/UX

- Sigue Material Design 3 y la guía de estilo del proyecto (colores/tipografías)
- Usa `flutter_screenutil` y patrones responsive
- Respeta accesibilidad (contraste, tamaños de toque, textos escalables)

## 🔒 Seguridad

- No subas `.env` ni secretos; usa `--dart-define` para variables
- Revisa que las reglas de Firestore/Storage sean estrictas
- Evita logs con datos sensibles

## 📝 Documentación

- Documenta clases y funciones públicas
- Actualiza el README y el CHANGELOG cuando corresponda
- Añade ejemplos de uso para componentes complejos

## ❓ Soporte y dudas

Abre un issue describiendo el contexto, comportamiento esperado y pasos para reproducir. Etiqueta con `bug`, `enhancement` o `question`.

## 📜 Código de Conducta

Este proyecto sigue el [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Al participar aceptas cumplir sus lineamientos.
