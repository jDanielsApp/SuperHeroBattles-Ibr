# SuperHeroBattle

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue)
![Xcode](https://img.shields.io/badge/Xcode-27.2%2B-blue)
![Plataforma](https://img.shields.io/badge/UI-SwiftUI-purple)

App iOS nativa que convierte SuperHeroAPI en un simulador de combates por equipos: consulta el catálogo de personajes, forma equipos de 1 vs 1, 2 vs 2 o 3 vs 3, y resuelve el ganador con un motor matemático en Swift. Apple Foundation Models se usa exclusivamente para narrar el combate; nunca decide el resultado.

Proyecto construido con SwiftUI, Clean Architecture + MVVM, Swift Concurrency estricta, RealmSwift para persistencia local y Lottie para animaciones.

## Índice

- [Estado actual](#estado-actual)
- [Arquitectura](#arquitectura)
- [Stack tecnológico](#stack-tecnológico)
- [Requisitos previos](#requisitos-previos)
- [Instalación y configuración](#instalación-y-configuración)
- [Comandos de uso habitual](#comandos-de-uso-habitual)
- [Configuración de secretos](#configuración-de-secretos)
- [Catálogo de personajes por IDs](#catálogo-de-personajes-por-ids)
- [Estructura del proyecto](#estructura-del-proyecto)
- [GitHub Actions](#github-actions)
- [Tests](#tests)
- [Localización y accesibilidad](#localización-y-accesibilidad)
- [Solución de problemas](#solución-de-problemas)
- [Hoja de ruta](#hoja-de-ruta)
- [Documentación adicional](#documentación-adicional)

## Estado actual

| Funcionalidad | Estado |
|---|---|
| Navegación Home → Guía → Detalle, Ajustes | ✅ Operativa |
| Catálogo paginado por IDs con caché Realm | ✅ Operativa |
| Búsqueda por nombre con caché TTL y cancelación | ✅ Operativa |
| Filtros locales (editorial, género) sobre los héroes cargados | ✅ Operativa |
| Detalle de personaje con PowerStats accesibles | ✅ Operativa |
| Selección de equipos y motor de combate | 🚧 En desarrollo | Selección de equipos operativa; motor de combate en Fase 5 |
| Narración con Apple Foundation Models | ⏳ Planificada |
| Historial de combates con Realm | ⏳ Planificada |
| Caché de imágenes remotas | ⚠️ Bloqueada por el host externo (HTTP 403) |

`docs/IMPLEMENTATION_STATUS.md` es el registro vivo de fases y decisiones; este cuadro es solo un resumen.

## Arquitectura

Clean Architecture + MVVM con dependencias apuntando siempre hacia el dominio:

```text
Presentation ──▶ Domain ◀── Data
                    ▲
                    └── Core (utilidades transversales, sin lógica de negocio)
```

- **Domain**: entidades `Sendable` puras, protocolos de repositorio y de servicios, casos de uso y el motor de combate. Solo Foundation y Swift estándar; sin SwiftUI, sin Realm, sin FoundationModels.
- **Data**: implementaciones de los protocolos, DTOs `Codable`, mapeadores, caché TTL, Realm y el generador de narrativas con Foundation Models.
- **Presentation**: vistas pequeñas y view models `@Observable` / `@MainActor`. Nunca acceden a red ni a Realm directamente; dependen de casos de uso.
- **App**: `AppContainer` compone las dependencias y las inyecta por inicializador. Los tests sustituyen cualquier dependencia externa por un fake.

Reglas clave que se aplican en revisiones:

- El historial y el catálogo persisten snapshots inmutables; nunca objetos de Realm ni DTOs.
- La IA solo narra: el resultado matemático del combate es inmutable.
- Prohibido `try!`, `as!` y force unwraps en código de producción.
- `async/await` en todo; sin callbacks ni `DispatchQueue` salvo interoperabilidad justificada.

## Stack tecnológico

| Área | Tecnología |
|---|---|
| Lenguaje | Swift 6 (concurrencia estricta) |
| UI | SwiftUI con `@Observable` y `@MainActor` |
| iOS mínimo | 26.0 |
| Arquitectura | Clean Architecture + MVVM |
| Red | `URLSession` con `async/await`, cliente HTTP propio |
| API | [SuperHeroAPI](https://superheroapi.com) (búsqueda por nombre y consulta por ID) |
| Persistencia | RealmSwift 20.x (vía SwiftPM) |
| IA | Apple Foundation Models (`import FoundationModels`, iOS 26+) |
| Animaciones | Lottie 4.6.x encapsulado en un wrapper SwiftUI |
| Localización | `Localizable.strings` clásico, inglés y español |
| Tests | XCTest (unit + UI) |
| Proyecto | Xcode 27.2 con formato JSON `project.xcproj` |

Las dependencias se resuelven con SwiftPM desde el `Package.resolved` versionado. **No hace falta CocoaPods ni Carthage.**

## Requisitos previos

1. **macOS con Xcode 27.2 o superior**, con el SDK de iOS 26+.
2. **Simulador iOS 26+ instalado**. La verificación de este proyecto se hace con *iPhone 17 (iOS 27.0)*.
3. **Token personal de SuperHeroAPI**, gratuito desde [superheroapi.com](https://superheroapi.com). Sin él la app arranca, pero la búsqueda y el catálogo remoto muestran un estado "no configurado".
4. **Python 3.9+ (opcional)**, solo si vas a ejecutar el actualizador del índice de IDs. La app no lo necesita: `data/character_ids.json` ya está empaquetado y versionado.

Si `xcode-select` apunta solo a Command Line Tools, exporta `DEVELOPER_DIR` antes de cualquier `xcodebuild`:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Instalación y configuración

```sh
# 1. Clonar
git clone https://github.com/jDanielsApp/SuperHeroBattles-Ibr.git
cd SuperHeroBattles-Ibr

# 2. Crear la configuración local de secretos (gitignored)
cp SuperHeroBattle/Config/Secrets.example.xcconfig SuperHeroBattle/Config/Secrets.xcconfig

# 3. Editar Secrets.xcconfig y poner tu token real
open -e SuperHeroBattle/Config/Secrets.xcconfig

# 4. Resolver dependencias con SwiftPM
xcodebuild -project SuperHeroBattle.xcodeproj -resolvePackageDependencies

# 5. Compilar
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
```

O simplemente abre `SuperHeroBattle.xcodeproj` en Xcode, espera a que SwiftPM termine y ejecuta el scheme **SuperHeroBattle**. La carpeta `SuperHeroBattle/` es una *folder reference*: los archivos nuevos se incluyen en el target automáticamente.

## Comandos de uso habitual

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

# Listar targets y schemes (útil para validar el proyecto)
xcodebuild -list -project SuperHeroBattle.xcodeproj

# Compilar (genérico, sin simulador concreto)
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build

# Tests unitarios y UI (elige un simulador instalado)
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Resolver dependencias de SwiftPM
xcodebuild -project SuperHeroBattle.xcodeproj -resolvePackageDependencies
```

Actualizador opcional del índice de IDs (no usa el token de SuperHeroAPI):

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python scripts/download_ids.py
```

## Configuración de secretos

El token nunca se hardcodea ni se commitea. Fluye así:

```text
Secrets.xcconfig (local, gitignored)
  └─ SUPERHERO_API_TOKEN
       └─ Info.plist (SuperHeroAPIToken) vía xcconfig
            └─ SuperHeroAPIConfiguration.live()
```

- `SuperHeroBattle/Config/Base.xcconfig`: versionado, sin secretos, define `SUPERHERO_API_BASE_URL`.
- `SuperHeroBattle/Config/Secrets.example.xcconfig`: plantilla versionada.
- `SuperHeroBattle/Config/Secrets.xcconfig`: archivo local real, en `.gitignore`.
- Ningún `*.xcconfig` acaba en el bundle: están excluidos de Copy Bundle Resources.

Normas de seguridad del proyecto:

- El token viaja en la URL de SuperHeroAPI, así que **nunca se registran URLs completas**.
- No se imprime el token en logs, errores, prompts ni tests.
- El script de IDs solo descarga `https://superheroapi.com/ids.html`; no necesita token ni datos sensibles.

## Catálogo de personajes por IDs

SuperHeroAPI **no tiene endpoint de catálogo completo**. El índice se resuelve con un artefacto propio:

1. `scripts/download_ids.py` descarga `https://superheroapi.com/ids.html`, extrae los IDs numéricos de sus tablas y escribe `data/character_ids.json` (enteros ordenados, sin duplicados; actualmente 731 IDs).
2. El JSON se empaqueta en la app como recurso y `BundledCharacterIDProvider` lo lee al arrancar.
3. La Guía pagina **30 IDs por página**: consulta primero la caché Realm, pide por ID solo los ausentes con **concurrencia máxima de 6**, omite los `notFound` y no avanza el cursor si la página falla.
4. Los filtros actúan solo sobre los héroes ya cargados, nunca sobre el catálogo completo.
5. El detalle se resuelve con los datos persistidos; no hace peticiones adicionales.

El índice se actualiza automáticamente los lunes a las 06:17 UTC mediante GitHub Actions (ver abajo).

## Estructura del proyecto

```text
SuperHeroBattle/
├── App/                  # Punto de entrada, navegación y composición (AppContainer)
├── Core/                 # Utilidades compartidas, sin lógica de negocio
│   ├── DesignSystem/     # Paleta y tipografía comic
│   ├── Localization/     # LocalizableStringKey, L10n y AppLanguage
│   ├── Lottie/           # Wrapper SwiftUI de animaciones
│   ├── Networking/       # Cliente HTTP y errores de red
│   ├── Persistence/      # Configuración y migraciones de Realm
│   └── Time/             # Reloj inyectable
├── Domain/
│   ├── Entities/         # Modelos de negocio Sendable
│   ├── Repositories/     # Protocolos de repositorio
│   ├── Services/         # Protocolos (IDs, narración, aleatoriedad)
│   ├── UseCases/         # Casos de uso
│   └── Combat/           # Motor de combate puro
├── Data/
│   ├── Network/          # DTOs, mapeadores y cliente SuperHeroAPI
│   ├── Cache/            # Caché TTL de búsquedas
│   ├── Catalog/          # Proveedor del índice de IDs empaquetado
│   ├── Persistence/      # Modelos Realm y snapshots inmutables
│   └── Repositories/     # Implementaciones de los protocolos
├── Presentation/
│   ├── Features/         # Home, CharacterGuide, DuelMode, Settings…
│   └── Components/       # Vistas reutilizables
└── Resources/            # Assets, Lottie, en.lproj, es.lproj, Info.plist

Tests/                    # XCTest: UnitTests y UITests
scripts/download_ids.py   # Actualizador del índice de IDs
data/character_ids.json   # Índice de IDs versionado y empaquetado
docs/                      # Documentación y estado de implementación
```

Reglas de ubicación (resumen): un tipo principal por archivo; DTOs en `Data/Network`; modelos Realm en `Data/Persistence/Realm`; vistas sin lógica de negocio; documentación solo en `docs/`. `AGENTS.md` contiene el reglamento completo.

## GitHub Actions

`.github/workflows/update-character-ids.yml` actualiza el índice los lunes a las 06:17 UTC y bajo demanda (`workflow_dispatch`). No necesita secretos: usa el `GITHUB_TOKEN` automático y solo commitea `data/character_ids.json`.

Configuración única tras el primer push:

1. Pestaña **Actions** del repositorio → habilita los workflows si la UI lo pide.
2. **Settings → Actions → General → Workflow permissions** → marca **Read and write permissions**.
3. Si `main` tiene reglas de protección, añade `github-actions[bot]` a la *bypass list* o cambia el workflow para abrir un PR.
4. Ejecuta **Run workflow** sobre `main` para verificar el flujo completo.

Comportamiento esperado: con el índice sin cambios verás `Sin cambios: 731 IDs.` y el run termina en verde sin commit. GitHub puede retrasar el disparo programado y desactiva los cron tras 60 días de inactividad en repositorios públicos; una ejecución manual lo reactiva.

## Tests

Estado actual: **111 tests unitarios + 1 UI test** en verde sobre iPhone 17 (iOS 27.0).

Convenciones del proyecto:

- Ningún test toca red, hora del sistema ni el modelo real de IA: se inyectan `TimeProvider`, RNG fakes, `URLProtocolStub`, catálogos en memoria y narradores falsos.
- Realm se prueba con configuración in-memory (`Realm.Configuration(inMemoryIdentifier:)`).
- Se cubre cancelación (una respuesta obsoleta nunca sobrescribe una reciente), expiración de caché con reloj falso y paridad de claves `en`/`es`.
- Los UI tests son pocos y estables, con el flujo principal; la verificación de la API real se hace con tests temporales que luego se eliminan.

Aviso conocido: en este formato de proyecto, `xcodebuild test` elimina `SuperHeroBattle.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Restáuralo antes de commitear:

```sh
git checkout -- SuperHeroBattle.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

## Localización y accesibilidad

- Interfaz y narración en inglés y español con `Localizable.strings` clásico (sin String Catalogs). El idioma se elige en Ajustes y se aplica a toda la app; los nombres propios no se traducen.
- Estética comic book con `ComicPalette` y `TeamPalette`, con color siempre acompañado de texto o icono.
- Las barras de PowerStats exponen el valor numérico y anuncian los desconocidos como "no disponible".
- VoiceOver, Dynamic Type, Reduce Motion y áreas táctiles verificadas en todas las pantallas; Lottie cae a un fallback estático con Reduce Motion activo.

## Solución de problemas

| Síntoma | Causa | Solución |
|---|---|---|
| Xcode no puede abrir el proyecto | Versión de Xcode anterior a 27.2 | Actualiza Xcode; el formato `project.xcproj` es JSON |
| La Guía muestra "no configurado" | Falta `Secrets.xcconfig` o el token es el placeholder | Copia `Secrets.example.xcconfig` y pon tu token real |
| Las fichas no cargan en el simulador | Sin red o token inválido | Revisa la conexión; el token se valida contra la API real |
| Las imágenes de personajes no aparecen | El host `superherodb.com` responde HTTP 403 | Comportamiento conocido; se muestra el placeholder previsto |
| La narración es una plantilla | Foundation Models no está disponible (simulador o equipo sin Apple Intelligence) | Fallback determinista previsto; no se simula IA |
| `xcodebuild: Unable to read project` | `xcode-select` apunta a Command Line Tools | `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` |
| Falta `Package.resolved` tras los tests | `xcodebuild test` lo elimina en este formato | `git checkout -- SuperHeroBattle.xcodeproj/.../Package.resolved` |
| El workflow de Actions falla al pushear | Permisos de solo lectura o `main` protegida | Settings → Actions → Workflow permissions → Read and write; bypass para el bot |

## Hoja de ruta

- [x] Fase 0-1: arquitectura, dominio, navegación y composición de dependencias
- [x] Fase 2: cliente SuperHeroAPI, búsqueda con caché TTL y cancelación
- [x] Fase 3: catálogo paginado por IDs, Realm, filtros y detalle
- [x] Fase 4: selección de equipos con `TeamDraft`
- [ ] Fase 5: motor de combate (PowerStats, suerte, afinidad de equipos)
- [ ] Fase 6: narración con Apple Foundation Models y fallback local
- [ ] Fase 7: combate, resultados e historial en Realm
- [ ] Fase 8: diseño comic completo, Lottie y accesibilidad final
- [ ] Fase 9: calidad final
- [ ] Caché de imágenes remotas (bloqueada por HTTP 403 del host)

## Documentación adicional

- `AGENTS.md` — reglamento de arquitectura, convenciones y verificación del proyecto.
- `docs/IMPLEMENTATION_STATUS.md` — registro vivo de fases, decisiones y pendientes.
- `docs/PROMPT_MAESTRO.md` — especificación original del producto.
- `.github/workflows/update-character-ids.yml` — automatización semanal del índice de IDs.
