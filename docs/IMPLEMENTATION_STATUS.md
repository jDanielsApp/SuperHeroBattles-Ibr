# Estado de implementación — SuperHeroBattle

Última actualización: 19/11/2026

Este documento es el registro vivo del proyecto. Se actualiza al cerrar cada fase y antes de cada commit relevante.

## Resumen

- **Fase actual:** Fase 2 cerrada; Fase 3 (catálogo, filtros, detalle e imágenes) pendiente de iniciar.
- **Última fase cerrada:** Fase 2 — API, búsqueda, caché y cancelación.
- **Estado del build:** compila y los tests pasan en Xcode 27.2 / iOS Simulator 27.0.
- **Dependencias:** RealmSwift 20.0.6 y Lottie 4.6.1 resueltas con SwiftPM.

## Decisiones confirmadas

1. Catálogo inicial: semilla de ~30 nombres de héroes descargados desde la API oficial en el primer arranque, con concurrencia limitada, persistencia en Realm y progreso/reintento en la Guía. Sin datos inventados.
2. Lottie: paquete y wrapper SwiftUI integrados. Las animaciones `.json` las aporta el usuario; mientras no existan, se usa fallback estático.
3. Token de SuperHeroAPI: configurado en `Secrets.xcconfig` (ignorado por git) y verificado contra la API real. Nunca se imprime ni se commitea.
4. Localización clásica con `Localizable.strings` en inglés y español. Sin String Catalogs.
5. Arquitectura por capas según `AGENTS.md`, con `Domain/Services` para protocolos no ligados a repositorios.
6. Historial y catálogo persistidos como snapshots inmutables; nunca se guardan objetos Realm ni DTOs.
7. La IA solo narra. El ganador y las puntuaciones los determina exclusivamente el motor Swift.

## Fases

| Fase | Estado | Notas |
|---|---|---|
| 0. Saneamiento y decisiones | Completada | Documentación movida, Lottie añadido, localización clásica, configs excluidos del bundle |
| 1. Arquitectura, dominio y navegación | Completada | Entidades, protocolos, casos de uso base, DI, Home y placeholders |
| 2. API, búsqueda, caché y cancelación | Completada | Cliente HTTP, búsqueda explícita, caché TTL y cancelación con tests |
| 3. Catálogo, filtros, detalle e imágenes | Pendiente | Siguiente fase; incluye seed inicial |
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

## Fase 2 — completada

- [x] Cliente HTTP con `URLSession` y `async/await`, sin callbacks ni `DispatchQueue`.
- [x] Errores tipados (`HeroRepositoryError`) y validación de estado HTTP y del campo `response` (la API puede devolver errores con HTTP 200).
- [x] DTOs, mapeadores y tratamiento de marcadores `"-"`, `"null"`, `"n/a"` y cadenas vacías como dato no disponible.
- [x] `SuperHeroAPIEndpoint` con la query codificada como componente de ruta (espacios, acentos y barras).
- [x] `HeroSearchCache` actor con TTL (180 s por defecto, rango 120–300 s) y reloj inyectable.
- [x] `CachedHeroRepository` como decorador; el detalle no pasa por la caché de búsqueda.
- [x] Normalización de query (`SearchQueryNormalizer`): la API recibe el texto recortado y la caché usa clave sin mayúsculas ni diacríticos.
- [x] Búsqueda explícita con botón y Return; sin peticiones por tecla.
- [x] Una única búsqueda activa por view model, protegida por cancelación de tarea y contador de generación; una respuesta obsoleta nunca se publica.
- [x] `HeroSearchView` con estados idle, loading, vacío, resultados y error con reintento.
- [x] Localización en inglés y español de textos de búsqueda, errores y accesibilidad.
- [x] Clasificación de errores de autenticación devueltos por la API (`access denied`, `Invalid API key`, etc.) como `unauthorized`.
- [x] `SuperHeroAPIConfiguration` rechaza tokens vacíos, marcadores `$(...)` (también entre comillas) y la plantilla `YOUR_...`.
- [x] Tests con `URLProtocol`, cliente HTTP falso, caché con reloj falso y repositorio controlado para cancelación y respuestas obsoletas.

Decisiones de la fase:

- La búsqueda es explícita; no hay debounce.
- No se añade coalescencia a nivel de repositorio: la caché y la búsqueda única activa cubren la duplicación en esta fase.
- No hay reintento automático con backoff; la UI ofrece reintento manual.
- Las conexiones (`group-affiliation`, `relatives`) se conservan como texto tal y como las entrega la API.

Tests: **84 unit tests + 1 UI test**, todos en verde.

## Pendiente inmediato — Fase 3

- Semilla inicial del catálogo con ~30 nombres reales, concurrencia limitada, persistencia en Realm y progreso/reintento.
- Modelos Realm de catálogo e historial, mapeadores y migraciones en un único punto.
- Filtros locales por editorial, alineación, género y rango de PowerStats.
- Pantalla de detalle de héroe con PowerStats accesibles.
- Caché de imágenes, cabeceras para el host externo y fallback para héroes sin retrato.

## Pendientes y riesgos

- **Token de SuperHeroAPI:** configurado localmente en `Secrets.xcconfig` y verificado con una búsqueda real. El archivo está ignorado por git y no se incluye en el bundle.
- **Imágenes de SuperHeroAPI:** el host `superherodb.com` responde HTTP 403 a peticiones directas, incluso con User-Agent y Referer de navegador. La app muestra el placeholder correctamente, pero en Fase 3 habrá que resolver la carga de imágenes (cabeceras específicas, proxy/CDN o fuente alternativa) antes de considerar la caché de imágenes terminada.
- SuperHeroAPI no tiene endpoint de catálogo completo ni paginación; el seed inicial se resolverá con búsquedas controladas en Fase 3.
- Las imágenes dependen de un host externo; habrá placeholder y fallback.
- Foundation Models puede no estar disponible en simulador; el fallback local es obligatorio.
- El wrapper Lottie y los assets quedan para Fase 8.
- El selector de idioma ya persiste la preferencia, pero la revisión completa de accesibilidad e idioma se cierra en Fase 8.
- Reintento automático con backoff y coalescencia de peticiones idénticas quedan fuera de Fase 2 por decisión de alcance.

## Verificación ejecutada

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -list -project SuperHeroBattle.xcodeproj
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Resultado Fase 2: build correcto, **84 unit tests + 1 UI test en verde** en iPhone 17 (iOS 27.0). `SuperHeroBattle.app` contiene `en.lproj` y `es.lproj`, y no incluye archivos `*.xcconfig`. La navegación Home → Guía y la presencia del campo de búsqueda se verifican con el UI test permanente `testCharacterGuideShowsSearchField`.

Verificación manual con API real: con el token configurado en `Secrets.xcconfig`, la búsqueda de `batman` devuelve 3 resultados (`Batman`, `Batman`, `Batman II`) y la app los publica en la Guía. La comprobación se hizo con un test UI temporal, ya eliminado. Las imágenes remotas no cargan porque el host responde 403; se muestra el placeholder previsto.
