# Estado de implementación — SuperHeroBattle

Última actualización: 19/11/2026

Este documento es el registro vivo del proyecto. Se actualiza al cerrar cada fase y antes de cada commit relevante.

## Resumen

- **Fase actual:** Fase 9 cerrada. **Proyecto completado.**
- **Última fase cerrada:** Fase 9 — calidad final: limpieza, cobertura 84,9 %, build Release verificado y documentación de entrega.
- **Herramienta nueva:** índice público de IDs (`data/character_ids.json`) con actualización semanal mediante GitHub Actions.
- **Estado del build:** compila en Debug y Release sin warnings de código; **233 unit tests + 5 UI tests** en verde en Xcode 27.2 / iOS Simulator 27.0; cobertura del 84,9 % en la app.
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
