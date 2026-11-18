PROMPT MAESTRO — SUPERHERO BATTLES.
Desarrollo de aplicación nativa iOS con SwiftUI, Clean Architecture y Apple Foundation Models
1. ROL Y OBJETIVO DEL PROYECTO
Actúa como un arquitecto senior de aplicaciones iOS y desarrollador experto en:
* Swift.
* SwiftUI.
* Clean Architecture.
* MVVM.
* Swift Concurrency (async/await).
* URLSession.
* Realm Swift.
* Lottie.
* Apple Foundation Models.
* XCTest.
* Accesibilidad e internacionalización en iOS.
Tu objetivo es diseñar e implementar una aplicación nativa para iOS llamada provisionalmente Superhero Battles.
La aplicación permitirá buscar superhéroes utilizando la API oficial SuperHeroAPI, consultar sus características, seleccionar personajes y enfrentarlos en combates simulados.
Los combates podrán ser:
* 1 vs 1.
* 2 vs 2.
* 3 vs 3.
El ganador se determinará mediante un motor matemático desarrollado en Swift, que tendrá en cuenta los PowerStats, la suerte y la afinidad entre compañeros de equipo.
Posteriormente, Apple Foundation Models utilizará la información de los personajes y el resultado matemático para generar una narración cinematográfica del enfrentamiento.
La aplicación debe tener una estética inspirada en los cómics de superhéroes, ser completamente funcional y contar con una arquitectura preparada para crecer.
No te limites a generar una demostración visual. Implementa la lógica de negocio, integración con APIs, persistencia, gestión de errores, pruebas y accesibilidad.

2. STACK TECNOLÓGICO Y REQUISITOS GENERALES
Utiliza las siguientes tecnologías:
Área    Tecnología
Lenguaje    Swift
Interfaz    SwiftUI
iOS mínimo    iOS 26
Arquitectura    Clean Architecture + MVVM
Concurrencia    Swift Concurrency
Networking    URLSession nativo
API    SuperHeroAPI oficial
Persistencia    Realm Swift
Animaciones    Lottie
Inteligencia artificial    Apple Foundation Models
Internacionalización    LocalizableStringKey clasico
Testing    XCTest
Requisitos generales:
* Utilizar APIs modernas de Swift compatibles con iOS 26.
* Utilizar async/await para las operaciones asíncronas.
* Evitar dependencias externas innecesarias.
* Utilizar inyección de dependencias.
* Mantener una separación clara de responsabilidades.
* Priorizar código mantenible, escalable y testeable.
* No introducir lógica de negocio en las vistas SwiftUI.
* No utilizar SDKs externos para realizar las llamadas HTTP.
* Todas las pantallas deben implementarse con SwiftUI.

3. ARQUITECTURA: CLEAN ARCHITECTURE
La aplicación debe seguir los principios de Clean Architecture y Clean Code.
Separar claramente el proyecto en tres capas principales:
3.1. Data
Responsable de acceder a fuentes de datos externas e internas.
Incluye:
* Networking.
* Servicios de API.
* DTO.
* Decodificación JSON.
* Implementaciones de repositorios.
* Caché en memoria.
* Acceso a Realm.
* Mapeadores entre DTO y modelos de dominio.
Esta capa implementará los protocolos definidos en Domain.
3.2. Domain
Contiene la lógica de negocio independiente de frameworks externos.
Incluye:
* Entidades de dominio.
* Protocolos de repositorios.
* Casos de uso.
* Reglas de negocio.
* Motor de combate.
* Cálculos de puntuaciones.
* Lógica de feeling.
* Validaciones de selección.
Domain no debe depender de Data ni de Presentation.
3.3. Presentation
Responsable de la interfaz de usuario y de la gestión de estados.
Incluye:
* Vistas SwiftUI.
* ViewModels.
* Navegación.
* Estados de carga.
* Estados de error.
* Presentación de resultados.
Presentation debe utilizar los casos de uso de Domain y no acceder directamente a URLSession, Realm o DTO.
3.4. Estructura orientativa
Organiza el proyecto de manera similar a esta:
App/
* SuperheroBattlesApp
* AppContainer
Core/
* Networking
* Persistence
* Localization
* Extensions
* DesignSystem
Data/
* API/
* DTOs/
* Repositories/
* Cache/
* Mappers/
Domain/
* Models/
* Protocols/
* UseCases/
* CombatEngine/
Presentation/
* Home/
* Search/
* CharacterGuide/
* CharacterDetail/
* DuelMode/
* TeamSelection/
* Combat/
* History/
* Settings/
Resources/
* Assets
* Lottie
* Localizables
Tests/
* DomainTests
* DataTests
* PresentationTests
Puedes adaptar la estructura si existe una solución mejor, pero debes conservar la separación de responsabilidades.
Utiliza protocolos e inyección de dependencias mediante inicializadores.
Evita crear abstracciones innecesarias.

4. INTEGRACIÓN CON SUPERHEROAPI
Utilizaremos exclusivamente la API oficial:
https://superheroapi.com/
La autenticación se realizará mediante el token de acceso proporcionado por el servicio.
Las peticiones HTTP deben realizarse mediante URLSession y async/await.
No utilizar SDKs externos para las peticiones de red.
4.1. Información de los personajes
Implementar los servicios necesarios para obtener:
* Información general.
* PowerStats.
* Biography.
* Appearance.
* Work.
* Connections.
* Imagen del personaje.
Prestar especial atención a los siguientes campos:
Powerstats
* intelligence
* strength
* speed
* durability
* power
* combat
Todos los PowerStats tienen un rango de 0 a 100.
La API puede devolver valores desconocidos representados mediante "-".
Biography
* full-name
* alter-egos
* aliases
* place-of-birth
* first-appearance
* publisher
* alignment
Appearance
* gender
* race
* height
* weight
* eye-color
* hair-color
Work
* occupation
* base
Connections
* group-affiliation
* relatives
Los campos group-affiliation y relatives deben tratarse como listas de elementos independientes cuando estén separados por comas.
Normalizar los valores:
* Eliminar espacios sobrantes.
* Comparar sin distinguir mayúsculas y minúsculas.
* Evitar coincidencias parciales.
* Gestionar valores vacíos y desconocidos.
4.2. Modelo de datos
Crear DTO independientes de los modelos de dominio.
Los datos de la API no deben utilizarse directamente en la interfaz ni en el motor de combate.
Implementar mapeadores que conviertan las respuestas de la API en entidades de dominio tipadas.
Los PowerStats deben poder representar correctamente valores desconocidos sin perder información.
4.3. Gestión de red
Implementar:
* Gestión de errores HTTP.
* Errores de decodificación.
* Errores de conexión.
* Estados de carga.
* Cancelación de peticiones.
* Caché de imágenes.
* Reutilización de datos.
* Prevención de peticiones duplicadas.
* Gestión de respuestas incompletas.
No presupongas que todos los personajes contienen todos los campos.
No inventes endpoints ni funcionalidades que no estén disponibles en la API oficial.

5. REQUISITOS FUNCIONALES DE BÚSQUEDA
5.1. Pantalla inicial de búsqueda
La primera pantalla funcional debe permitir buscar superhéroes utilizando la API oficial.
Debe incluir:
* Campo de texto para introducir el nombre del superhéroe.
* Acción para iniciar la búsqueda.
* Indicador de carga.
* Listado de resultados.
* Estados vacíos.
* Gestión de errores.
* Posibilidad de realizar nuevas búsquedas.
Los resultados deben mostrarse mediante una lista SwiftUI.
Cada elemento debe mostrar como mínimo:
* Imagen del personaje.
* Nombre.
* Editorial, cuando esté disponible.
La búsqueda debe realizarse contra el endpoint oficial de búsqueda por nombre.
No presentar resultados ficticios como si procedieran de la API.
5.2. Cancelación de búsquedas
La lógica de búsqueda debe implementar cancelación real de tareas asíncronas.
Si el usuario inicia una nueva búsqueda antes de que finalice la anterior:
1. Cancelar la tarea anterior.
2. Propagar la cancelación hasta URLSession.
3. Evitar que los resultados anteriores se publiquen en la interfaz.
4. Mostrar exclusivamente los resultados de la búsqueda más reciente.
También se debe contemplar:
* Cancelación al limpiar el campo de búsqueda.
* Cancelación al desaparecer la vista, cuando corresponda.
* Evitar tareas concurrentes innecesarias.
* Gestionar CancellationError correctamente.
* No mostrar errores cuando una cancelación sea intencionada.
La cancelación debe propagarse desde Presentation hasta Data.
Es obligatorio evitar condiciones de carrera.
Incluso si una petición anterior termina después de haber sido cancelada, nunca podrá sobrescribir los resultados de una búsqueda más reciente.
Utiliza mecanismos de concurrencia seguros, como aislamiento mediante actores cuando corresponda, y control de identidad de las búsquedas.
5.3. Caché de búsquedas
Implementar una caché en memoria para almacenar resultados de búsqueda.
La caché debe funcionar por query.
Cada consulta tendrá su propia entrada.
Tiempo de vida configurable:
* Mínimo: 2 minutos.
* Máximo: 5 minutos.
* Valor inicial recomendado: 3 minutos.
Comportamiento obligatorio:
1. Normalizar la query.
2. Comprobar si existe una entrada válida.
3. Si existe y no ha expirado, devolver los resultados almacenados sin realizar una petición de red.
4. Si no existe o ha expirado, consultar la API.
5. Si la petición finaliza correctamente, actualizar la caché.
6. Si la petición falla, no almacenar resultados incorrectos.
La normalización debe evitar entradas duplicadas por diferencias irrelevantes de mayúsculas, minúsculas o espacios.
La caché debe ser independiente de la interfaz.
No debe devolver resultados de consultas diferentes.
La caché en memoria es suficiente. No es obligatorio persistirla en disco.
Implementar una abstracción para facilitar su sustitución futura.
Utilizar un reloj inyectable o una abstracción temporal para permitir pruebas deterministas de expiración.

6. GUÍA Y CATÁLOGO DE PERSONAJES
La aplicación debe disponer de una guía de personajes que permita consultar los superhéroes disponibles.
La búsqueda principal debe utilizar el endpoint oficial de búsqueda por nombre.
También se debe implementar un catálogo local de personajes descargados para facilitar búsquedas y filtros adicionales.
No presuponer que la API dispone de endpoints específicos para filtrar por editorial o género.
Los filtros adicionales se realizarán localmente sobre los datos disponibles.
6.1. Buscador y filtros
Permitir buscar por:
* Nombre.
* Alias.
Implementar filtros combinables por:
* Editorial.
* Género.
La búsqueda debe ser insensible a mayúsculas y minúsculas.
6.2. Presentación de resultados
Cada tarjeta debe mostrar:
* Imagen.
* Nombre.
* Nombre real.
* Editorial.
* Género.
* Alineamiento.
6.3. Detalle del personaje
Al seleccionar un personaje se abrirá una pantalla de detalle.
Mostrar:
* Imagen.
* Nombre.
* Nombre real.
* Alias.
* Editorial.
* Género.
* Raza.
* Alineamiento.
* Biografía.
* Ocupación.
* Lugar de nacimiento.
* Primera aparición.
* PowerStats.
* Afiliaciones.
* Familiares.
Los PowerStats deben mostrarse mediante barras de progreso con un rango de 0 a 100.
Los valores desconocidos deben representarse como no disponibles, sin convertirlos en cero.

7. PANTALLA PRINCIPAL
La pantalla principal debe presentar la identidad visual de la aplicación.
Debe incluir dos botones principales:
Guía de personajes
Navega al catálogo de superhéroes.
Duelos
Es la funcionalidad principal de la aplicación y debe tener mayor protagonismo visual.
Navega a la selección del modo de combate.
La pantalla debe utilizar una composición visual atractiva inspirada en los cómics.

8. SELECCIÓN DEL MODO DE COMBATE
La pantalla Duelos debe permitir seleccionar tres modalidades:
* 1 vs 1.
* 2 vs 2.
* 3 vs 3.
Cada modalidad debe presentarse como una tarjeta diferenciada.
Una vez elegido el modo, se navegará a la pantalla de selección de equipos.

9. SELECCIÓN DE EQUIPOS
La pantalla permitirá formar dos equipos:
* Equipo A.
* Equipo B.
El número de integrantes dependerá del modo elegido.
Cada hueco de selección debe permitir dos opciones:
1. Seleccionar manualmente un personaje desde el catálogo.
2. Seleccionar aleatoriamente un personaje mediante un botón.
La selección aleatoria debe rellenar únicamente el hueco solicitado.
Debe permitirse sustituir individualmente cualquier personaje sin reiniciar el equipo.
9.1. Restricciones
* No se pueden repetir personajes dentro de un mismo equipo.
* Sí se permite que un personaje aparezca en ambos equipos.
* Cada hueco debe tener estado vacío y ocupado.
* La selección aleatoria debe respetar las restricciones del equipo.
* La sustitución de un personaje no debe modificar los demás integrantes.
Los personajes seleccionados deben visualizarse en tarjetas con imagen y nombre.
Debe existir un botón para iniciar el combate.
Solo estará habilitado cuando ambos equipos estén completos.

10. MOTOR MATEMÁTICO DE COMBATE
Esta es una de las partes más importantes de la aplicación.
La determinación del ganador debe realizarse exclusivamente mediante código Swift.
Foundation Models nunca decidirá el ganador ni modificará las puntuaciones.
10.1. Puntuación individual: PowerStats
Cada personaje dispone de seis estadísticas:
* Intelligence.
* Strength.
* Speed.
* Durability.
* Power.
* Combat.
Cada una tiene un rango de 0 a 100.
La puntuación base se calcula mediante la media aritmética de los valores conocidos.
Fórmula:
Puntuación base = suma de PowerStats conocidos / número de PowerStats conocidos.
Los valores desconocidos, nulos o representados por "-" deben excluirse de la media.
No deben contabilizarse como cero.
Si todas las estadísticas son desconocidas, la puntuación base será cero.
10.2. Suerte
Cada personaje recibe una bonificación aleatoria individual.
Rango:
* Mínimo: 7 puntos.
* Máximo: 77 puntos.
La generación debe realizarse independientemente para cada personaje.
La suerte se suma a la puntuación base.
Cada personaje debe tener su propia tirada aleatoria.
El motor debe permitir inyectar una fuente de aleatoriedad controlada para facilitar las pruebas unitarias.
10.3. Feeling entre compañeros
El feeling representa la afinidad entre personajes que forman parte del mismo equipo.
Se calcula comparando cada pareja de personajes del equipo.
Para cada pareja:
* Comparar group-affiliation.
* Comparar relatives.
Si existe al menos una coincidencia en cualquiera de los dos campos, la pareja recibe 33 puntos adicionales.
La condición es OR, no AND.
Reglas:
* Coincidencia de afiliación: +33.
* Coincidencia familiar: +33.
* Coincidencia de afiliación y familiar simultáneamente: +33.
* Ausencia de coincidencias: 0.
Nunca se suman 66 puntos por una misma pareja.
Las comparaciones deben realizarse entre los elementos individuales de las listas, normalizados y sin distinguir mayúsculas y minúsculas.
No deben producirse coincidencias parciales accidentales.
El feeling solo se calcula entre personajes del mismo equipo.
No se compara el feeling entre integrantes de equipos contrarios.
En un equipo de dos personajes existe una pareja posible.
En un equipo de tres personajes existen tres parejas posibles.
Cada pareja puede aportar un máximo de 33 puntos.
10.4. Puntuación individual final
Puntuación individual = puntuación base + suerte.
10.5. Puntuación total del equipo
La puntuación del equipo será la suma de las puntuaciones individuales de todos sus integrantes más el feeling total.
Fórmula:
Puntuación total = suma de puntuaciones individuales + suma del feeling de todas las parejas.
Ejemplo conceptual:
Equipo A:
* Personaje 1: base 70 + suerte 40.
* Personaje 2: base 85 + suerte 25.
* Personaje 3: base 90 + suerte 50.
* Feeling entre parejas: 66.
Total:
70 + 40 + 85 + 25 + 90 + 50 + 66 = 426 puntos.
Equipo B:
Calcular siguiendo exactamente el mismo procedimiento.
El equipo con mayor puntuación total será el ganador.
En caso de empate, declarar empate.
No modificar aleatoriamente el resultado después del cálculo.
10.6. Trazabilidad del combate
El motor debe generar un resultado estructurado que contenga:
* Puntuación base de cada personaje.
* Suerte de cada personaje.
* Puntuación individual final.
* Coincidencias de feeling encontradas.
* Bonificación de feeling de cada pareja.
* Puntuación total de cada equipo.
* Ganador o empate.
Esta información alimentará la presentación de resultados y Foundation Models.
Implementar el motor como un componente independiente y testeable.

11. INTELIGENCIA ARTIFICIAL: APPLE FOUNDATION MODELS
Utilizar Apple Foundation Models para generar una narración cinematográfica de cada combate.
El modelo recibirá:
* Información de los personajes.
* Nombre y alias.
* Biografía.
* PowerStats.
* Habilidades relevantes.
* Equipos participantes.
* Resultado matemático.
* Ganador.
* Diferencias de puntuación.
Foundation Models utilizará estos datos para crear una narración original.
11.1. Estilo narrativo
El tono debe ser cinematográfico, espectacular y entretenido, inspirado en las narraciones de cómics de superhéroes.
La narración debe incluir:
1. Presentación de ambos equipos.
2. Inicio del enfrentamiento.
3. Momentos estelares.
4. Ataques especiales.
5. Estrategias.
6. Interacciones entre personajes.
7. Desenlace.
8. Proclamación del ganador.
Ejemplos orientativos:
"Batman aprovecha la oscuridad para lanzar un batarang impregnado de compuestos químicos."
"Joker anticipa el movimiento de su rival y activa una bomba de humo que transforma el campo de batalla."
"Superman recibe el impacto, pero su resistencia le permite contraatacar con una fuerza devastadora."
Estos ejemplos son referencias de estilo, no textos fijos.
La IA debe tener libertad creativa para construir enfrentamientos entretenidos, respetando la información disponible de los personajes.
11.2. Restricciones de Foundation Models
* La IA no puede modificar el ganador.
* La IA no puede alterar las puntuaciones.
* La IA no debe inventar PowerStats.
* La IA debe respetar las características conocidas.
* Puede desarrollar una narración creativa basada en las habilidades y biografías disponibles.
* Debe reconocer que se trata de una simulación ficticia.
La narración debe generarse en el idioma seleccionado por el usuario.
11.3. Arquitectura de Foundation Models
Crear un protocolo:
CombatNarrationService
Implementaciones:
* FoundationModelsNarrationService
* MockNarrationService
El servicio real utilizará Apple Foundation Models.
El servicio alternativo se utilizará para desarrollo, testing y situaciones en las que Foundation Models no esté disponible.
Comprobar la disponibilidad del modelo antes de iniciar la generación.
Gestionar:
* Disponibilidad.
* Generación.
* Cancelación.
* Errores.
* Tiempo de espera.
* Respuestas incompletas.
No bloquear la interfaz mientras se genera la narración.
No simular que la IA se ha ejecutado cuando no ha sido posible utilizar el modelo real.
Mantener siempre separadas la resolución matemática y la generación narrativa.

12. PANTALLA DE COMBATE Y RESULTADOS
Una vez seleccionados los equipos, mostrar una pantalla de combate.
Debe tener una presentación visual de enfrentamiento:
* Equipo A frente a Equipo B.
* Personajes de ambos equipos.
* Presentación visual tipo cómic.
* Animación de inicio mediante Lottie.
* Indicador de generación de narración.
Una vez completada la simulación, mostrar:
* Ganador.
* Puntuación de ambos equipos.
* Puntuación individual de cada personaje.
* Bonificación de suerte.
* Feeling obtenido.
* Narración cinematográfica.
La narración debe mostrarse como texto, con una presentación visual atractiva y lectura cómoda.
Se pueden utilizar animaciones Lottie para:
* Inicio del combate.
* Transiciones.
* Presentación del ganador.
* Celebración del equipo vencedor.
No es necesario implementar un combate gráfico en tiempo real.
El combate es una simulación narrativa textual.

13. HISTORIAL DE COMBATES Y REALM
Implementar persistencia local utilizando Realm Swift.
El historial debe guardar exclusivamente los siguientes datos:
* Modalidad del combate.
* Equipo A.
* Equipo B.
* Ganador.
* Narración generada.
Los datos de los personajes deben guardarse como snapshots suficientes para reconstruir el detalle de un combate aunque la API cambie o el personaje deje de estar disponible.
No es necesario conservar en el historial:
* Estadísticas intermedias.
* Tiradas de suerte.
* Cálculos de feeling.
* Resultados parciales.
La persistencia debe estar aislada detrás de un repositorio.
Implementar:
* Consulta del historial.
* Detalle de un combate anterior.
* Visualización de equipos.
* Lectura de la narración.
* Eliminación de registros individuales.
No se necesita sincronización en la nube.

14. DISEÑO VISUAL: COMIC BOOK
La identidad visual debe inspirarse en los cómics de superhéroes.
Características:
* Colores intensos.
* Contrastes marcados.
* Tipografías contundentes y legibles.
* Tarjetas con estética de viñeta.
* Bordes y separadores inspirados en cómics.
* Elementos gráficos de explosiones, rayos y onomatopeyas.
* Transiciones y animaciones controladas.
El diseño debe resultar moderno y atractivo, no infantil.
Debe transmitir una sensación de videojuego de enfrentamientos de superhéroes.
Evita saturar las pantallas con efectos visuales.
Mantén una jerarquía visual clara y una navegación intuitiva.
Utiliza colores diferenciados para Equipo A y Equipo B.

15. INTERNACIONALIZACIÓN
La aplicación debe soportar:
* Español.
* Inglés.
Utilizar:
* No usar String Catalogs de Xcode. Usar localizables clásicos
* LocalizableStringKey.
* Herramientas de localización de SwiftUI.
No escribir textos visibles directamente en las vistas.
Todos los textos deben estar externalizados:
* Botones.
* Títulos.
* Mensajes de error.
* Estados de carga.
* Etiquetas.
* Filtros.
* Resultados.
* Historial.
* Mensajes de accesibilidad.
La narración de Foundation Models debe solicitarse en el idioma seleccionado por el usuario.
No traducir nombres propios de personajes, grupos o editoriales.

16. ACCESIBILIDAD
La aplicación debe cumplir las buenas prácticas de accesibilidad de Apple.
Implementar:
* Compatibilidad con VoiceOver.
* Etiquetas y descripciones accesibles.
* Dynamic Type.
* Contraste suficiente.
* Elementos táctiles con tamaños adecuados.
* Orden lógico de lectura.
* Estados accesibles de botones.
* Indicadores de progreso accesibles.
* Alternativas textuales a elementos visuales relevantes.
* Respeto por Reduce Motion.
* No depender exclusivamente del color para comunicar información.
Las barras de PowerStats deben ofrecer su valor numérico accesible.
Las animaciones Lottie deben poder reducirse o desactivarse cuando corresponda.

17. ANIMACIONES LOTTIE
Utilizar Lottie para aportar dinamismo.
Posibles usos:
* Animación de entrada de la pantalla principal.
* Transición a la selección de equipos.
* Presentación del enfrentamiento.
* Inicio de la simulación.
* Celebración del equipo ganador.
* Estados de carga.
Encapsular la integración de Lottie en componentes reutilizables compatibles con SwiftUI.
Evitar que las animaciones afecten al rendimiento o la accesibilidad.

18. SEGURIDAD Y CALIDAD
No introducir tokens de API directamente en el código fuente ni en el repositorio.
Utilizar una configuración externa para desarrollo y contemplar las limitaciones de protección de secretos en aplicaciones cliente.
Implementar:
* Gestión centralizada de errores.
* Logging sin información sensible.
* Validación de datos procedentes de la API.
* Prevención de estados inconsistentes.
* Gestión de concurrencia segura.
* Control de tareas asíncronas.
* Cancelación de tareas cuando corresponda.
No forzar valores que no estén presentes en la API.
No suponer que todos los personajes tienen información completa.
Comprobar la compatibilidad de las versiones actuales de Realm Swift y Lottie con iOS 26 antes de incorporarlas al proyecto.

19. TESTING OBLIGATORIO
Implementar pruebas unitarias para las capas principales.
19.1. Tests de Domain
Utilizar repositorios mockeados.
Comprobar:
* Ejecución correcta de los casos de uso.
* Transformación de resultados.
* Gestión de resultados vacíos.
* Gestión de errores.
* Comportamiento ante cancelación cuando corresponda.
Motor de combate
Probar:
* Media de PowerStats.
* Exclusión de valores desconocidos.
* Personajes sin estadísticas.
* Generación de suerte entre 7 y 77.
* Coincidencias de afiliación.
* Coincidencias familiares.
* Coincidencias simultáneas de afiliación y familiares.
* Feeling de equipos de dos y tres integrantes.
* Suma de puntuaciones.
* Empates.
* Ausencia de feeling entre equipos contrarios.
19.2. Tests de Data
Comprobar:
* Primera búsqueda mediante red.
* Segunda búsqueda utilizando caché.
* Ausencia de llamadas de red cuando existe una entrada válida.
* Expiración de la caché.
* Nueva llamada de red después de expirar.
* Actualización de la caché después de una petición correcta.
* Aislamiento de consultas diferentes.
* Normalización de queries.
* Decodificación de respuestas.
* Valores desconocidos.
* Errores HTTP.
* Respuestas incompletas.
19.3. Tests de cancelación
Comprobar:
* Que una búsqueda cancelada no publica resultados.
* Que una búsqueda nueva tiene prioridad sobre la anterior.
* Que la cancelación se propaga hasta networking.
* Que una respuesta antigua nunca sobrescribe una respuesta reciente.
19.4. Tests de Presentation
Aunque son opcionales, se valoran especialmente.
Comprobar:
* Estados de carga.
* Resultados.
* Errores.
* Cancelación.
* Navegación al detalle.
19.5. Tests de persistencia
Comprobar:
* Guardado.
* Recuperación.
* Eliminación.
* Reconstrucción del detalle de un combate.
19.6. Tests de Foundation Models
Comprobar:
* Disponibilidad.
* Generación.
* Errores.
* Cancelación.
* Uso del servicio alternativo.
Utilizar dobles de prueba para no depender de la disponibilidad real de Apple Intelligence.

20. CASOS DE USO PRINCIPALES
Mantener los casos de uso independientes y con una responsabilidad clara.
Como mínimo, implementar:
* SearchHeroesUseCase: búsqueda de personajes.
* GetHeroDetailUseCase: recuperación de información del personaje.
* GetHeroesCatalogUseCase: acceso al catálogo local.
* FilterHeroesUseCase: filtrado local por editorial y género.
* SelectHeroUseCase: selección y validación de personajes.
* GenerateRandomHeroUseCase: selección aleatoria individual.
* CalculateCombatUseCase: resolución matemática.
* GenerateCombatNarrationUseCase: generación narrativa.
* SaveCombatHistoryUseCase: almacenamiento de combates.
* GetCombatHistoryUseCase: consulta del historial.
* DeleteCombatHistoryUseCase: eliminación de registros.
Puedes adaptar los nombres, pero debes conservar la separación de responsabilidades.

21. COMPATIBILIDAD CON FOUNDATION MODELS Y SIMULADORES
La aplicación tiene como requisito mínimo iOS 26 para poder integrar Apple Foundation Models.
No obstante, no debes asumir que el modelo estará disponible en todos los dispositivos o simuladores.
Implementar comprobaciones de disponibilidad mediante las APIs oficiales de Foundation Models.
Para desarrollo:
* Utilizar Xcode 26 o posterior.
* Utilizar macOS compatible.
* Utilizar simuladores con iOS 26 o posterior.
* Comprobar la disponibilidad real del modelo.
* Mantener MockNarrationService para entornos sin acceso al modelo.
El funcionamiento de toda la aplicación debe poder probarse sin depender de Apple Intelligence.
Las pruebas finales de rendimiento y generación deben realizarse también en dispositivos físicos compatibles.

22. METODOLOGÍA DE DESARROLLO POR FASES
No intentes generar toda la aplicación de una sola vez.
Trabaja por fases y mantén el proyecto compilable al finalizar cada una.
Antes de implementar cada fase:
1. Explica brevemente qué vas a construir.
2. Indica los archivos que crearás o modificarás.
3. Explica las decisiones arquitectónicas importantes.
4. Implementa el código completo.
5. Comprueba las dependencias y compatibilidad con iOS 26.
6. Indica cómo probar lo implementado.
Fase 1: Arquitectura
* Crear el proyecto.
* Configurar arquitectura.
* Crear modelos de dominio.
* Definir protocolos.
* Configurar dependencias.
* Configurar navegación inicial.
Fase 2: API y búsqueda
* Implementar networking.
* Crear DTO.
* Crear repositorios.
* Implementar búsqueda.
* Implementar cancelación real.
* Implementar caché TTL.
* Crear tests de Data y Domain.
Fase 3: Catálogo de personajes
* Implementar catálogo local.
* Buscador.
* Filtros.
* Detalle del personaje.
* Caché de imágenes.
Fase 4: Selección de equipos
* Selector de modalidad.
* Selección manual.
* Selección aleatoria.
* Sustitución individual.
* Validaciones de personajes duplicados.
Fase 5: Motor de combate
* PowerStats.
* Suerte.
* Feeling.
* Puntuaciones.
* Ganador.
* Tests unitarios completos.
Fase 6: Foundation Models
* Integración del framework.
* Generación narrativa.
* Comprobación de disponibilidad.
* Servicio alternativo.
* Gestión de errores y cancelación.
* Tests.
Fase 7: Resultados e historial
* Pantalla de combate.
* Resultados.
* Integración de Realm.
* Consulta de historial.
* Eliminación de registros.
Fase 8: Diseño y accesibilidad
* Diseño Comic Book.
* Animaciones Lottie.
* Internacionalización.
* VoiceOver.
* Dynamic Type.
* Reduce Motion.
Fase 9: Calidad final
* Pruebas integrales.
* Optimización.
* Gestión de errores.
* Revisión de arquitectura.
* Documentación.
* Verificación de criterios de aceptación.
No avances a la siguiente fase hasta presentar el resultado de la actual y sus decisiones técnicas.

23. CRITERIOS FINALES DE ACEPTACIÓN
La aplicación se considerará correctamente implementada cuando cumpla todos los siguientes requisitos:
Búsqueda y API
* La búsqueda funciona contra SuperHeroAPI oficial.
* Los resultados se muestran mediante SwiftUI.
* Se puede acceder al detalle de cada personaje.
* Las búsquedas anteriores se cancelan al iniciar una nueva.
* Los resultados antiguos nunca sobrescriben los nuevos.
* La caché evita peticiones de red innecesarias.
* La caché expira correctamente.
* Los filtros locales funcionan por editorial y género.
Selección y combate
* Se pueden realizar combates 1 vs 1, 2 vs 2 y 3 vs 3.
* Se permite selección manual y aleatoria.
* Se permite sustituir personajes individualmente.
* No se repiten personajes dentro del mismo equipo.
* Se permite repetir personajes entre equipos.
* El motor matemático respeta todas las reglas definidas.
* El feeling utiliza correctamente la condición OR.
* La suerte se calcula individualmente entre 7 y 77.
* El ganador se determina exclusivamente mediante Swift.
Inteligencia artificial
* Foundation Models genera narraciones cinematográficas.
* La IA respeta el ganador matemático.
* La IA no altera las puntuaciones.
* Se gestiona la falta de disponibilidad del modelo.
* Existe un servicio alternativo para desarrollo y testing.
Persistencia
* El historial se guarda en Realm.
* Se conservan modalidad, equipos, ganador y narración.
* Se pueden consultar y eliminar combates anteriores.
* Los snapshots permiten reconstruir los detalles sin depender de la API.
Arquitectura y calidad
* Existe separación Data, Domain y Presentation.
* Se aplican principios de Clean Architecture y Clean Code.
* Todas las pantallas están implementadas en SwiftUI.
* Se utiliza async/await.
* Existe cancelación real de tareas.
* Existe caché con expiración.
* Se incluyen pruebas unitarias.
* El código es mantenible y escalable.
Experiencia de usuario
* Diseño Comic Book.
* Español e inglés.
* Accesibilidad.
* VoiceOver.
* Dynamic Type.
* Reduce Motion.
* Animaciones Lottie.

24. INSTRUCCIÓN FINAL
Actúa como responsable técnico del proyecto.
No tomes decisiones importantes que contradigan estos requisitos.
Si detectas incompatibilidades técnicas, limitaciones de Apple Foundation Models, problemas con SuperHeroAPI o incompatibilidades de dependencias, explícalas antes de implementar una solución alternativa.
No inventes métodos ni APIs de Apple, Realm, Lottie o SuperHeroAPI.
Consulta documentación oficial cuando sea necesario.
No generes pseudocódigo cuando se solicite una implementación real.
No omitas archivos necesarios para compilar el proyecto.
Prioriza código tipado, mantenible, testeable y preparado para crecer.
Mantén la aplicación compilable al finalizar cada fase.
Comienza por la Fase 1: arquitectura y estructura inicial del proyecto.
Presenta primero la propuesta arquitectónica, estructura de carpetas, modelos iniciales, protocolos y configuración de dependencias. Espera la validación de esta fase antes de continuar con la siguiente.
El objetivo final es construir una aplicación iOS nativa, funcional y de calidad profesional, no simplemente una maqueta visual.
