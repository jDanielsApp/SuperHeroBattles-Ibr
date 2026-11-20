# AGENTS.md — SuperHeroBattle

Este documento define cómo trabajar en el proyecto. Léelo antes de modificar código y respeta las reglas de arquitectura, seguridad y verificación.

## 1. Contexto del producto

SuperHeroBattle es una app iOS nativa que permite:

- Consultar superhéroes desde SuperHeroAPI.
- Formar equipos y simular combates.
- Generar narrativas de combate con Apple Foundation Models.
- Guardar el historial local de combates con Realm.

El código, los nombres de tipos, las ramas, los commits y los comentarios técnicos (`//`, `///`, `// MARK:`) se escriben en inglés. La documentación del proyecto (`docs/`) se mantiene en español. Los textos visibles para el usuario se externalizan en inglés y español; los nombres propios de personajes, grupos y editoriales no se traducen.

## 2. Stack y requisitos

- Swift 6 (modo de lenguaje estricto).
- SwiftUI con `@Observable` y `@MainActor` por defecto.
- iOS 26.0 como deployment target mínimo.
- Apple Foundation Models (`import FoundationModels`), disponible solo en iOS 26+ y dispositivos con Apple Intelligence.
- RealmSwift 20.x mediante SwiftPM (`https://github.com/realm/realm-swift.git`).
- Lottie 4.6.x mediante SwiftPM (`https://github.com/airbnb/lottie-ios.git`), encapsulado en un wrapper SwiftUI.
- SuperHeroAPI como backend HTTP.
- Localización clásica con `Localizable.strings` en inglés y español. No se usan String Catalogs.
- XCTest para unit tests y UI tests.
- Xcode 27.2 o superior, con el formato de proyecto JSON `project.xcproj`.

## 3. Comandos

`xcode-select` puede apuntar a Command Line Tools. Para compilar usa siempre `DEVELOPER_DIR`:

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Listar targets y schemes:

```sh
xcodebuild -list -project SuperHeroBattle.xcodeproj
```

Compilar:

```sh
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'generic/platform=iOS Simulator' build
```

Ejecutar tests (elige un simulador instalado):

```sh
xcodebuild -project SuperHeroBattle.xcodeproj -scheme SuperHeroBattle \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Resolver dependencias:

```sh
xcodebuild -project SuperHeroBattle.xcodeproj -resolvePackageDependencies
```

Validar el proyecto después de editar `project.xcproj`:

```sh
xcodebuild -list -project SuperHeroBattle.xcodeproj
```

Actualizar el índice de IDs de personajes (requiere Python 3.9+ y las dependencias de `requirements.txt`):

```sh
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/python scripts/download_ids.py
```

El script solo descarga `https://superheroapi.com/ids.html`, no usa el token de SuperHeroAPI y escribe `data/character_ids.json`. La automatización semanal vive en `.github/workflows/update-character-ids.yml`.

No cambies `xcode-select` de forma global sin permiso del usuario.

## 4. Estructura del proyecto

```text
SuperHeroBattle/
├── App/                          # Punto de entrada, navegación y composición de la app
├── Core/                         # Utilidades compartidas, sin lógica de negocio
│   ├── DesignSystem/             # Paleta, tipografía y componentes base
│   ├── Images/                   # Caché y carga de imágenes
│   ├── Localization/             # LocalizableStringKey, L10n y AppLanguage
│   ├── Lottie/                   # Wrapper SwiftUI de animaciones
│   ├── Networking/               # Cliente HTTP y errores de red
│   ├── Persistence/              # Configuración y migraciones de Realm
│   └── Time/                     # Reloj inyectable
├── Domain/
│   ├── Entities/                 # Modelos de negocio puros
│   ├── Repositories/             # Protocolos de repositorio
│   ├── Services/                 # Protocolos de servicios (narración, aleatoriedad)
│   ├── UseCases/                 # Casos de uso
│   └── Combat/                   # Motor de combate puro
├── Data/
│   ├── Network/SuperHeroAPI/     # Cliente HTTP, DTOs y mapeadores
│   ├── Cache/                    # Caché TTL de búsquedas
│   ├── Persistence/Realm/        # Modelos Realm, catálogo e historial
│   ├── FoundationModels/         # Narrativa con Apple Foundation Models
│   └── Repositories/             # Implementaciones de los protocolos
├── Presentation/
│   ├── Features/                 # Home, Search, CharacterGuide, CharacterDetail,
│   │                             # DuelMode, TeamSelection, Combat, History, Settings
│   └── Components/               # Vistas reutilizables
├── Resources/
│   ├── Assets.xcassets
│   ├── Lottie/
│   ├── en.lproj/Localizable.strings
│   ├── es.lproj/Localizable.strings
│   └── Info.plist
└── Config/                       # xcconfig y secretos locales
Tests/
├── UnitTests/
└── UITests/
scripts/                          # Herramientas de mantenimiento (Python)
├── download_ids.py               # Índice de IDs desde ids.html
requirements.txt                  # Dependencias Python con versiones fijadas
data/
└── character_ids.json            # Índice de IDs versionado y empaquetado en la app
.github/
└── workflows/
    └── update-character-ids.yml  # Actualización semanal del índice de IDs
docs/                             # Documentación y estado de implementación
```

Reglas de ubicación:

- Un tipo principal por archivo.
- Los DTOs y mapeadores viven en `Data/Network`.
- Los modelos de Realm viven en `Data/Persistence/Realm`.
- Las implementaciones de repositorios viven en `Data/Repositories`.
- Las vistas no acceden directamente a red ni a Realm.
- La documentación vive en `docs/` y no dentro de `SuperHeroBattle/`, porque la folder reference compila y copia su contenido.

## 5. Arquitectura

Regla de dependencias:

```text
Presentation → Domain ← Data
```

- `Domain` no importa SwiftUI, Realm ni FoundationModels. Solo Foundation y Swift estándar.
- `Domain` define entidades, protocolos de repositorio, protocolos de servicios y casos de uso.
- Los modelos de dominio son `Sendable` puros. El estado mutable de presentación vive en view models `@MainActor`.
- `Data` implementa esos protocolos y traduce entre DTOs/Realm y entidades de dominio.
- `Presentation` depende de casos de uso y protocolos, nunca de implementaciones concretas.
- La composición de dependencias se hace en `App/AppContainer`.
- El historial y el catálogo persisten snapshots inmutables; nunca se guardan objetos de Realm ni DTOs.

Inyección de dependencias:

- Usa protocolos para repositorios y servicios.
- Pasa dependencias por inicializador.
- No uses singletons globales salvo que sea imprescindible; si lo haces, documéntalo.
- Los tests deben poder sustituir cualquier dependencia externa por un fake.

## 6. Convenciones Swift y SwiftUI

- Swift 6 con concurrencia estricta y aislamiento `MainActor` por defecto.
- Las entidades y servicios de `Domain` se marcan `nonisolated` para no depender del actor principal.
- Usa `async/await`; no uses callbacks ni `DispatchQueue` salvo interoperabilidad justificada.
- Prohíbe `try!`, `as!` y force unwraps en código de producción.
- Usa `guard` para salidas tempranas y errores tipados.
- Los view models son `@Observable` y `@MainActor`.
- Las vistas son pequeñas; extrae subvistas a `Presentation/Components`.
- No pongas lógica de negocio en las vistas.
- Usa `@State` para estado local, `@Bindable` para view models observables y `@Environment` para dependencias compartidas.
- Respeta el Dynamic Type, VoiceOver, Reduce Motion y los tamaños de pantalla.
- No introduzcas dependencias nuevas sin justificarlo y actualizar este documento.

## 7. Red y SuperHeroAPI

- Usa `URLSession` con `async/await`.
- Centraliza la URL base y el token en `Bundle` (`SuperHeroAPIBaseURL` y `SuperHeroAPIToken`).
- No hardcodees el token ni lo incluyas en logs, errores, prompts o tests. El token viaja en la URL de SuperHeroAPI: nunca registres URLs completas.
- Separa DTOs (`Codable`) de entidades de dominio.
- Valida el código de estado HTTP antes de decodificar. SuperHeroAPI puede devolver errores con HTTP 200: valida también el campo `response`.
- Propaga errores tipados y añade contexto sin filtrar secretos.
- Cancela tareas cuando la vista desaparezca.
- La búsqueda usa identidad de petición y cancela la anterior; una respuesta obsoleta nunca puede publicarse.
- Implementa caché TTL por query normalizada con reloj inyectable.
- Los tests no deben hacer peticiones reales: usa `URLProtocol` o un cliente HTTP falso.
- No inventes endpoints: SuperHeroAPI solo ofrece búsqueda por nombre y consulta por ID. No existe un endpoint de catálogo completo.
- El catálogo se construye a partir de `data/character_ids.json`, un índice público de IDs generado por `scripts/download_ids.py` y actualizado semanalmente por GitHub Actions. La app conoce todos los IDs al arrancar y pide las fichas por ID bajo demanda, nunca mediante búsquedas masivas.
- El índice de IDs solo contiene enteros ordenados y sin duplicados; no incluye nombres, fichas ni imágenes. No requiere token y no debe commitearse ningún dato sensible junto a él.
- La Guía carga páginas de 30 IDs con concurrencia máxima de 6 para las fichas. Consulta primero Realm, pide solo los IDs ausentes, omite los `notFound` y no avanza el cursor si la página falla.
- La carga de imágenes remotas está cerrada: las imágenes cargan con normalidad y su disponibilidad depende de la respuesta del host externo; los fallos puntuales muestran el placeholder.

## 8. Persistencia con Realm

- Usa `RealmSwift` y mantén los modelos en `Data/Persistence/Realm`.
- Nunca expongas clases `Object` ni objetos gestionados a `Domain` o `Presentation`.
- Mapea siempre entre modelos Realm y entidades de dominio.
- Realm está confinado a su actor/hilo: no pases objetos gestionados entre actores.
- Marca los repositorios de persistencia como `@MainActor` mientras no haya una razón medida para lo contrario.
- Si necesitas leer en segundo plano, usa `freeze()` o una `Realm` creada en ese contexto y devuelve valores inmutables.
- Gestiona migraciones en un único punto y documenta cada cambio de esquema.
- En tests usa una configuración in-memory (`Realm.Configuration(inMemoryIdentifier:)`).
- El historial guarda modalidad, equipos como snapshots, ganador/empate, narración y origen de la narración. No guarda suerte, feeling ni cálculos intermedios.
- El catálogo local guarda personajes descargados con datos suficientes para filtros y detalle; el seed inicial usa datos reales de la API.
- Ten en cuenta que RealmSwift 20.x es open source y ya no tiene soporte oficial de MongoDB; evita depender de APIs obsoletas de Device Sync.

## 9. Apple Foundation Models

- Disponible en iOS 26+. Protege el código con `@available(iOS 26, *)` cuando sea necesario.
- Comprueba `SystemLanguageModel.default.availability` antes de crear una sesión.
- Si el modelo no está disponible, usa una narrativa de fallback determinista y localizada.
- La IA nunca decide el ganador ni modifica puntuaciones; el resultado matemático es inmutable.
- Usa `@Generable` para salidas estructuradas y valida el resultado antes de mostrarlo.
- Mantén los prompts en un solo lugar y versionados.
- No envíes tokens, credenciales ni datos personales al modelo.
- Controla cancelación, timeouts y respuestas incompletas; la generación puede tardar.
- Registra el origen de la narración (`foundationModels` o `template`) y muéstralo en la UI. No simules que se usó IA cuando no fue posible.
- La narración se solicita en el idioma seleccionado por el usuario y no traduce nombres propios.
- Los tests no invocan el modelo real: usa un generador de narrativa falso.

## 10. Tests

- Usa XCTest en unit tests y UI tests.
- Los unit tests importan el módulo con `@testable import SuperHeroBattle`.
- Cubre casos de uso, mapeadores y repositorios con fakes.
- No uses `sleep`; espera con expectativas o `async` correctamente.
- No dependas de red, hora del sistema ni estado global compartido. Inyecta `TimeProvider` y RNG cuando corresponda.
- Prueba cancelación: una búsqueda cancelada no publica resultados y una respuesta antigua no sobrescribe una reciente.
- Prueba la caché con reloj falso: hit, expiración, normalización, aislamiento por query y actualización tras una respuesta correcta.
- Los UI tests deben ser pocos y estables: flujo principal de selección y combate, con fakes mediante argumentos de lanzamiento (`-uitest-fakes` activa `FixedRosterHeroRepository`, `FixedCharacterIDProvider` y catálogo en memoria, sin red ni token).
- Toda corrección de bug debe incluir un test que lo reproduzca.

## 11. Secretos y configuración

- `SuperHeroBattle/Config/Base.xcconfig` es versionado y no contiene secretos.
- `SuperHeroBattle/Config/Secrets.example.xcconfig` es la plantilla versionada.
- `SuperHeroBattle/Config/Secrets.xcconfig` es local, está en `.gitignore` y nunca se commitea.
- Para configurar el token:

  ```sh
  cp SuperHeroBattle/Config/Secrets.example.xcconfig SuperHeroBattle/Config/Secrets.xcconfig
  ```

- El token llega a la app mediante las claves `SuperHeroAPIToken` y `SuperHeroAPIBaseURL` del `Info.plist`.
- Los archivos `Config/*.xcconfig` están excluidos de Copy Bundle Resources; ninguno debe acabar dentro del `.app`.
- No imprimas el token ni lo muestres en pantalla.
- No añadas secretos a `AGENTS.md`, `opencode.json`, tests, fixtures ni capturas.

## 12. Proyecto Xcode

- El proyecto usa el formato JSON de Xcode 27 (`project.xcproj`).
- La carpeta `SuperHeroBattle/` es una *folder reference*: los archivos nuevos se incluyen automáticamente en el target app.
- `Resources/Info.plist` está excluido de Copy Bundle Resources porque se usa como `INFOPLIST_FILE`.
- No añadas archivos ajenos al código dentro de `SuperHeroBattle/` (por ejemplo `.gitkeep`), porque la folder reference los copia como recursos. Para preservar carpetas vacías usa la estructura documentada, no archivos placeholder.
- Los tests viven fuera de la carpeta de la app, en `Tests/UnitTests` y `Tests/UITests`.
- `scripts/`, `data/` y `.github/` viven fuera de `SuperHeroBattle/` y no forman parte del bundle salvo `data/character_ids.json`, que se añade como referencia de archivo explícita en `project.xcproj`.
- La documentación vive en `docs/`. No añadas `.md` ni texto plano dentro de `SuperHeroBattle/`.
- Los archivos de localización viven en `Resources/en.lproj` y `Resources/es.lproj`; el proyecto debe declarar `en` y `es` como localizaciones soportadas.
- `Config/Base.xcconfig`, `Config/Secrets.example.xcconfig` y `Config/Secrets.xcconfig` están excluidos de Copy Bundle Resources.
- Después de editar `project.xcproj`, valida con `xcodebuild -list` antes de commitear.
- `Package.resolved` se versiona. Las dependencias actuales son RealmSwift 20.x y Lottie 4.6.x.
- `docs/IMPLEMENTATION_STATUS.md` es el registro vivo de fases, decisiones y pendientes. Actualízalo al cerrar cada fase.

## 13. Git y commits

- Usa Conventional Commits: `feature(battle): add team selection`, `fix(api): validate status code`, `test(domain): cover battle scoring`.
- Commits pequeños y con un propósito claro.
- No commitees `xcuserdata`, `DerivedData`, `build`, `*.xcuserstate` ni `Secrets.xcconfig`.
- No reescribas historia compartida ni hagas force push sin permiso.
- Antes de commitear: compila, ejecuta tests y revisa `git diff`.

## 14. Localización, diseño y accesibilidad

- Usa `LocalizableStringKey` y `L10n` con `Localizable.strings` clásicos. No uses String Catalogs ni textos visibles embebidos en las vistas.
- Mantén paridad de claves entre `en` y `es`; añade un test que lo compruebe.
- El idioma seleccionado se aplica a la interfaz y a la narración. Los nombres propios no se traducen.
- El diseño sigue la estética comic book con colores intensos, viñetas y jerarquía clara, sin saturar.
- Usa `TeamPalette` para diferenciar Equipo A y Equipo B, pero no comuniques información solo con color.
- Lottie se encapsula en `Core/Lottie` y debe respetar Reduce Motion con un fallback estático.
- Toda pantalla debe funcionar con VoiceOver, Dynamic Type, contraste suficiente y áreas táctiles adecuadas.
- Las barras de PowerStats exponen siempre el valor numérico accesible; los desconocidos se anuncian como no disponibles.

## 15. Definition of Done

Una tarea está terminada cuando:

1. El proyecto compila sin errores ni warnings nuevos.
2. Los tests existentes pasan y la funcionalidad nueva tiene cobertura.
3. No hay secretos ni datos sensibles en el diff ni en el bundle.
4. La arquitectura y las convenciones de este documento se respetan.
5. `xcodebuild -list` sigue funcionando tras cambios en el proyecto.
6. `docs/IMPLEMENTATION_STATUS.md` refleja el estado real de la fase.
