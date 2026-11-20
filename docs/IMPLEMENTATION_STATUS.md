# Estado de implementación — SuperHeroBattle

Última actualización: 20/11/2026

Este documento es el registro vivo del proyecto. Se actualiza al cerrar cada fase y antes de cada commit relevante.

## Resumen

- **Fase actual:** Fase 16 cerrada (arrangement adaptativo fuera del scroll) sobre el proyecto completado.
- **Última fase cerrada:** Fase 16 — `ArrangementView` a nivel de contenedor con scroll propio por panel: lado a lado en horizontal, apilado en vertical, en las cuatro pantallas de paneles.
- **Herramienta nueva:** skill de proyecto `.opencode/skills/iphone-duo` (HIG destilada + mapa de decisiones por pantalla), con la lección del arrangement-fuera-del-scroll.
- **Estado del build:** compila en Debug sin warnings de código propio; **266 unit tests + 6 UI tests en verde en iPhone 17 (compact) y en iPhone Duo (regular, iOS 27.2)**.
- **Dependencias:** RealmSwift 20.0.6 y Lottie 4.6.1 resueltas con SwiftPM.

## Decisiones confirmadas

1. Catálogo paginado por IDs: `data/character_ids.json` es la fuente de verdad y se empaqueta con la app. Al entrar en la Guía se cargan los 30 primeros IDs, se piden sus fichas con concurrencia limitada y, al llegar al final, se cargan los siguientes 30. Los filtros actúan solo sobre los héroes ya cargados.
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
| 3. Catálogo, filtros, detalle e imágenes | Completada (imágenes pendientes) | Catálogo paginado por IDs, Realm, filtros, detalle y búsqueda unificada |
| 4. Selección de equipos | Completada | Modalidades 1v1/2v2/3v3, huecos con elegir/aleatorio/quitar, Guía reutilizada como selector |
| 5. Motor de combate | Completada | Base, suerte 7-77, feeling +33 por pareja, ganador/empate y trazabilidad completa |
| 6. Apple Foundation Models | Completada (simulador sin assets) | Prompts versionados, `@Generable`, timeout 20s, fallback de plantilla honesto y badge de origen |
| 7. Combate, resultados e historial | Completada | Historial Realm schemaVersion 2, guardado tras narración, listado con borrado/vaciado y detalle |
| 8. Diseño comic, Lottie, idiomas y accesibilidad | Completada | Wrapper con fallbacks y Reduce Motion, halftone, ComicCTALabel, cabecera de choque y assets `combat_intro`/`combat_winner` activos |
| 9. Calidad final | Completada | Limpieza de código muerto, cobertura 84,9 %, smoke tests de pantallas, build Release y docs de entrega |
| 10. Mejoras de combate | Completada | Afinidad sin paréntesis, familiares por identidad del compañero, suspense hasta la narración, feeling condicional y skill `iphone-duo` |
| 11. Aleatorio con índice completo | Completada | Pool precargado de 2/4/6 IDs sorteados, sorteo bajo demanda y catálogo local de respaldo |
| 12. Selector de duelos | Completada | Tarjetas de modo sin badge "VS"; el badge queda solo en la tarjeta "Duelos" de Home |
| 13. Borrado en el detalle | Completada | Sin papelera en las filas; presionar el combate abre su detalle con borrado y alerta de confirmación |
| 14. Adaptación iPhone Duo | Completada | `ArrangementView(.split)` en pantalla interior, ancho legible acotado y suite en verde en el simulador Duo |
| 15. Corrección arrangement en Duo vertical | Completada | `.split.axes(.horizontal)` para no apilar paneles y test de regresión geométrico |
| 16. Arrangement adaptativo | Completada | ArrangementView fuera del scroll con paneles de scroll propio: lado a lado en horizontal, apilado en vertical |

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

## Herramienta — índice de IDs de SuperHeroAPI

- `scripts/download_ids.py` descarga `https://superheroapi.com/ids.html` (sin token), recorre sus tres tablas y extrae los IDs numéricos.
- Salida: `data/character_ids.json`, una lista de enteros deduplicados y ordenados. Actualmente contiene **731 IDs** (1…731).
- Validaciones: mínimo de 500 IDs en la primera ejecución, fallo si el JSON anterior está corrupto y fallo si el recuento cae más del 20 %.
- Escritura atómica; si no hay cambios, no reescribe el archivo.
- `.github/workflows/update-character-ids.yml` se ejecuta los lunes a las 06:17 UTC y mediante `workflow_dispatch`. Solo commitea `data/character_ids.json` con `github-actions[bot]`.
- Dependencias fijadas en `requirements.txt`: `requests==2.32.5` y `beautifulsoup4==4.15.0`.
- Pruebas locales ejecutadas: ejecución real (731 IDs), segunda ejecución sin cambios y fallos simulados (sin tablas, menos de 500 IDs, caída >20 %, JSON corrupto, HTTP 404). En todos los fallos el JSON previo queda intacto y el script devuelve código distinto de cero.

## Fase 3 — completada (imágenes pendientes)

- [x] `data/character_ids.json` empaquetado como recurso del target; verificado dentro de `SuperHeroBattle.app` con 731 IDs.
- [x] `CharacterIDProviding` y `BundledCharacterIDProvider`, con validación de recurso ausente, JSON inválido, IDs no positivos y lista vacía.
- [x] `HeroCatalogRepository.heroes(ids:)` para leer páginas completas de la caché.
- [x] `LoadHeroesByIDsUseCase`: caché Realm primero, remoto solo para IDs ausentes, concurrencia máxima de 6, orden por ID solicitado, omisión de `notFound` y propagación del resto de errores.
- [x] Modelo `HeroObject` + `HeroRecord` y `RealmHeroCatalogRepository`; el héroe completo se guarda como JSON inmutable y los campos indexables quedan como columnas.
- [x] Configuración y migraciones de Realm centralizadas en `RealmStore` (schemaVersion 1).
- [x] Respaldo en memoria si Realm no se puede abrir.
- [x] Paginación de 30 IDs en la Guía con skeletons, precarga a 5 filas del final, footer de carga, footer de reintento y fin de catálogo.
- [x] Al fallar una página no se avanza el cursor; los héroes ya cacheados se conservan para el reintento.
- [x] Búsqueda unificada: catálogo por defecto, búsqueda al enviar y vuelta al catálogo al limpiar.
- [x] Filtros locales por editorial y género sobre los héroes cargados.
- [x] Pantalla de detalle con PowerStats numéricos accesibles, biografía, apariencia, trabajo y conexiones.
- [x] Localización en inglés y español con paridad de claves.
- [ ] Caché de imágenes remotas: el host sigue devolviendo HTTP 403.

Decisiones de la fase:

- Tamaño de página fijo: 30 IDs.
- Concurrencia de detalle: 6 peticiones simultáneas.
- La búsqueda de Fase 2 se mantiene como modo alternativo dentro de la misma barra.
- Los filtros solo afectan a los héroes ya cargados, nunca al catálogo completo.
- El detalle se resuelve con los datos persistidos; no hace una petición adicional.

## Fase 4 — completada

- [x] `DuelModeView` con tarjetas 1v1 / 2v2 / 3v3 y navegación a la selección de equipos.
- [x] `TeamSelectionViewModel`: dos `TeamDraft`, asignar/sustituir/quitar por hueco, aleatorio que rellena solo el hueco pedido, cancelación con guardas de generación y precarga de la primera página al entrar.
- [x] Reglas: sin repetidos dentro de un equipo; el mismo héroe puede estar en ambos equipos; el aleatorio excluye solo los IDs del equipo que se rellena.
- [x] `TeamSlotView` reutilizable con estados vacío/ocupado, color de `TeamPalette` acompañado de texto y etiquetas de VoiceOver con equipo y número de hueco.
- [x] La Guía se reutiliza como selector (`onHeroSelected` opcional): cada hueco abre una hoja con catálogo, búsqueda y filtros; las filas eligen en lugar de navegar al detalle.
- [x] `BuildBattleParticipantsUseCase`: valida drafts completos y produce `BattleParticipants` en orden de huecos.
- [x] CTA "Iniciar combate" dentro del scroll, habilitado solo con ambos equipos completos; navega al puente `CombatPlaceholderView`.
- [x] Fakes de UI tests: argumento `-uitest-fakes` activa `FixedRosterHeroRepository`, `FixedCharacterIDProvider` y catálogo en memoria, sin red ni token.
- [x] UI test permanente del flujo Duelos → 3v3 → aleatorio completo → combate.
- [x] Localización en inglés y español con paridad de claves.

Decisiones de la fase:

- El CTA vive dentro del scroll: un footer fijo (`safeAreaInset`) ocultaba los últimos huecos tras él y sus acciones quedaban inaccesibles (detectado con jerarquías de UI test).
- La selección aleatoria usa el catálogo local; la primera página se precarga al entrar para que el botón aleatorio tenga datos aunque no se haya visitado la Guía.
- Los errores de precarga son silenciosos: el selector manual o la Guía presentan el error real.
- `DuelModeView` ya no usa `FeaturePlaceholderView`; las claves `duels.placeholder.*` se han retirado.

## Fase 5 — completada

- [x] `Domain/Combat/AffinityMatcher`: normaliza afiliaciones y familiares por comas, recorta espacios, compara en minúsculas con coincidencia exacta (sin parciales) y descarta vacíos, `-`, `unknown`, `none` y `n/a`.
- [x] `LuckProvider` en `Domain/Services` (junto a `RandomHeroPicker`): protocolo inyectable con `SystemLuckProvider` en 7…77. `SequenceLuckProvider` en los tests permite puntuaciones exactas.
- [x] `CombatEngine` en `Domain/Combat`: base = `PowerStats.baseScore` (media de conocidos), suerte por combatiente, +33 por pareja con coincidencia OR (nunca 66), total de equipo = individuales + feeling, ganador por mayor total y empate sin re-rolls.
- [x] El mismo héroe en ambos equipos produce dos combatientes con tiradas de suerte independientes.
- [x] `ResolveCombatUseCase`: delegación pura y síncrona sobre el motor.
- [x] `CombatView` y `CombatViewModel`: banner de ganador/empate con texto (no solo color), filas con base/suerte/total accesibles, feeling con elementos coincidentes, totales por equipo con formato localizado. Sustituye y elimina `CombatPlaceholderView`.
- [x] UI test extendido hasta la pantalla de resultado (`combat.outcome`, `combat.total.teamA/B`).
- [x] Localización en inglés y español con paridad; claves `combat.placeholder.*` retiradas.

Decisiones de la fase:

- La suerte se consume en orden: Equipo A y luego Equipo B, por hueco; documentado para tests deterministas.
- El ejemplo conceptual del prompt maestro ("feeling 66" en un equipo de tres) contradice sus propias reglas (33 por pareja, tres parejas = 99); se siguen las reglas, no el ejemplo.
- `SequenceLuckProvider` es `@unchecked Sendable` con nota: el motor lo consume síncronamente desde un único contexto.

## Fase 6 — completada

- [x] `GenerateCombatNarrationUseCase`: comprueba disponibilidad, delega en el servicio de IA y cae a la plantilla ante error o respuesta vacía. La cancelación se propaga y nunca se sustituye por el fallback.
- [x] `Data/FoundationModels/NarrationPrompts`: prompts versionados (`version = 1`) en un único punto; reglas invariables (no cambiar ganador ni puntuaciones, no inventar PowerStats, no traducir nombres propios, simulación ficticia) y estructura narrativa completa. Solo datos del dominio; sin tokens.
- [x] `GeneratedNarration` con `@Generable` y `@Guide`; el texto se valida antes de publicarse.
- [x] `FoundationModelsNarrationService`: comprueba `SystemLanguageModel.default.availability`, sesión por generación, **timeout de 20 s** que cancela la tarea y errores tipados (`NarrationError`).
- [x] `TemplateNarrationService`: fallback determinista y localizado con `source: .template`; sin simular IA.
- [x] `CombatView` muestra la narración con badge de origen (`foundationModels` / `template`), indicador de generación y carga por `.task` que no bloquea la UI.
- [x] Idioma de la narración derivado de `AppLanguage.narrationCode`; nombres propios sin traducir.
- [x] Corregido un bug latente de localización: `L10n.string` ahora resuelve el bundle del `lproj` pedido (antes `String(localized:)` respondía siempre en el idioma del proceso).
- [x] Tests con `MockNarrationService` (actor interno para registro): plantilla, caso de uso y view model. Los tests nunca invocan el modelo real.
- [x] UI test permanente con fakes: afirma la narración de plantilla y su badge.

Verificación con el modelo REAL (probe temporal, eliminado tras la comprobación, nunca commiteado): en el simulador iPhone 27.0 de este MacBook Pro M4, `availability` reporta `available` pero los assets del modelo no están aprovisionados (`Model Catalog 5000` / `LanguageModelError -1`), y la generación directa falla. La ruta de producción completa (servicio real que falla → caso de uso → plantilla) devolvió una narración española correcta con `source: .template`. En un dispositivo real con Apple Intelligence la ruta IA se activará sin cambios de código; en este entorno el fallback funciona exactamente como exige AGENTS.md: sin simular IA.

Decisiones de la fase:

- Timeout de 20 s, constante única (`FoundationModelsNarrationService.timeout`), cancelando la generación al agotarse.
- En modo `-uitest-fakes` el servicio de IA ni se instancia: la plantilla alimenta los UI tests.
- La sesión de `LanguageModelSession` se crea dentro de la tarea de generación: nunca cruza aislamientos.

### Ajuste de narración (prompt v2)

Tras verificar la IA real en un iPhone con iOS 26.5, se afinó la generación:

- `NarrationContext`: cada combatiente llega etiquetado con su bando (`[TEAM A]` / `[TEAM B]`, roster por equipo, base/suerte/total individuales y feeling por bando). En 2v2/3v3, y cuando el mismo héroe está en ambos equipos, el modelo ya no puede confundir los bandos.
- Tono por diferencia: `gap >= 30` se narra como victoria clara (`CLEAR`), `gap < 30` como combate reñido (`CLOSE`) y empate como igualada sin vencedor.
- Regla creativa acotada: el modelo puede añadir UN detalle característico del lore conocido del personaje, sin inventar PowerStats ni contradecir los datos.
- Ejemplos de estilo few-shot localizados (en/es), marcados como referencia, nunca contenido a copiar.
- `GeneratedNarration` pasa a cuatro beats (`opening`, `exchange`, `climax`, `verdict`) y `NarrationOutputValidator` exige: beats completos, ambos equipos nombrados y el ganador proclamado en el veredicto; si falla → `NarrationError.invalidResponse` → plantilla.
- `GenerationOptions(temperature: 0.8, maximumResponseTokens: 400)`. `ContextOptions` es solo iOS 27 y no se usa para mantener compatibilidad con iOS 26.
- Verificación en simulador: la inferencia sigue fallando por falta de assets del host (error documentado arriba); la ruta de producción cae a plantilla correctamente. La verificación con IA real se hace en dispositivo físico con Apple Intelligence.

### Manejo del guardrail de seguridad (prompt v3)

Tras probar en un iPhone real con iOS 26.5 apareció `Safety guardrails were triggered`: el modelo ejecutaba pero la política de contenido rechazaba la generación (antes de esto, el error de simulador era de assets, no de contenido).

- `NarrationError.guardrail(String)` y `NarrationErrorClassifier`: clasifican la violación por tipo (`GenerationError.guardrailViolation` en iOS 26, `LanguageModelError.guardrailViolation` en iOS 27) con respaldo textual; la cancelación se preserva intacta.
- Las sesiones usan `SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)` para reducir falsos positivos en narración ficticia. La puerta de entrada sigue siendo `SystemLanguageModel.default.availability`, como exige AGENTS.md.
- Reintento único: si el intento creativo cae en guardrail, se reintenta con el prompt **safe mode** (acción familiar, nada de armas ni lesiones, ejemplos neutros) en una sesión nueva, dentro del mismo presupuesto total de 20 s. Si vuelve a fallar, `NarrationError.guardrail` tipado → plantilla honesta. El resto de errores no reintenta.
- Las `@Guide` de los beats se suavizaron (*"dazzling displays of ability"*, *"decisive teamwork"*) para ambos modos.
- El reintento se prueba con un seam inyectable (`FoundationModelsNarrationService(attempt:)`): nunca invoca el modelo real en tests.

### Ajuste tras verificación real en dispositivo (prompt v4)

Verificado en iPhone con iOS 26.5 con logs de diagnóstico temporales (retirados tras confirmar):

- El flujo real observado: el intento creativo dispara el guardrail ("May contain unsafe content") y el reintento safe responde correctamente; los fallos restantes venían de la validación, no de la IA.
- Etiquetas y líneas de resultado localizadas por idioma (`[Equipo A]` / `[Team A]`, "El ganador es Equipo B"), para que el modelo no ecoar etiquetas en otro idioma.
- `NarrationOutputValidator` pasa a validar **por héroes o equipos**: un bando está presente si aparece su nombre (inglés o español, con o sin corchetes) o cualquiera de sus héroes; el veredicto vale si nombra al ganador por equipo o por uno de sus héroes. El caso real del dispositivo (narrativa solo con nombres de héroes) ya valida.
- Temperaturas por intento: 0.8 creativo, 0.5 safe (menor desviación del prompt tras un rechazo).
- Regla dura en ambos prompts (v4): los compañeros de un mismo equipo nunca se atacan; cooperan y se cubren, y los enfrentamientos son solo entre bandos. Reforzada en las `@Guide` de `exchange` y `climax` y en el beat de apertura (nombra ambos equipos explícitamente).
- Resumen de la verificación final con IA real: narración generada con Apple Intelligence en español, combate 2v2 reñido (gap 20), héroes bien emparejados por bandos y ganador proclamado en el desenlace.

## Fase 7 — completada

- [x] `HeroSnapshot` ahora es `Codable` (y `HeroAlignment`, que no lo sintetiza automáticamente); `CombatRecord` y `CombatOutcome` son `Hashable` para navegar por valor.
- [x] `CombatHistoryRepository.deleteAll()` para el vaciado y `DeleteCombatHistoryUseCase.executeAll()`.
- [x] `CombatRecordSnapshot` (Codable): descompone `CombatOutcome` en `outcomeKind` + `winnerSide` y preserva narración y origen.
- [x] `CombatObject` en Realm (id/date/mode indexadas + payload JSON) y **schemaVersion 2** documentada en `RealmStore`.
- [x] `RealmCombatHistoryRepository`: confinado al actor principal, listado por fecha descendente, respaldo en memoria si Realm no abre.
- [x] `CombatViewModel` guarda **explícitamente**: botón "Guardar en el historial" habilitado cuando la narración está publicada (el registro exige narración y su origen), alerta de confirmación y vuelta a Home tras guardar. Snapshots, modalidad, ganador/empate, narración y origen, con fecha del `TimeProvider` inyectable. Sin suerte, feeling ni cálculos. Un fallo de Realm es silencioso y permite reintentar sin navegar.
- [x] `HistoryView` + `CombatHistoryViewModel`: tarjeta en Home, listado, estado vacío, borrado individual **con alerta de confirmación** (mensaje con los dos equipos), vaciado con alerta y reintento ante fallo de carga.
- [x] `CombatRecordDetailView`: fecha, modalidad, banner de ganador/empate, equipos con retratos y narración persistida con badge de origen.
- [x] Localización en inglés y español con paridad; accesibilidad con etiquetas y Dynamic Type.
- [x] UI test con fakes: combate completo → tres niveles atrás → historial con el registro → borrado → estado vacío.

Decisiones de la fase:

- El guardado es **explícito**: el usuario pulsa Guardar, confirma el alerta y navega a Home; sin pulsarlo no se historifica nada (el registro exige narración y su origen, por lo que el botón se habilita al publicarse la narración).
- El guardado es silencioso ante fallos: el combate sigue en pantalla y el usuario puede reintentar.
- `RootView` gestiona la pila con `NavigationPath` para volver a la raíz tras guardar.
- El estado vacío combinado se expone como `StaticText` en la jerarquía de accesibilidad; los UI tests lo consultan así.
- Las confirmaciones (guardar, borrado individual y vaciado) son **alerts clásicos centrados** (no `confirmationDialog` tipo action sheet, que se mostraba incorrectamente); los UI tests cubren presentación, cancelación sin pérdida y acción destructiva.

## Fase 8 — completada

- [x] `Core/Lottie/ComicLottieView.swift`: primer uso real del paquete Lottie (`LottieView` SwiftUI). Lógica de decisión pura y testeable (`ComicLottie.decision`): asset ausente o Reduce Motion → fallback estático; asset presente y movimiento permitido → animación. Fallbacks intercambiables por vista y decorativos (`accessibilityHidden`).
- [x] `ComicLottieLoopMode` propio (`playOnce`/`loop`): ningún tipo de Lottie sale de `Core/Lottie` (encapsulación de AGENTS.md).
- [x] Cabecera de choque fija y decorativa en el combate: slot `combat_intro` con ráfaga comic de respaldo (rayos + "VS" + emblemas A/B), sin temporizadores que rompan los UI tests.
- [x] Slot `combat_winner` para el trofeo del banner de ganador (respaldo: `trophy.fill` actual) y entrada spring del banner desactivada con Reduce Motion.
- [x] `ComicBackground` con tramas de imprenta (halftone) dibujadas en un único `Canvas`, opacidad baja.
- [x] `ComicCTALabel` compartido para los CTAs amarillos: "Iniciar combate" y "Guardar en el historial" dejan de estar duplicados a mano.
- [x] Accesibilidad: `.isHeader` en títulos de sección para el rotor de VoiceOver; Reduce Motion cubierto en todo lo nuevo; areas táctiles y contraste revisados.
- [x] Tests de la matriz de decisión (asset × motion) sin depender del paquete Lottie.

Assets incluidos en `Resources/Lottie/` (folder reference, se empaquetan solos): `combat_intro.json` (512×512, bucle de ~2,5 s para la cabecera de choque) y `combat_winner.json` (1000×1000, una vez ~4 s para el trofeo). El slot de intro es cuadrado (104×104) para no deformar los assets cuadrados con `.resizable()`. Verificado objetivamente: capturas temprana/tardía de la pantalla de combate difieren (animación en movimiento) y la suite completa sigue en verde. Sin assets o con Reduce Motion, los fallbacks comic siguen gobernando solos; añadir más slots en el futuro solo requiere soltar el `.json` y colocar el slot en código.

## Pendiente inmediato — Fase 9

- Auditoría final de calidad: repaso de warnings, cobertura y accesibilidad en dispositivo.
- Revisión del estado de la caché de imágenes (sigue bloqueada por el 403 del host).
- Preparación de la entrega: estado de docs y README definitivos.

## Fase 9 — completada

- [x] **Limpieza**: eliminados `GetHeroesCatalogUseCase` (sustituido por `LoadHeroesByIDsUseCase`) y `TeamSide.opponent` (sin usos). `GetHeroDetailUseCase` se conserva para futuras mejoras del detalle, ahora con tests propios (búsqueda por ID, notFound, error de transporte y cancelación).
- [x] **Cobertura**: informe con `xcrun xccov`: del 72,8 % inicial al **84,9 % final**. Tests dirigidos a los huecos reales: dos smoke tests UI cubren las pantallas que ningún flujo alcanzaba (detalle de héroe con PowerStats, detalle de combate guardado y Ajustes) y `UnconfiguredHeroRepository` cubre la ruta real de producción sin token.
- [x] **Identificadores de accesibilidad** añadidos para testabilidad: `hero.detail.powerstats`, `home.settings`, `settings.root` y `history.row`.
- [x] **Build Release** verificado en simulador: compila sin warnings de código y el bundle no contiene `*.xcconfig` ni secretos; `character_ids.json`, `combat_intro.json`, `combat_winner.json`, `en.lproj` y `es.lproj` presentes.
- [x] **Sin TODO/FIXME** en el código; paridad de claves `en`/`es` verificada por test.
- [x] **Documentación de entrega**: README definitivo y este registro cerrado.

Hallazgos documentados de la auditoría:

- `FeaturePlaceholderView` (127 líneas) quedó **sin referencias** tras reescribir `DuelModeView` en Fase 4. Se conserva como componente reutilizable para pantallas futuras; si no se usa, es candidato a eliminación.
- La cobertura restante se concentra en ramas defensivas (payload corrupto, migraciones) y en vistas SwiftUI puras sin lógica extraíble; no se persigue el 100 % por decisión de alcance.
- `FoundationModelsNarrationService` marca ~37 % por diseño: los tests usan el seam inyectable y nunca invocan el modelo real (exigencia de AGENTS.md); la ruta real se verificó en dispositivo en Fase 6.

## Fase 10 — completada

- [x] **Skill `iphone-duo`** (`.opencode/skills/iphone-duo/`): HIG de Apple destilada en `references/hig-duo-guidelines.md`, reglas de oro por size class y mapa de decisiones pantalla a pantalla acordado con el usuario, para las fases siguientes sin releer la documentación oficial.
- [x] **Afiliaciones sin paréntesis**: `AffinityMatcher` descarta el contenido entre paréntesis y corchetes antes de comparar ("Avengers (honorary member)" → "avengers") y acepta `;` como separador adicional.
- [x] **Familiares por identidad del compañero**: la regla antigua de intersección de listas queda sustituida; ahora un familiar de un héroe debe coincidir con el nombre o alias biográfico de su compañero, en ambas direcciones ("Loki (adoptive brother)" + compañero Loki → +33). Los marcadores `unknown`, guiones y paréntesis vacíos se descartan.
- [x] **Suspense hasta la narración**: `CombatViewModel.isNarrationPublished` gobierna la revelación. El banner muestra la incógnita con "El combate se está librando…" y al publicarse la narración entra el ganador/empate con el spring existente (desactivado con Reduce Motion).
- [x] **Marcadores en suspense**: `SuspenseScoreText` rota números aleatorios plausibles (rango puro y testeable en `SuspenseScore`, escalado por tamaño de equipo) en el total de cada equipo y el total de cada combatiente; al revelarse muestra el valor real. Reduce Motion congela un único número y VoiceOver anuncia "Puntuación pendiente de narración" en vez del aleatorio; la etiqueta de accesibilidad del combatiente tampoco revela el total real en suspense.
- [x] **Cabecera de choque oculta con narración**: la vista con `combat_intro` se retira del layout cuando la narración está publicada (transición suave, sin movimiento con Reduce Motion).
- [x] **Feeling condicional**: la sección de feeling solo aparece si el equipo tiene bonus (1v1 nunca la muestra); la clave `combat.result.affinity.none` queda sin uso y se retira de `en`/`es`.
- [x] **Componentes compartidos**: `ComicVersusDivider` (antes triplicada), `CombatOutcomeBanner` (con variante de suspense e identificadores por pantalla), `CombatNarrationSection` (con estado de carga) y `SuspenseScoreText` reutilizados por combate y detalle de historial; identificadores de UI test estables.
- [x] Localización en inglés y español con paridad; claves nuevas `combat.outcome.pending` y `combat.score.pending`.
- [x] UI tests reordenados: la narración se espera primero y después se comprueba la revelación del ganador y los totales reales.

Decisiones de la fase:

- Base y suerte permanecen visibles durante el suspense (decisión del usuario); solo los totales se enmascaran.
- El número aleatorio de Reduce Motion se congela en un único valor: la información de "pendiente" sigue presente sin animación.
- La regla de familiares se sustituye en lugar de acumularse: compartir el mismo familiar entre dos héroes ya no otorga feeling (decisión del usuario).

Verificación Fase 10: build Debug correcto sin warnings de código, **250 unit tests + 5 UI tests en verde** en iPhone 17 (iOS 27.2), `xcodebuild -list` correcto. Suites nuevas: AffinityMatcherTests (19), SuspenseScoreTests (6) y cobertura de `isNarrationPublished` en CombatViewModelTests (11).

## Fase 11 — completada

- [x] **`RandomIDPicker`** en `Domain/Services` junto a `RandomHeroPicker`: protocolo inyectable con `SystemRandomIDPicker` (barajado, sin repeticiones, tolerante a índices pequeños).
- [x] **`DrawRandomHeroesUseCase`**: sortea IDs del índice completo (`CharacterIDProviding`) y carga las fichas con `LoadHeroesByIDsUseCase` (caché local primero, red para los ausentes, `notFound` omitidos). Devuelve héroes e IDs sorteados para que el llamador no repita tiradas; índice vacío o agotado devuelve vacío sin error.
- [x] **`TeamSelectionViewModel.prepareRandomPool()`** sustituye a la precarga de los 30 primeros IDs: al mostrar la pantalla se sortean `teamSize × 2` IDs (**2 en 1v1, 4 en 2v2, 6 en 3v3**) y su carga se lanza en segundo plano, una sola vez por pantalla y cancelable al salir.
- [x] **Cadena del botón aleatorio**: pool precargado (instantáneo, saltando los héroes ya presentes en el equipo que se rellena) → sorteo bajo demanda de un ID nuevo excluyendo lo ya sorteado → catálogo local como respaldo si no hay red ni índice → mensaje `noHeroesAvailable` como último eslabón. El aleatorio ya no sale solo de la base de datos local.
- [x] `AppContainer` compone el caso de uso una vez y lo inyecta en el view model; los UI tests con fakes (`FixedCharacterIDProvider` + roster de 12) cubren el pool de 6 del 3v3 sin cambios.
- [x] Copy de `team.selection.error.noHeroes` actualizado en `en`/`es` (hablaba de héroes descargados; ahora menciona conexión y guía).
- [x] Tests: `DrawRandomHeroesUseCaseTests` (9: conteo, exclusiones, agotamiento, notFound, errores de índice/carga, cancelación) y `TeamSelectionViewModelTests` reescrito con pool (17: tamaño por modalidad, una sola preparación, consumo en orden, salto de repetidos del equipo, sorteo bajo demanda sin repetir IDs, respaldo de catálogo, noHeroes, cancelaciones de botón y de preload).

Decisiones de la fase:

- La precarga de la primera página del catálogo (30 IDs) desaparece: el pool es la nueva preparación del botón aleatorio y las fichas que resuelve se guardan igualmente en Realm.
- Los IDs sorteados se contabilizan aunque su ficha no resuelva (`notFound`), para no volver a sortearlos.
- Un tap con el pool listo es instantáneo (sin `busySlot`); la espera solo existe en el sorteo bajo demanda o los respaldos.

Verificación Fase 11: build Debug correcto sin warnings de código propio (el linker reporta un aviso conocido del binario de RealmSwift), **264 unit tests + 5 UI tests en verde** en iPhone 17 (iOS 27.2).

## Fase 12 — completada

- [x] `ComicCard` desacopla el badge "VS" del énfasis: nuevo parámetro `showsVersusBadge` (por defecto `true`).
- [x] `DuelModeView` pasa `showsVersusBadge: false` en las tres tarjetas de modo; el 3v3 conserva su énfasis (`isPrimary`) pero ninguna tarjeta de modo muestra la etiqueta. La tarjeta "Duelos" de Home conserva su badge, según lo acordado con el usuario.
- [x] Sin cambios de tests: el badge es decorativo y ningún UI test lo cubre.

## Fase 13 — completada

- [x] **`CombatRecordDetailViewModel`** nuevo, con el patrón de `CombatViewModel`: retiene el registro, expone `isDeleting`/`isDeleted`, `canDelete` como guarda y `delete()` que delega en `DeleteCombatHistoryUseCase`. Fallo de Realm silencioso (reintento sin navegación) y sin doble borrado.
- [x] **`CombatRecordDetailView`**: pasa a recibir el view model (`AppContainer.makeCombatRecordDetailViewModel`) con botón de papelera en toolbar (`history.detail.delete`, deshabilitado durante/tras el borrado), alerta de confirmación reutilizando `history.delete.confirm.*` con los nombres de ambos equipos y `dismiss` al listado tras borrar (el listado se recarga solo al reaparecer).
- [x] **`HistoryView`**: la fila es el enlace completo al detalle; desaparecen la papelera por fila, el `recordPendingDeletion` y `deletionMessage`. El vaciado completo no se toca. `CombatHistoryViewModel.delete(record:)` queda sin llamadores y se elimina con sus tests (misma limpieza que la Fase 9).
- [x] Tests: `CombatRecordDetailViewModelTests` (3: borrado único y marca de borrado, guarda de doble intento con repositorio contador, fallo con reintento); `CombatHistoryViewModelTests` pierde el test de borrado individual; el UI test reordenado cubre fila → detalle → cancelación sin pérdida → confirmación → listado vacío.

Decisiones de la fase:

- La vista hace `dismiss` comprobando `isDeleted` en lugar del callback `onDeleted` de `CombatViewModel`: ahí hace falta porque `RootView` reinicia toda la pila; aquí basta un pop del propio detalle.

Verificación Fase 13: build Debug correcto sin warnings de código propio, **266 unit tests + 5 UI tests en verde** en iPhone 17 (iOS 27.2).

## Fase 14 — completada

- [x] **Ancho legible compartido**: `.comicReadableWidth()` en `Core/DesignSystem` (≈640 pt centrado, no-op en compact) aplicado a Home, selector de duelos, listado de historial y Ajustes (560 pt por su densidad).
- [x] **`ArrangementView` (iOS 27.1+) con `.split`** en las tres pantallas de dos paneles de la pantalla interior, gated con `#available` + size class regular (el target sigue en iOS 26.0, así que `CombatArrangementLayout` queda como respaldo manual para compact e iOS 26):
  - **Selección de equipos**: Equipo A primario y Equipo B secundario; el pliegue hace de separador y el CTA de inicio queda debajo a todo el ancho.
  - **Combate y detalle de historial**: resto (banners, equipos y guardado al final de la columna, decisión del usuario) primario y narración secundaria; el suspense y su animación de revelado se mantienen.
  - **Guía (ruta standalone)**: catálogo primario y ficha secundaria (patrón Mail); `CharacterGuideView` gana `onHeroDetailRequested` para que las filas pidan la ficha al panel en vez de empujar.
- [x] **Detalle vacío de la Guía**: `FeaturePlaceholderView` reutilizado (revive el componente sin referencias desde la Fase 4) con el badge "Próximamente" desactivable y claves nuevas `guide.split.placeholder.*` en `en`/`es`.
- [x] **UI tests**: el smoke test de detalle de héroe vuelve a Home relanzando la app, determinista en cualquier pose (en el Duo los controles de navegación se montan en el lateral y el botón atrás de `navigationBars.buttons` no siempre es localizable; además el detalle ya no es un nivel de navegación en regular).
- [x] **Skill `iphone-duo` actualizada** con la API real: `ArrangementView` como opción primaria con su gate de disponibilidad, y la advertencia de que `NavigationSplitView` empujado dentro de un `NavigationStack` no renderiza su sidebar en compact (hallazgo real de esta fase).

Decisiones de la fase:

- Primera implementación con `HStack` por size class (lo que la HIG mapea conceptualmente a *arrangement views*); el usuario pidió explícitamente la API que indica la documentación y se migró a `ArrangementView(.split)`, que además gestiona la región de pliegue en poses parcialmente abiertas.
- La columna compacta no cambia ni un píxel (orden actual con narración antes del guardado y divisor "VS"); `ArrangementView` solo entra en ancho regular con iOS 27.1+.
- El divisor "VS" vertical se descartó: `ArrangementView` no permite inyectar vistas entre paneles y el pliegue ya separa; el horizontal de compact se conserva.
- `NavigationSplitView` se descartó para la Guía empujada: en compact el sidebar no renderizaba (tests lo detectaron); `ArrangementView` + selección cumple el mismo patrón Mail.

Verificación Fase 14: builds sin warnings de código propio, **266 unit tests + 5 UI tests en verde en iPhone 17 (compact) y en el simulador iPhone Duo (regular, iOS 27.2)**, `xcodebuild -list` correcto. La revisión de poses en Device Hub queda pendiente de pase visual del usuario.

## Fase 15 — completada

- [x] **Causa**: reporte del usuario — con el Duo abierto en vertical, la selección de equipos apilaba Equipo A, Equipo B y el CTA en un monto. El split arrangement por defecto divide verticalmente cuando la disposición es más alta que ancha (HIG: "splits vertically when the arrangement is taller than it is wide"), y la pantalla interior en portrait lo es.
- [x] **Corrección**: `.arrangementViewStyle(.split.axes(.horizontal))` — el límite de ejes que la HIG documenta — en las cuatro pantallas de paneles: selección de equipos, combate, detalle de historial y Guía. Lado a lado siempre en ancho regular, en cualquier orientación; el CTA de inicio queda debajo a todo el ancho, fuera del arrangement.
- [x] **Test de regresión geométrico**: `testTeamSelectionPanelsMatchWindowSizeClass` compara los frames de los botones aleatorios de ambos equipos: en ventana ancha (≥600 pt, pantalla interior del Duo) exige `minX(B) ≥ maxX(A)` (lado a lado); en compact exige `minY(B) ≥ maxY(A)` (apilados). Un mismo test valida ambos destinos de la suite y habría cazado el bug original (los tests existentes solo comprueban existencia y tap, no geometría).
- [x] Skill `iphone-duo` actualizada con la regla del eje horizontal y el mapa con la API exacta.

Verificación Fase 15: build sin warnings de código propio, **266 unit tests + 6 UI tests en verde en iPhone 17 (compact) y en el simulador iPhone Duo (regular)**, incluido el test geométrico en ambos.

## Fase 16 — completada

- [x] **Causa**: reporte del usuario — con el Duo abierto en horizontal solo se veía el Equipo A a todo el ancho y el CTA encima; el Equipo B desaparecía. El `ArrangementView` vivía dentro del `ScrollView` común: la altura infinita que propone el scroll rompía su decisión de eje (primero apilaba siempre; tras restringir `.axes(.horizontal)`, colapsaba el panel secundario en horizontal).
- [x] **Corrección**: el arrangement pasa a nivel de contenedor —fuera de todo scroll— en las cuatro pantallas de paneles, con `ScrollView` propio dentro de cada panel; el split por defecto vuelve a ser **adaptativo** (la HIG: lado a lado cuando es más ancho que alto, apilado cuando es más alto que ancho):
  - **Selección de equipos**: en horizontal A izquierda | B derecha con el CTA fijo debajo; en vertical A arriba, B abajo, con el CTA debajo (lo que el usuario pidió explícitamente).
  - **Combate y detalle de historial**: resto (guardado al final de su panel) y narración con scroll independiente, adaptativos a la orientación.
  - **Guía**: sin cambio estructural (ya estaba fuera del scroll); se retira la restricción de eje.
- [x] **Test geométrico actualizado** a la especificación adaptativa: rama por ancho ≥600 pt **y** ventana en horizontal (lado a lado) frente al resto (apilado). En el Duo en vertical (estado por defecto del simulador) valida A arriba, B abajo.
- [x] Skill actualizada con la regla real: nunca anidar `ArrangementView` en un `ScrollView`; paneles con scroll propio y eje por geometría.

Verificación Fase 16: build sin warnings de código propio, **266 unit tests + 6 UI tests en verde en iPhone 17 y en el simulador iPhone Duo**. La rama horizontal del test (lado a lado) queda cubierta por el comportamiento por defecto del arrangement con geometría real y pendiente del pase visual del usuario en landscape.

## Pendientes y riesgos

- **Token de SuperHeroAPI:** configurado localmente en `Secrets.xcconfig` y verificado con una búsqueda real. El archivo está ignorado por git y no se incluye en el bundle (verificado también en Release).
- **Imágenes de SuperHeroAPI:** el host `superherodb.com` responde HTTP 403 a peticiones directas, incluso con User-Agent y Referer de navegador. Catálogo y detalle muestran el placeholder correctamente, pero la caché de imágenes sigue pendiente (cabeceras específicas, proxy/CDN o fuente alternativa).
- `FeaturePlaceholderView` quedó sin referencias tras la Fase 4; se conserva como componente reutilizable, candidato a eliminación si no se usa.
- SuperHeroAPI no tiene endpoint de catálogo completo ni paginación; el catálogo se resuelve con el índice de IDs y llamadas por ID bajo demanda.
- El workflow programado se desactiva tras 60 días sin actividad en repositorios públicos; conviene ejecutar `workflow_dispatch` periódicamente. Si la rama `main` exige PR, el push del bot fallará y habrá que permitir escritura a Actions o cambiar el flujo a PR.
- Los tests del script no cubren el entorno real de GitHub Actions hasta que se ejecute el primer `workflow_dispatch` en el repositorio remoto.
- Foundation Models no está disponible en el simulador de este Mac (assets del modelo ausentes en el host); el fallback de plantilla cubre el flujo y la ruta IA se verificó en un iPhone real con iOS 26.5.
- Reintento automático con backoff y coalescencia de peticiones idénticas quedaron fuera por decisión de alcance.

## Verificación ejecutada

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -list -project SuperHeroBattle.xcodeproj
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Resultado Fase 9: build Debug y Release correctos sin warnings de código, **233 unit tests + 5 UI tests en verde** y cobertura del **84,9 %** en la app (desde el 72,8 % del inicio de la fase). Smoke tests nuevos cubren detalle de héroe, detalle de combate guardado y Ajustes; `GetHeroDetailUseCase` y `UnconfiguredHeroRepository` tienen cobertura directa. Bundle de Release verificado sin `*.xcconfig` ni secretos.

Resultado Fase 8: build correcto, **227 unit tests + 3 UI tests en verde** en iPhone 17 (iOS 27.0), sin warnings de código. La matriz de decisión del wrapper está cubierta sin invocar Lottie (asset presente/ausente × movimiento), los fallbacks no alteran ningún identificador de UI test y la suite de flujos completa sigue en verde.

Resultado Fase 7: build correcto, **222 unit tests + 3 UI tests en verde** en iPhone 17 (iOS 27.0), sin warnings de código. Cubierto: round-trip del registro en Realm (snapshots, narración, origen, empates), orden por fecha descendente, upsert por id, borrado individual y vaciado, guardado explícito desde el combate (habilitado con la narración, persiste con campos exactos, no guarda sin narración, reintenta tras fallo y navega a Home una sola vez), y el flujo UI completo: combate con fakes → guardar con alerta → Home → historial → alerts de vaciado y borrado individual (cancelar conserva, confirmar vacía). Realm schemaVersion 2 sin datos que migrar.

Resultado ajuste tras verificación real (v4): build correcto, **206 unit tests + 2 UI tests en verde**, sin warnings de código y sin logs de diagnóstico en el árbol. Cobierta la validación por héroes (incluido el caso real del dispositivo), el ganador por héroe del bando vencedor, el rechazo si el héroe es del perdedor, las temperaturas 0.8/0.5 por intento y la regla de compañeros en ambos prompts.

Resultado ajuste de narración: build correcto, **186 unit tests + 2 UI tests en verde**, sin warnings de código. Cubierto con suerte determinista: contexto etiquetado por bandos (incluido el mismo héroe en ambos equipos), umbral exacto de 30 (`gap >= 30` claro, 29 reñido), prompts v2 con lore acotado y ejemplos localizados, y validador de beats que rechaza respuestas sin ambos equipos o sin el ganador correcto en el veredicto (→ plantilla).

Resultado Fase 6: build correcto, **172 unit tests + 2 UI tests en verde** en iPhone 17 (iOS 27.0), sin warnings de código. La narración está cubierta con `MockNarrationService` (actor interno de registro): plantilla determinista y localizada en `en`/`es`, caso de uso con disponibilidad/error/cancelación, y view model con guarda de generación. Verificación con el modelo real en el simulador mediante probe temporal (eliminado, no commiteado): availability miente (`available`) porque los assets del modelo no están en el simulador; la generación directa falla y la ruta de producción cae a plantilla en español con `source: .template`, exactamente como exige AGENTS.md. En dispositivo real con Apple Intelligence la ruta IA se activa sin cambios.

Nota de la fase: `L10n.string` resolvía siempre en el idioma del proceso (`String(localized:)` no garantiza la selección por locale); ahora selecciona el bundle del `lproj` pedido. Esto corrigió también etiquetas de accesibilidad en español.

Resultado Fase 5: build correcto, **153 unit tests + 2 UI tests en verde** en iPhone 17 (iOS 27.0), sin warnings de código. El motor está cubierto con suerte determinista (`SequenceLuckProvider`): base y suerte por combatiente, tiradas independientes para el mismo héroe en ambos equipos, feeling +33 por pareja (0/1/3 parejas según modalidad, nunca entre equipos, nunca 66), totales, ganador y empate. El UI test llega con fakes hasta la pantalla de resultado y comprueba banner y totales de ambos equipos.

Resultado Fase 4: build correcto, **129 unit tests + 2 UI tests en verde** en iPhone 17 (iOS 27.0), sin warnings nuevos. El UI test del flujo de selección corre con `-uitest-fakes` (sin red ni token): Duelos → 3v3 → relleno aleatorio de los seis huecos → "Iniciar combate" habilitado → pantalla de combate.

Nota de la fase: el CTA dentro del scroll corrige una oclusión real; con un footer fijo (`safeAreaInset`), los botones del último hueco quedaban tapados y XCUI reportaba el botón como hittable aunque el tap no llegaba. Se diagnosticó dumpeando la jerarquía de accesibilidad.

Resultado Fase 3: build correcto, **111 unit tests + 1 UI test en verde** en iPhone 17 (iOS 27.0). `SuperHeroBattle.app` incluye `character_ids.json` con 731 IDs, `en.lproj` y `es.lproj`, y no incluye archivos `*.xcconfig`.

Verificación manual con API real: al entrar en la Guía se cargan los 30 primeros IDs (`A-Bomb` … `Ant-Man`). Al llegar al final se solicita la página siguiente y aparecen `Ant-Man II` … `Bane`. Al abrir `Bane` se muestra el detalle con PowerStats (inteligencia 88, fuerza 38, combate 95, etc.). La comprobación se hizo con un test UI temporal, ya eliminado.

Nota de localización: Xcode normaliza `localizations.supported` y trata `en` como idioma de desarrollo implícito; el bundle sigue conteniendo `en.lproj` y `es.lproj`, `CFBundleDevelopmentRegion` es `en` y el test de paridad de claves pasa.

Verificación manual previa de Fase 2: con el token configurado en `Secrets.xcconfig`, la búsqueda de `batman` devuelve 3 resultados (`Batman`, `Batman`, `Batman II`) y la app los publica en la Guía. Las imágenes remotas no cargan porque el host responde 403; se muestra el placeholder previsto.
