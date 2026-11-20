# Guía HIG "Designing for iPhone Duo" — destilado

Destilado de la página oficial de Apple (publicada el 9 de septiembre de
2026): <https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo>.
Volver a ella solo si Apple publica cambios en el change log.

## Anatomía del dispositivo

- **Dos pantallas**, cada una con su cámara frontal. La **bisagra central**
  permite abrir, cerrar y posicionar el dispositivo de varias formas.
- **Pantalla exterior**: se usa con el dispositivo cerrado. Es más ancha y
  baja que un iPhone convencional; el sistema mueve toolbars y tab bars al
  lateral para maximizar el espacio vertical.
- **Pantalla interior**: se usa con el dispositivo abierto. En portrait tiene
  suficiente altura para mantener las barras horizontales estándar; en
  landscape los controles quedan en el lateral (igual que en la exterior)
  para mantener la continuidad.
- **Cámara exterior**: en la esquina, siempre visible, alineada
  verticalmente con los controles laterales. Se expande al Dynamic Island
  para Live Activities.
- **Cámara interior**: bajo la pantalla; invisible salvo cuando la cámara
  está activa (entonces la UI se aparta para indicar su presencia).

## Poses del dispositivo

Libro parcialmente plegado, apoyado en una superficie, de pie sobre sus
bordes… No se diseña una layout por pose: se usan **size classes** (compact
para la exterior, regular para la interior) y el layout se adapta solo.
"Preparar tu app para iPhone Duo" (Device Hub de Xcode) permite previsualizar
y probar las poses.

## Best practices

- **Construye para redimensionar.** Size classes, márgenes y safe areas.
  Sin anchos fijos ni dependencias de pantalla concreta. Split View
  multitarea añade todavía más tamaños posibles.
- **Experiencia consistente entre pantallas.** Misma funcionalidad y estado;
  misma jerarquía de información, mostrando en la interior un nivel
  adicional si tiene sentido (Mail: con el dispositivo cerrado muestra lista
  *o* correo; abierto muestra ambos lado a lado).
- **Misma funcionalidad en cada pose.** Los controles pueden desbordar y el
  contenido moverse, pero nada desaparece por sostener el dispositivo de otra
  forma.
- **Sigue el layout vertical del sistema** para toolbars, tab bars y
  navegación: lo dan gratis los componentes estándar. No lo sobrescribas salvo
  necesidad real.
- **Juegos**: pueden bloquear orientación, pero deben llenar la pantalla en
  cada pose; prefiere cambiar el aspect ratio antes que letterbox/pillarbox
  y, si no queda más remedio, decora el padding.

## Dynamic layouts

- Además de las safe areas estándar, el espacio disponible está moldeado por
  las **reserved regions**:
  - Cámara frontal exterior (siempre presente).
  - Cámara frontal interior (solo con la cámara activa).
  - **Folding region**: condicional; con el dispositivo parcialmente abierto
    divide la pantalla interior en regiones utilizables excluyendo el centro
    del pliegue.
- Muchos componentes del sistema se adaptan solos (alerts, context menus,
  sheets, split views ajustando anchos y márgenes). Para lo custom:
  `ReservedRegion` (SwiftUI) / `UIView.ReservedRegion` (UIKit).
- **Al plegar, ajusta el layout** con contenedores que se adapten solos
  (split views) o rejillas con **número par de columnas** para dividir
  limpio. `ReservedRegion` para apartar lo importante del centro si el
  sistema no lo mueve.
- **Evita cambios extremos al plegar**: mueve solo lo necesario; los
  controles que desaparecen o saltan son difíciles de seguir.

## Split views

Un split view se expande en la pantalla interior y colapsa a un único panel
en la exterior, igual que entre entornos regular y compacto en otros
iPhone. Con componentes estándar se adaptan solos a las reserved regions.
SwiftUI: `NavigationSplitView`. UIKit: `UISplitViewController`.

## Arrangement views

Contenedor con vista primaria y secundaria organizadas según tamaño,
orientación y reserved regions. Dos tipos:

- **Split**: divide su área entre primaria y secundaria. Horizontal si es
  más ancha que alta; vertical si es más alta que ancha.
- **Overlay**: apila primaria sobre secundaria. Con el dispositivo
  parcialmente plegado cada vista ocupa un lado; si no, la primaria queda
  encima.

Un layout que ya coloca dos vistas lado a lado (`HStack`) o apiladas
(`ZStack`) se traduce directamente en un arrangement. La navegación se
coloca *alrededor* del arrangement, nunca dentro.

## Vertical controls

- En la pantalla exterior (y en la interior en landscape) el Dynamic Island,
  status bar, toolbar y tab bar pasan al eje lateral. En Split View, cada
  app pone sus controles en su borde exterior.
- **Cuenta la asimetría**: los controles ocupan un borde y el contenido queda
  asimétrico; usa safe areas para que nada se tape (incluidos los controles
  del borde opuesto en Split View).
- **Posiciones estables entre poses** para no reaprender dónde vive cada
  acción.
- **Orden estándar de ítems**: arriba del eje vertical va la navegación
  primaria (Back/Close), luego acciones prominentes (Done); el resto en sus
  agrupaciones originales.
- **Prioriza los ítems frecuentes**: desbordan de abajo a arriba por defecto;
  asigna prioridad de visibilidad (`ToolbarItemVisibilityPriority`) por
  grupos y luego por ítem. Conserva primero acciones frecuentes y elementos
  con estado relevante (badges).
- **No sobrescribas la colocación por defecto**: es un patrón núcleo de la
  plataforma.
- **Ancho completo** solo para interfaces inmersivas sin scroll que no
  choquen con Dynamic Island ni status bar (Calculator); se puede combinar:
  fondo/cabecera a todo el ancho y contenido scrolleable con insets.
- **Agrupa ítems relacionados** (`ToolbarItemGroup`) en vez de espaciar a
  mano. Título + símbolo en cada ítem (el símbolo queda para el eje
  vertical, el título para overflow). Botones de texto, los mínimos.
- **Con espacio limitado**: conserva la toolbar (experiencias de tarea) o la
  tab bar (experiencias de navegación); usa el menú overflow del sistema y
  reserva el símbolo de elipsis para overflow.

## Documentación de developer

- TechnologyOverviews/preparing-your-app-for-iphone-duo
- SwiftUI: `ReservedRegion`, `ArrangementView`, `NavigationSplitView`,
  `ToolbarItemVisibilityPriority`, `ToolbarVerticalCompressionBehavior`.
- UIKit: `UIView.ReservedRegion`, `UIArrangementViewController`,
  `UIBarButtonItemVisibilityPriority`, `UIVerticalBarCompressionBehavior`.
