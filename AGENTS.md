# AGENTS.md — SuperHeroBattle

Este documento define cómo trabajar en el proyecto. Léelo antes de modificar código y respeta las reglas de arquitectura, seguridad y verificación.

## 1. Contexto del producto

SuperHeroBattle es una app iOS nativa que permite:

- Consultar superhéroes desde SuperHeroAPI.
- Formar equipos y simular combates.
- Generar narrativas de combate con Apple Foundation Models.
- Guardar el historial local de combates con Realm.

El código, los nombres de tipos, las ramas y los commits se escriben en inglés. La documentación y los comentarios técnicos se escriben en español. Los textos visibles para el usuario se escriben en inglés.

## 2. Stack y requisitos

- Swift 6 (modo de lenguaje estricto).
- SwiftUI con `@Observable` y `@MainActor` por defecto.
- iOS 26.0 como deployment target mínimo.
- Apple Foundation Models (`import FoundationModels`), disponible solo en iOS 26+ y dispositivos con Apple Intelligence.
- RealmSwift 20.x mediante SwiftPM (`https://github.com/realm/realm-swift.git`).
- SuperHeroAPI como backend HTTP.
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

No cambies `xcode-select` de forma global sin permiso del usuario.

## 4. Estructura del proyecto

```text
SuperHeroBattle/
├── App/                          # Punto de entrada y composición de la app
├── Core/                         # Utilidades compartidas, DI, extensiones
├── Domain/
│   ├── Entities/                 # Modelos de negocio puros
│   ├── Repositories/             # Protocolos de repositorio
│   └── UseCases/                 # Casos de uso
├── Data/
│   ├── Network/SuperHeroAPI/     # Cliente HTTP, DTOs y mapeadores
│   ├── Persistence/Realm/        # Modelos Realm y acceso a datos
│   ├── FoundationModels/         # Narrativa con Apple Foundation Models
│   └── Repositories/             # Implementaciones de los protocolos
├── Presentation/
│   ├── Features/Heroes/          # Pantallas y view models de héroes
│   ├── Features/Battle/          # Selección de equipos y combate
│   ├── Features/History/         # Historial local
│   └── Components/               # Vistas reutilizables
├── Resources/Assets.xcassets
└── Config/                       # xcconfig y secretos locales
Tests/
├── UnitTests/
└── UITests/
```

Reglas de ubicación:

- Un tipo principal por archivo.
- Los DTOs y mapeadores viven en `Data/Network`.
- Los modelos de Realm viven en `Data/Persistence/Realm`.
- Las implementaciones de repositorios viven en `Data/Repositories`.
- Las vistas no acceden directamente a red ni a Realm.

## 5. Arquitectura

Regla de dependencias:

```text
Presentation → Domain ← Data
```

- `Domain` no importa SwiftUI, Realm ni FoundationModels. Solo Foundation y Swift estándar.
- `Domain` define entidades, protocolos de repositorio y casos de uso.
- `Data` implementa esos protocolos y traduce entre DTOs/Realm y entidades de dominio.
- `Presentation` depende de casos de uso y protocolos, nunca de implementaciones concretas.
- La composición de dependencias se hace en `App` o en un contenedor de `Core`.

Inyección de dependencias:

- Usa protocolos para repositorios y servicios.
- Pasa dependencias por inicializador.
- No uses singletons globales salvo que sea imprescindible; si lo haces, documéntalo.
- Los tests deben poder sustituir cualquier dependencia externa por un fake.

## 6. Convenciones Swift y SwiftUI

- Swift 6 con concurrencia estricta y aislamiento `MainActor` por defecto.
- Usa `async/await`; no uses callbacks ni `DispatchQueue` salvo interoperabilidad justificada.
- Prohíbe `try!`, `as!` y force unwraps en código de producción.
- Usa `guard` para salidas tempranas y errores tipados.
- Los view models son `@Observable` y `@MainActor`.
- Las vistas son pequeñas; extrae subvistas a `Presentation/Components`.
- No pongas lógica de negocio en las vistas.
- Usa `@State` para estado local, `@Bindable` para view models observables y `@Environment` para dependencias compartidas.
- Respeta el Dynamic Type, VoiceOver y los tamaños de pantalla.
- No introduzcas dependencias nuevas sin justificarlo y actualizar este documento.

## 7. Red y SuperHeroAPI

- Usa `URLSession` con `async/await`.
- Centraliza la URL base y el token en `Bundle` (`SuperHeroAPIBaseURL` y `SuperHeroAPIToken`).
- No hardcodees el token ni lo incluyas en logs, errores, prompts o tests.
- Separa DTOs (`Codable`) de entidades de dominio.
- Valida el código de estado HTTP antes de decodificar.
- Propaga errores tipados y añade contexto sin filtrar secretos.
- Cancela tareas cuando la vista desaparezca.
- Los tests no deben hacer peticiones reales: usa `URLProtocol` o un cliente HTTP falso.

## 8. Persistencia con Realm

- Usa `RealmSwift` y mantén los modelos en `Data/Persistence/Realm`.
- Nunca expongas clases `Object` ni objetos gestionados a `Domain` o `Presentation`.
- Mapea siempre entre modelos Realm y entidades de dominio.
- Realm está confinado a su actor/hilo: no pases objetos gestionados entre actores.
- Marca los repositorios de persistencia como `@MainActor` mientras no haya una razón medida para lo contrario.
- Si necesitas leer en segundo plano, usa `freeze()` o una `Realm` creada en ese contexto y devuelve valores inmutables.
- Gestiona migraciones en un único punto y documenta cada cambio de esquema.
- En tests usa una configuración in-memory (`Realm.Configuration(inMemoryIdentifier:)`).
- Ten en cuenta que RealmSwift 20.x es open source y ya no tiene soporte oficial de MongoDB; evita depender de APIs obsoletas de Device Sync.

## 9. Apple Foundation Models

- Disponible en iOS 26+. Protege el código con `@available(iOS 26, *)` cuando sea necesario.
- Comprueba `SystemLanguageModel.default.availability` antes de crear una sesión.
- Si el modelo no está disponible, usa una narrativa de fallback determinista.
- Usa `@Generable` para salidas estructuradas y valida el resultado antes de mostrarlo.
- Mantén los prompts en un solo lugar y versionados.
- No envíes tokens, credenciales ni datos personales al modelo.
- Controla cancelación y timeouts; la generación puede tardar.
- Los tests no invocan el modelo real: usa un generador de narrativa falso.

## 10. Tests

- Usa XCTest en unit tests y UI tests.
- Los unit tests importan el módulo con `@testable import SuperHeroBattle`.
- Cubre casos de uso, mapeadores y repositorios con fakes.
- No uses `sleep`; espera con expectativas o `async` correctamente.
- No dependas de red, hora del sistema ni estado global compartido.
- Los UI tests deben ser pocos y estables: flujo principal de selección y combate.
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
- No imprimas el token ni lo muestres en pantalla.
- No añadas secretos a `AGENTS.md`, `opencode.json`, tests, fixtures ni capturas.

## 12. Proyecto Xcode

- El proyecto usa el formato JSON de Xcode 27 (`project.xcproj`).
- La carpeta `SuperHeroBattle/` es una *folder reference*: los archivos nuevos se incluyen automáticamente en el target app.
- `Resources/Info.plist` está excluido de Copy Bundle Resources porque se usa como `INFOPLIST_FILE`.
- No añadas archivos ajenos al código dentro de `SuperHeroBattle/` (por ejemplo `.gitkeep`), porque la folder reference los copia como recursos. Para preservar carpetas vacías usa la estructura documentada, no archivos placeholder.
- Los tests viven fuera de la carpeta de la app, en `Tests/UnitTests` y `Tests/UITests`.
- Después de editar `project.xcproj`, valida con `xcodebuild -list` antes de commitear.
- `Package.resolved` se versiona.

## 13. Git y commits

- Usa Conventional Commits: `feature(battle): add team selection`, `fix(api): validate status code`, `test(domain): cover battle scoring`.
- Commits pequeños y con un propósito claro.
- No commitees `xcuserdata`, `DerivedData`, `build`, `*.xcuserstate` ni `Secrets.xcconfig`.
- No reescribas historia compartida ni hagas force push sin permiso.
- Antes de commitear: compila, ejecuta tests y revisa `git diff`.

## 14. Definition of Done

Una tarea está terminada cuando:

1. El proyecto compila sin errores ni warnings nuevos.
2. Los tests existentes pasan y la funcionalidad nueva tiene cobertura.
3. No hay secretos ni datos sensibles en el diff.
4. La arquitectura y las convenciones de este documento se respetan.
5. `xcodebuild -list` sigue funcionando tras cambios en el proyecto.
