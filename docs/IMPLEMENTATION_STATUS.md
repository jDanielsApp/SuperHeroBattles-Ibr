# Estado de implementación — SuperHeroBattle

Última actualización: 18/11/2026

Este documento es el registro vivo del proyecto. Se actualiza al cerrar cada fase y antes de cada commit relevante.

## Resumen

- **Fase actual:** Fase 2 — API, búsqueda, caché y cancelación (pendiente de iniciar).
- **Última fase cerrada:** Fase 1 — Arquitectura, dominio y navegación.
- **Estado del build:** compila y los tests pasan en Xcode 27.2 / iOS Simulator 27.x.
- **Dependencias:** RealmSwift 20.0.6 y Lottie 4.6.1 resueltas con SwiftPM.

## Decisiones confirmadas

1. Catálogo inicial: semilla de ~30 nombres de héroes descargados desde la API oficial en el primer arranque, con concurrencia limitada, persistencia en Realm y progreso/reintento en la Guía. Sin datos inventados.
2. Lottie: paquete y wrapper SwiftUI integrados. Las animaciones `.json` las aporta el usuario; mientras no existan, se usa fallback estático.
3. Token de SuperHeroAPI: disponible en `Secrets.xcconfig` para verificación manual. Nunca se imprime ni se commitea.
4. Localización clásica con `Localizable.strings` en inglés y español. Sin String Catalogs.
5. Arquitectura por capas según `AGENTS.md`, con `Domain/Services` para protocolos no ligados a repositorios.
6. Historial y catálogo persistidos como snapshots inmutables; nunca se guardan objetos Realm ni DTOs.
7. La IA solo narra. El ganador y las puntuaciones los determina exclusivamente el motor Swift.

## Fases

| Fase | Estado | Notas |
|---|---|---|
| 0. Saneamiento y decisiones | Completada | Documentación movida, Lottie añadido, localización clásica, configs excluidos del bundle |
| 1. Arquitectura, dominio y navegación | Completada | Entidades, protocolos, casos de uso base, DI, Home y placeholders |
| 2. API, búsqueda, caché y cancelación | Pendiente | Siguiente fase |
| 3. Catálogo, filtros, detalle e imágenes | Pendiente | Incluye seed inicial |
| 4. Selección de equipos | Pendiente | |
| 5. Motor de combate | Pendiente | |
| 6. Apple Foundation Models | Pendiente | |
| 7. Combate, resultados e historial | Pendiente | |
| 8. Diseño comic, Lottie, idiomas y accesibilidad | Pendiente | Wrapper y assets Lottie |
| 9. Calidad final | Pendiente | |

## Fase 0 — completada

- [x] Mover `SuperHeroBattle/App/Documentation.swift` a `docs/PROMPT_MAESTRO.md`.
- [x] Crear este registro de implementación.
- [x] Actualizar `AGENTS.md` con Lottie, localización clásica, estructura y reglas de test.
- [x] Añadir Lottie 4.6.1 al `project.xcproj`.
- [x] Configurar `en.lproj` y `es.lproj` con `Localizable.strings`.
- [x] Desactivar String Catalogs y preferencia de catálogos.
- [x] Excluir `Config/Base.xcconfig`, `Config/Secrets.example.xcconfig` y `Config/Secrets.xcconfig` de Copy Bundle Resources.
- [x] Verificar que `Secrets.xcconfig` no está dentro del `.app`.
- [x] Compilar, ejecutar tests y validar `xcodebuild -list`.

## Fase 1 — completada

- [x] Entidades de dominio: `Hero`, `PowerStats`, biografía, apariencia, trabajo, conexiones, snapshots, modalidad, equipos, resultado y narración.
- [x] Reglas de `PowerStats` con valores desconocidos fuera de la media.
- [x] `TeamDraft` con huecos, sustitución individual y prohibición de duplicados dentro del equipo.
- [x] Protocolos `HeroRepository`, `HeroCatalogRepository`, `CombatHistoryRepository` y `CombatNarrationService`.
- [x] Casos de uso base: búsqueda, detalle, catálogo, filtros, selección, aleatorio e historial.
- [x] `AppContainer`, `RootView`, `AppRoute` y pantalla Home con estética comic.
- [x] Placeholders de Guía, Duelos y Ajustes.
- [x] Localización en inglés y español con test de paridad de claves.
- [x] Tests de dominio y filtros.

Tests: **20 unit tests + 2 UI tests**, todos en verde.

## Pendiente inmediato — Fase 2

- Cliente HTTP con `URLSession`, errores tipados y validación del campo `response`.
- DTOs, mapeadores y decodificación de valores `"-"`.
- `HeroSearchCache` actor con TTL (180 s por defecto, rango 120–300 s), reloj inyectable y normalización de query.
- Coalescencia de peticiones idénticas y cancelación propagada.
- `HeroSearchView` y `HeroSearchViewModel` con loading, vacío, error y reintento.
- Tests con `URLProtocol`, caché y cancelación.

## Pendientes y riesgos

- SuperHeroAPI no tiene endpoint de catálogo completo ni paginación; el seed inicial se resolverá con búsquedas controladas en Fase 3.
- Las imágenes dependen de un host externo; habrá placeholder y fallback.
- Foundation Models puede no estar disponible en simulador; el fallback local es obligatorio.
- El wrapper Lottie y los assets quedan para Fase 8.
- El selector de idioma ya persiste la preferencia, pero la revisión completa de accesibilidad e idioma se cierra en Fase 8.

## Verificación ejecutada

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -list -project SuperHeroBattle.xcodeproj
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Resultado: build correcto, 20 unit tests + 2 UI tests en verde, y `SuperHeroBattle.app` contiene `en.lproj` y `es.lproj`, sin archivos `*.xcconfig`. La pantalla Home se verificó visualmente en inglés y español en el simulador iPhone 17 (iOS 27.0).
