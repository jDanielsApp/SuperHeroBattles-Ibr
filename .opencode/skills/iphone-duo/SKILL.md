---
name: iPhone Duo
description: Desarrollo orientado a iPhone Duo para SuperHeroBattle — layouts por size class, poses del dispositivo, split views, reserved regions y verificación en simulador. Úsala para cualquier tarea que cree o modifique vistas, layouts o navegación que deba adaptarse a iPhone Duo (dual display, split view, size classes, pantalla interior/exterior).
---

# Desarrollo orientado a iPhone Duo

Guía de trabajo para adaptar SuperHeroBattle al iPhone Duo sin releer la
documentación de Apple en cada tarea. La fuente oficial destilada vive en
`references/hig-duo-guidelines.md` (léela la primera vez que toques una
pantalla de este listado o cuando dudes de una regla).

Fuente oficial (por si Apple la actualiza, publicada sept. 2026):
<https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>

## Cuándo usar esta skill

- Crear o modificar vistas, layouts o navegación de `SuperHeroBattle/Presentation`.
- Cualquier tarea de diseño/adaptación marcada como "iPhone Duo".
- Decidir cómo repartir contenido entre pantallas o columnas.

## Reglas de oro

1. **Adapta por size classes, nunca por dispositivo.** Compact = pantalla
   exterior (dispositivo cerrado) y Split View; regular = pantalla interior
   abierta. Usa `@Environment(\.horizontalSizeClass)`.
2. **Sin anchos fijos ni dependencias de pantalla concreta.** Márgenes de
   layout y safe areas siempre; los tamaños de elemento (iconos, slots) sí
   pueden ser fijos.
3. **Componentes estándar gratis.** Con `NavigationStack`, `.toolbar` y
   `TabView` el sistema coloca los controles en vertical y gestiona las
   reserved regions automáticamente. No sobrescribas barras ni posiciones.
4. **Sin cambios extremos al plegar.** Al pasar de compact a regular (o al
   plegar en libro) mueve solo lo necesario; los rediseños totales cuestan
   de seguir y localizar.
5. **Rejillas con número par de columnas** cuando el contenido se divida;
   si el número de items es impar, columna única con ancho legible acotado.
6. **Contenido crítico fuera de la zona de pliegue.** Lo decorativo
   (divisores, fondos) puede cruzarla; los datos y botones no.
7. **Misma funcionalidad en todas las poses.** Nada desaparece al abrir o
   cerrar; a lo sumo se reordena o muestra un nivel más de jerarquía.

## Mapa de decisiones del proyecto (pantalla a pantalla)

Decisiones ya acordadas con el usuario. Apícalas; si una pantalla no está
aquí, aplica "columna única con ancho legible acotado" en regular.

| Pantalla | Compact (cerrado) | Regular (Duo abierto) |
|---|---|---|
| TeamSelectionView | Columna actual con divisor "VS". | Equipo A y Equipo B lado a lado (split); CTA de inicio debajo a todo el ancho. |
| CombatView y CombatRecordDetailView | Columna actual (banners, equipo A, divisor, equipo B, narración, guardado). | Resto a la izquierda (banners, equipos, guardado) y narración a la derecha. |
| CharacterGuideView (ruta standalone desde Home) | Push actual de `HeroDetailView`. | `NavigationSplitView`: lista + ficha lado a lado (patrón Mail). |
| Hoja selectora de equipos (CharacterGuideView embebida) | Sin cambios: las filas eligen héroe, no navegan a detalle. | Igual, sin split. |
| HomeView, DuelModeView, HistoryView, SettingsView | Columna actual. | Columna única con ancho legible acotado (helper compartido). |

Helper compartido para el ancho legible: componente/módifier reutilizable
(≈640 pt centrado) — no lo dupliques por vista.

## APIs recomendadas

- `@Environment(\.horizontalSizeClass)` para elegir layout.
- `NavigationSplitView` para lista + detalle (colapsa sola a push en compact).
- `HStack`/`ZStack` adaptativos: la HIG los mapea a *arrangement views*
  (split/overlay) sin que escribamos contenedores custom.
- `ReservedRegion` (SwiftUI) solo si el sistema no aparta algo por sí solo.
- `ToolbarItemVisibilityPriority` para conservar acciones frecuentes cuando
  la barra comprime.

## Verificación obligatoria tras tocar layout

1. `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` y
   compila para el simulador.
2. Ejecuta la app en un simulador iPhone Duo y revisa las poses: cerrado,
   abierto en landscape, parcialmente plegado (libro) y de pie.
3. Comprueba safe areas en los bordes: la cámara exterior y los controles
   laterales no deben tapar contenido.
4. VoiceOver y Dynamic Type en la vista tocada.
5. Los UI tests deben seguir pasando en iPhone 17 (compact): el layout
   compacto no cambia identificadores ni acciones.
6. Al terminar: build + tests completos y `xcodebuild -list`.
