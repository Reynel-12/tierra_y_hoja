# Sistema de Diseño — App de Bitácora Agrícola (Flutter)

**Concepto visual: "Tierra & Hoja"**
Papel de cuaderno de campo, verde profundo de monte y un toque de ocre de maíz seco. Se siente como una libreta de cuero bien hecha: sobria, cálida, con mucho aire. Nada de degradados, neones, morados ni verdes "app de salud".

> Este documento es la **fuente de verdad**. Toda pantalla se construye solo con los tokens y componentes de aquí. Si algo no está definido, se define primero aquí y luego se usa.

---

## 1. Principios

1. **Legible a pleno sol.** Contraste alto, texto nunca menor a 12 sp (cuerpo 16 sp), fondo claro por defecto. El modo oscuro existe pero el claro es el principal.
2. **Una mano, manos sucias.** Zonas táctiles grandes (mínimo 48, acciones principales 56), acciones clave abajo, cero gestos obligatorios.
3. **Registrar en menos de 3 toques.** Valores por defecto inteligentes (fecha hoy, último lote usado), detalles opcionales ocultos tras "Agregar más detalles".
4. **El color informa, nunca decide solo.** Todo estado lleva icono + texto además de color.
5. **Premium = restricción.** Un solo color de acento, superficies tonales, bordes finos, sombras casi invisibles, mucho espacio.
6. **Funciona sin internet.** Offline es el estado normal, no un error.
7. **Una acción principal por pantalla.** Lo demás es secundario y visualmente más quieto.

---

## 2. Color

### 2.1 Paleta base

| Token | Nombre | Claro | Oscuro | Uso |
|---|---|---|---|---|
| `bg` | Hueso / Noche de surco | `#F5F1E8` | `#14130F` | Fondo de pantalla |
| `surface` | Lino / Tierra oscura | `#FCFAF5` | `#1C1B16` | Tarjetas, sheets, inputs |
| `surfaceAlt` | Arcilla clara | `#EDE7DA` | `#25231D` | Chips, zonas hundidas, skeleton |
| `outline` | Hilo | `#DDD5C4` | `#38352B` | Bordes decorativos, divisores |
| `outlineStrong` | Surco | `#857D68` | `#6F6958` | Borde de inputs y controles (≥3:1) |
| `ink` | Tinta de tierra | `#1E1C17` | `#EFEAD9` | Texto principal |
| `inkSoft` | — | `#5A5445` | `#BDB6A1` | Texto secundario |
| `inkMuted` | — | `#6F6855` | `#8E8774` | Metadatos, hints |
| `primary` | Verde Ceiba | `#2C4A3A` | `#8DB89A` | Botón principal, nav activo, marca |
| `onPrimary` | — | `#F5F1E8` | `#12231A` | Texto sobre primary |
| `primarySoft` | Salvia | `#DDE6D8` | `#243629` | Fondos suaves de selección |
| `onPrimarySoft` | — | `#1B3025` | `#CFE3D4` | Texto sobre primarySoft |
| `accent` | Ocre Maíz | `#C8892B` | `#D9A453` | Un solo detalle por pantalla: cifra clave, indicador, FAB secundario |
| `onAccent` | — | `#1E1C17` | `#1E1C17` | Texto sobre accent |
| `accentSoft` | — | `#F1E2C0` | `#3A2F18` | Fondo de resaltes |
| `accentText` | Ocre tostado | `#7A5210` | `#D9A453` | Ocre **como texto** sobre fondo claro |

Reglas:
- El ocre `accent` **nunca** se usa como texto sobre fondo claro (usar `accentText`).
- Máximo **un** elemento `accent` fuerte por pantalla.
- Sin degradados. Sin transparencias para jerarquía de texto (usar `inkSoft`/`inkMuted`).

### 2.2 Semánticos

| Token | Claro | Oscuro | Significado |
|---|---|---|---|
| `positive` | `#2F6B41` | `#7FC08F` | Reacción positiva, éxito, ciclo en desarrollo |
| `neutral` | `#6F695A` | `#A8A18E` | Sin cambio, finalizado, inactivo |
| `negative` | `#A63F27` | `#E58A6F` | Daño, fitotoxicidad, error, borrar |
| `info` | `#2F5F73` | `#7FB3C8` | Agua, lluvia, riego, avisos, offline |

Fondos suaves (solo para tarjetas/chips del estado): `positiveSoft #DCEBDD`, `neutralSoft #E7E3D8`, `negativeSoft #F4DDD5`, `infoSoft #DAE8EE`. En oscuro: mezclar el color semántico al 16% sobre `surface`.
**El texto sobre un fondo suave siempre es `ink`, no el color semántico.** El color vive en el icono y en el borde.

### 2.3 Estados del ciclo de siembra

| Estado | Color (claro / oscuro) | Icono | Etiqueta |
|---|---|---|---|
| En preparación | `#7A5A3A` / `#C9A27C` | `shovel` | En preparación |
| En desarrollo | `#2F6B41` / `#7FC08F` | `plant` | En desarrollo |
| Floración / fructificación | `#7B4B6A` / `#C99BB8` | `flower` | En floración |
| En cosecha | `#8A5C0E` / `#D9A453` | `basket` | En cosecha |
| Finalizado | `#6F695A` / `#A8A18E` | `check-circle` | Finalizado |

Badge: fondo = color al 12% sobre `surface`, icono 16 en el color del estado, texto `label` en `ink`.

### 2.4 Veredicto de reacción (reemplaza los emojis 🟢⚪🔴)

Los emojis cambian según el teléfono y dependen solo del color. Se sustituyen por icono con **forma distinta** + etiqueta:

| Veredicto | Icono | Color | Etiqueta |
|---|---|---|---|
| Positiva | `check-circle` | `positive` | Positiva |
| Neutral | `minus-circle` | `neutral` | Sin cambio |
| Negativa | `warning` (triángulo) | `negative` | Negativa |

### 2.5 Contrastes verificados (WCAG)

| Par | Ratio |
|---|---|
| `ink` sobre `bg` (claro) | 15.1 : 1 |
| `inkSoft` sobre `bg` (claro) | 6.7 : 1 |
| `inkMuted` sobre `bg` (claro) | 4.9 : 1 |
| `onPrimary` sobre `primary` (claro) | 8.7 : 1 |
| `accentText` sobre `bg` (claro) | 6.1 : 1 |
| `onAccent` sobre `accent` (claro) | 5.7 : 1 |
| `positive` / `negative` / `info` sobre `surface` (claro) | 6.1 / 6.0 / 6.7 : 1 |
| `outlineStrong` sobre `surface` (claro) | 3.9 : 1 |
| `ink` sobre `bg` (oscuro) | 15.4 : 1 |
| `inkSoft` sobre `surface` (oscuro) | 8.5 : 1 |
| `primary` sobre `bg` (oscuro) | 8.4 : 1 |
| `onPrimary` sobre `primary` (oscuro) | 7.4 : 1 |

Texto deshabilitado: opacidad 0.38 del `ink` (los deshabilitados están exentos de contraste, pero se ven claramente inactivos).

---

## 3. Tipografía

| Rol | Fuente | Peso |
|---|---|---|
| Títulos y cifras grandes | **Fraunces** (serif cálida, de aspecto editorial) | 500–600 |
| Interfaz y cuerpo | **Manrope** | 500 cuerpo, 600 etiquetas, 700 títulos de tarjeta |

Fraunces le da el carácter "libreta premium" a los números de cosecha y a los títulos. Manrope aporta legibilidad al aire libre y buena cobertura de acentos en español.

### Escala (sp)

| Estilo | Fuente | Tamaño / interlínea | Peso | Uso |
|---|---|---|---|---|
| `displayLg` | Fraunces | 40 / 44 | 500 | Cifra héroe (rendimiento, ganancia neta) |
| `display` | Fraunces | 32 / 38 | 500 | Cifras de tarjeta |
| `headline` | Fraunces | 24 / 30 | 600 | Título de pantalla |
| `title` | Manrope | 18 / 24 | 700 | Título de tarjeta / sección |
| `body` | Manrope | 16 / 24 | 500 | Texto general |
| `bodySm` | Manrope | 14 / 20 | 500 | Texto de apoyo |
| `label` | Manrope | 14 / 20 | 600 | Botones, chips, etiquetas de campo |
| `overline` | Manrope | 12 / 16 | 700, mayúsculas, tracking 0.8 | Encabezado de sección |
| `caption` | Manrope | 12 / 16 | 600 | Metadatos (mínimo absoluto) |

Reglas:
- **Nada por debajo de 12 sp.** Cuerpo base 16 sp.
- Cifras (cantidades, dosis, costos, rendimientos) con `FontFeature.tabularFigures()` para que no bailen.
- Respetar el tamaño de texto del sistema; las pantallas deben sobrevivir a escala 1.3 (limitar con `TextScaler.clamp(maxScaleFactor: 1.3)` y priorizar que el texto se ajuste en varias líneas antes que truncar).
- Máximo 2 pesos por pantalla además de los de cifras.
- Empaquetar las fuentes como assets (no descarga en tiempo de ejecución): la app debe verse igual sin internet.

---

## 4. Espacio, forma y elevación

### 4.1 Escala de espaciado (múltiplos de 4/8)

`xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · x3 32 · x4 48`

| Contexto | Valor |
|---|---|
| Margen horizontal de pantalla | 20 |
| Espacio entre secciones | 32 |
| Espacio entre tarjetas de una lista | 12 |
| Padding interno de tarjeta | 20 (compacta: 16) |
| Espacio entre etiqueta y campo | 8 |
| Espacio entre campos de un formulario | 20 |
| Separación mínima entre zonas táctiles | 8 |

Aire generoso: cuando dudes entre dos valores, usa el mayor.

### 4.2 Radios

| Token | Valor | Uso |
|---|---|---|
| `rXs` | 8 | Badges pequeños, miniaturas de foto |
| `rSm` | 12 | Chips |
| `rMd` | 16 | Botones, inputs, tiles de veredicto |
| `rLg` | 20 | Tarjetas |
| `rXl` | 28 | Bottom sheets (solo esquinas superiores) |
| `rFull` | 999 | Pills, avatares, FAB extendido |

### 4.3 Bordes y elevación

Superficies **definidas por borde fino + tono**, no por sombra.

| Nivel | Tratamiento | Uso |
|---|---|---|
| 0 | Sin borde, sobre `bg` | Fondo |
| 1 | `surface` + borde 1 `outline` + sombra `0 1 2 rgba(30,28,23,.04)` | Tarjetas en reposo |
| 2 | `surface` + borde 1 `outline` + sombra `0 8 24 rgba(30,28,23,.08)` | Barra inferior, FAB, tarjeta arrastrada |
| 3 | `surface` + sombra `0 16 40 rgba(30,28,23,.14)` + scrim 50% negro detrás | Bottom sheets, diálogos |

En modo oscuro las sombras casi no se ven: la separación la hace el tono (`surface` vs `bg`) y el borde.

### 4.4 Capas (z-index)

`contenido 0 · barra superior 10 · barra inferior 20 · FAB 30 · sheet 40 · diálogo 50 · toast 60`

---

## 5. Iconografía

- Familia única: **Phosphor Icons** (`phosphor_flutter`), estilo **regular** (trazo uniforme). Nunca mezclar con relleno al mismo nivel; el relleno (`fill`) se reserva para el estado **activo/seleccionado** en la navegación.
- Tamaños: `iconSm 20`, `iconMd 24` (por defecto), `iconLg 32`, `iconXl 48` (estados vacíos).
- Zona táctil mínima 48×48 aunque el icono sea de 24.
- Todo icono sin texto lleva `Semantics(label: …)` / `tooltip`.
- Prohibido usar emojis como iconos estructurales.

Mapa sugerido (verifica los nombres exactos en el paquete):

| Concepto | Icono |
|---|---|
| Parcela / lote | `map-trifold` |
| Siembra / ciclo | `plant` |
| Aplicación de insumo | `flask` |
| Labor cultural | `shovel` |
| Plaga / enfermedad | `bug` |
| Clima adverso | `cloud-lightning` |
| Riego / agua | `drop` |
| Cosecha | `basket` |
| Foto | `camera` |
| Nota de voz | `microphone` |
| Recordatorio | `bell-ringing` |
| Costos | `wallet` |
| Historial | `clock-counter-clockwise` |
| Exportar / compartir | `share-network` |
| Sin conexión | `cloud-slash` |

---

## 6. Movimiento

| Token | Valor |
|---|---|
| `durFast` | 150 ms (pulsaciones, chips) |
| `durBase` | 220 ms (cambios de estado, expansión) |
| `durSlow` | 320 ms (transiciones de pantalla, sheets) |
| Salida | ~65% de la entrada (más rápida) |
| Curva de entrada | `Curves.easeOutCubic` |
| Curva de salida | `Curves.easeInCubic` |

- Feedback al tocar en ≤100 ms: ripple suave + escala 0.98 en tarjetas y botones (sin mover el layout vecino).
- Un máximo de 1–2 elementos animados por vista; el movimiento siempre explica algo (aparece, se guarda, se expande).
- Listas: entrada escalonada de 40 ms por elemento, solo la primera carga.
- Transición entre pantallas: deslizamiento horizontal corto (adelante ← / atrás →) y *shared element* en la foto de la parcela o del cultivo.
- Cargas > 300 ms: **skeleton** (`surfaceAlt`), no spinners largos.
- Respetar `MediaQuery.disableAnimationsOf(context)`: sin movimiento, solo cambio de opacidad.
- Háptico ligero al guardar y al elegir veredicto (`HapticFeedback.selectionClick`); nada más.

---

## 7. Componentes

### 7.1 Botones

| Variante | Fondo | Texto | Borde | Alto | Uso |
|---|---|---|---|---|---|
| **Primario** | `primary` | `onPrimary` | — | 56 | Una por pantalla ("Guardar", "Abrir siembra") |
| **Secundario** | `primarySoft` | `onPrimarySoft` | — | 56 | Acción alternativa |
| **Contorno** | transparente | `ink` | 1.5 `outlineStrong` | 56 | Acciones neutras |
| **Texto** | transparente | `primary` | — | 48 | Acciones terciarias ("Omitir") |
| **Destructivo** | `negative` | blanco | — | 56 | Solo en diálogo de confirmación |

- Ancho completo en formularios; radio `rMd`; etiqueta `label` 16 sp/600.
- Con icono: icono 20 a la izquierda, separación 8.
- **Cargando:** deshabilitar, mostrar indicador de 20 dentro del botón, mantener el ancho.
- **Deshabilitado:** opacidad 0.38, sin ripple.
- Barra de acción fija inferior: `surface` nivel 2, padding 16, respeta *safe area*.

### 7.2 Botón de registro rápido (acción principal global)

FAB **extendido** en forma de pill: `primary`, icono `plus` + texto "Registrar", alto 56, flotando 16 sobre la barra inferior, sombra nivel 2. Abre un bottom sheet con 4 opciones (cada una un tile de 72 de alto con icono en círculo `primarySoft`):

1. Aplicación de insumo
2. Labor cultural
3. Plaga o clima
4. Compra o gasto

### 7.3 Campos de formulario

- **Etiqueta siempre visible arriba** del campo (`label`, `ink`), nunca solo placeholder.
- Campo: alto 56, fondo `surface`, borde 1.5 `outlineStrong`, radio `rMd`, texto `body`.
- Foco: borde 2 `primary` + sin sombra.
- Error: borde 2 `negative` + icono `warning` + mensaje debajo (`bodySm`, `ink`) que diga **qué pasó y cómo arreglarlo** ("Falta el área del lote. Escríbela en manzanas o hectáreas.").
- Ayuda persistente debajo (`caption`, `inkMuted`).
- Obligatorios marcados con "(obligatorio)" en la etiqueta; el resto, opcionales sin marca.
- Teclado correcto según el campo (numérico para dosis, área, precios).
- Validar al salir del campo, no mientras escribe. Tras un error, llevar el foco al primer campo inválido.
- Autoguardado de borrador; confirmar antes de descartar un formulario con datos.

**Campo con unidad** (área, dosis, rendimiento, densidad): número a la izquierda y selector de unidad pegado a la derecha en el mismo contenedor (`2 | quintales ▾`). Unidades locales de primera clase: manzana, tarea, hectárea, quintal, libra, saco, caja.

**Fecha:** fila de chips `Hoy · Ayer · Elegir fecha`, con "Hoy" preseleccionado.

**Nota de voz:** botón `microphone` de 48 dentro del campo de notas; transcribe al texto, el audio queda adjunto.

### 7.4 Chips y selectores

- **Chip de filtro:** alto 40 (zona táctil 48), radio `rSm`, reposo `surfaceAlt` + texto `ink`; seleccionado `primarySoft` + borde 1.5 `primary` + icono `check` 16.
- **Selector segmentado** (2–4 opciones, p. ej. textura del suelo, topografía): contenedor `surfaceAlt`, radio `rMd`, segmento activo `surface` con borde y sombra nivel 1.
- **Selección múltiple** (tipo de insumo): cuadrícula de chips con icono.
- **Recordatorio de revisión:** segmentado `3 días · 5 días · 7 días · Sin recordatorio`.

### 7.5 Tiles de veredicto (Positiva / Sin cambio / Negativa)

Tres tiles iguales en una fila, alto 104, radio `rMd`, separación 12.

- Reposo: `surface`, borde 1.5 `outlineStrong`, icono 32 (color semántico), etiqueta `label` debajo.
- Seleccionado: fondo = color suave semántico, borde 2.5 en color semántico, check pequeño arriba a la derecha, háptico.
- Negativa seleccionada despliega debajo el campo "¿Qué síntomas viste?" (hoja quemada, amarillamiento, marchitez) con chips rápidos y nota de voz.

### 7.6 Tarjetas

Base: `surface`, borde 1 `outline`, radio `rLg`, padding 20, nivel 1. Toda la tarjeta es tocable (ripple recortado al radio).

| Tarjeta | Anatomía |
|---|---|
| **Parcela** | Foto/mapa 16:9 arriba (radio `rXs` interno) o inicial en círculo `primarySoft` · nombre (`title`) · área + riego (`bodySm`, `inkSoft`) · badge de siembra activa |
| **Siembra** | Cultivo y variedad (`title`) · parcela (`bodySm`) · badge de estado · barra de progreso fina (4 px, `surfaceAlt` con relleno `primary`) con "Día 32" |
| **Entrada de bitácora** | Círculo de tipo (40, `primarySoft`) con icono · título · fecha · dosis · chip de veredicto si aplica · miniatura de foto 56 a la derecha |
| **Cifra** (resumen) | `overline` arriba · número `display` · unidad `bodySm` · variación opcional con flecha e icono |
| **Pendiente de revisión** | Borde izquierdo de 4 px en `accent`, fondo `accentSoft`, texto `ink`, botón texto "Revisar ahora" |

### 7.7 Listas

- Separación entre tarjetas 12; sin divisores dentro de listas de tarjetas.
- Listas planas (ajustes, opciones): filas de alto mínimo 64, divisor 1 `outline` con sangría de 20.
- Más de 50 elementos: lista virtualizada (`ListView.builder`).
- Acciones por deslizamiento **nunca** como única vía: siempre hay también un menú `⋯` visible.
- Borrar = confirmación con diálogo, o bien eliminar con aviso "Deshacer" durante 5 s.

### 7.8 Navegación

**Barra inferior (5 destinos, icono + texto siempre):**

| # | Destino | Contenido |
|---|---|---|
| 1 | Inicio | Siembras activas, revisiones pendientes, resumen de la semana |
| 2 | Siembras | Ciclos (módulo 2) con su bitácora, labores e incidencias (módulos 3 y 4) |
| 3 | Parcelas | Módulo 1 |
| 4 | Historial | Línea de tiempo, búsqueda de experiencias y comparador (módulo 5) |
| 5 | Más | Costos (módulo 6), exportar, ajustes, ayuda |

- Barra: `surface` nivel 2, alto 72 + safe area, radio superior `rXl`, **sin** etiquetas ocultas.
- Activo: icono relleno (`fill`) en `primary`, etiqueta `label` en `primary`, indicador de píldora `primarySoft` de 56×32 detrás del icono. Inactivo: icono regular `inkSoft`.
- El FAB "Registrar" flota encima de la barra, alineado a la derecha, y se oculta en pantallas de formulario.
- Barra superior: fondo `bg` (sin línea hasta hacer scroll, luego borde 1 `outline`), título `headline` alineado a la izquierda, acción de atrás 48×48.
- La navegación nunca cambia de posición entre pantallas; atrás conserva scroll y filtros.

### 7.9 Bottom sheets y diálogos

- Sheet: `surface`, radio superior `rXl`, asa de 40×4 en `outlineStrong`, scrim 50% negro, se cierra deslizando, tocando fuera o con botón "Cerrar".
- Diálogo (solo confirmaciones): radio `rXl`, máximo 2 botones (acción segura a la izquierda como contorno; acción principal a la derecha).
- Si el sheet tiene datos sin guardar: preguntar antes de cerrar.

### 7.10 Avisos (toasts / snackbars)

- Flotante sobre la barra inferior, fondo `ink` (invertido), texto `bg`, radio `rMd`, icono semántico a la izquierda.
- Duran 4 s, nunca roban el foco, con acción "Deshacer" cuando aplique.
- Éxito de guardado: icono `check-circle` + "Aplicación guardada".

### 7.11 Estados vacíos

Círculo de 96 `primarySoft` con icono 48 `primary` · título `title` · una línea `bodySm` `inkSoft` · un solo botón.
Ejemplo: "Aún no hay siembras en este lote" / "Abre la primera para empezar tu bitácora" / [Abrir siembra].

### 7.12 Estado sin conexión

Franja debajo de la barra superior: `infoSoft`, icono `cloud-slash`, texto "Sin conexión · Tus registros se guardan en el teléfono". En cada elemento pendiente, un icono pequeño `cloud-arrow-up` en `inkMuted`. Al volver la red, aviso "Sincronizado".

### 7.13 Línea de tiempo del cultivo

- Riel vertical de 2 px en `outline`, a 20 px del margen izquierdo.
- Nodo: círculo de 32 `primarySoft` con icono del tipo de evento; nodos de incidencia en `negativeSoft`, de clima en `infoSoft`.
- Cabecera de grupo por semana (`overline`: "SEMANA 3 · DÍA 15–21").
- Cada evento es una tarjeta compacta (padding 16) con fecha, dosis, veredicto y miniatura.
- Hitos (siembra, floración, cosecha) en tarjetas con borde `accent`.

### 7.14 Foto antes / después

Dos miniaturas 1:1 lado a lado (radio `rMd`) con etiquetas "Antes" y "Después" en pill `ink` al 80%, más fecha. Tocar abre vista completa con deslizador de comparación. Siempre texto alternativo descriptivo.

### 7.15 Gráficas y comparador de siembras

- Barras horizontales (mejor en móvil), etiqueta directa del valor al final de cada barra.
- Serie A `primary`, serie B `accent`; además de color, diferenciar con **etiqueta en texto** (nunca solo leyenda de color).
- Rejilla 1 px `outline`, sin sombras ni degradados.
- Cada gráfica trae una **tabla/resumen en texto** debajo ("Ciclo 2024 rindió 18% más que el de 2023") y estado vacío con guía.

### 7.16 Reporte exportable (PDF / WhatsApp)

Hoja blanca `#FFFFFF`, márgenes 24, encabezado con nombre de la parcela y cultivo en Fraunces, tablas con filas zebra `#F5F1E8`, texto `#1E1C17`, pie con fecha y nombre de la app. Mismo vocabulario visual que la app.

---

## 8. Plantillas de pantalla (para que todas se vean iguales)

Cada pantalla de la app es una de estas 5. No se inventan estructuras nuevas.

**A. Lista** (Siembras, Parcelas, Historial, Costos)
Barra superior → buscador/chips de filtro → lista de tarjetas (espacio 12) → FAB "Registrar".

**B. Detalle** (Parcela, Siembra)
Barra superior transparente sobre cabecera (foto o color `primarySoft`) → título `headline` → fila de 2–3 tarjetas cifra → secciones con `overline` + contenido (espacio 32) → acciones.

**C. Formulario** (Nueva parcela, Abrir siembra, Aplicación, Labor, Incidencia, Compra)
Barra superior con "X" → título `headline` → campos agrupados en tarjetas por tema (espacio 20 entre campos) → "Agregar más detalles" (expandible) → barra de acción fija con **Guardar** (primario).

**D. Línea de tiempo / bitácora** (cronología del cultivo)
Barra superior → chips de filtro por tipo → riel con eventos agrupados por semana.

**E. Resumen / comparación** (Inicio, comparador, costos del ciclo)
Barra superior → cifra héroe en `displayLg` sobre `bg` (sin tarjeta) → tarjetas de apoyo → gráfica con resumen en texto.

### Mapa módulo → plantilla

| Módulo | Pantallas |
|---|---|
| 1. Parcelas | Lista (A) · Detalle (B) · Nueva/editar (C, con selectores de textura, topografía y riego) |
| 2. Ciclos de siembra | Lista (A) · Detalle con timeline y cierre (B + D) · Abrir siembra (C) · Cerrar ciclo y cosecha (C) |
| 3. Bitácora e insumos | Aplicación (C con tiles de veredicto en el seguimiento) · Seguimiento post-aplicación (C corta) |
| 4. Labores y clima | Labor (C) · Incidencia/plaga/clima (C con severidad: Leve · Moderada · Crítica en segmentado con icono) |
| 5. Historial y aprendizaje | Timeline (D) · Búsqueda de experiencias (A) · Comparador (E) · Exportar (sheet) |
| 6. Costos | Resumen del ciclo con ganancia neta (E) · Compras (A) · Nueva compra (C) |

**Severidad** (Leve/Moderada/Crítica): tres segmentos con iconos de 1, 2 y 3 barras (`cell-signal-low/medium/full` o equivalente) en `neutral` → `accentText` → `negative`, siempre con texto.

---

## 9. Patrones específicos de campo

1. **Valores por defecto:** fecha = hoy, parcela = la última usada, unidad = la última usada para ese insumo.
2. **Entrada rápida:** máximo 3 campos obligatorios por registro de bitácora; el resto en "Agregar más detalles".
3. **Condiciones climáticas al aplicar:** fila de chips con icono (Soleado, Nublado, Suelo húmedo, Lluvia después), selección única.
4. **Hora de aplicación:** chips "Mañana fresca · Mediodía · Tarde" además de hora exacta opcional.
5. **Zonas táctiles de pulgar:** acciones principales en el tercio inferior de la pantalla.
6. **GPS opcional:** botón "Usar mi ubicación" con explicación breve del permiso, nunca bloquea el guardado.
7. **Cálculo de costos:** el total y la ganancia neta se muestran en `displayLg`; ganancia positiva con icono `trending-up` en `positive`, pérdida con icono `trending-down` en `negative` y la palabra "pérdida".
8. **Idioma:** español claro y directo, "tú" o "usted" consistente en toda la app (decidir una vez), sin tecnicismos innecesarios.

---

## 10. Accesibilidad (obligatorio)

- Contraste ≥4.5:1 en texto normal, ≥3:1 en texto grande, iconos y bordes de controles.
- Zonas táctiles ≥48×48 con separación ≥8.
- Toda información de estado = color + icono + texto.
- `Semantics` en todo control sin texto; orden de lectura igual al visual.
- Foco visible: anillo 2 px `primary` con offset 2.
- Texto escalable hasta 1.3 sin cortar contenido.
- Movimiento reducido respetado.
- Probar en teléfono pequeño (360 px de ancho), grande y horizontal, y en claro y oscuro **por separado**.

---

## 11. Anti-patrones (prohibido)

- Degradados, neones, morado/índigo, verde "Material por defecto" (`#4CAF50`), gris sobre gris.
- Emojis como iconos; mezclar iconos rellenos y de contorno al mismo nivel.
- Sombras fuertes o personalizadas por pantalla; colores en hex dentro de los widgets.
- Más de una acción primaria por pantalla; más de un uso fuerte de `accent`.
- Placeholders como única etiqueta; errores solo arriba del formulario.
- Gestos como única forma de hacer algo; texto de menos de 12 sp.
- Spinners largos bloqueantes; animaciones de más de 400 ms.
- Pantallas con estructura distinta a las 5 plantillas.

---

## 12. Implementación en Flutter

Dependencias sugeridas: `google_fonts` (con fuentes empaquetadas), `phosphor_flutter`, `provider`.

### 12.1 Tokens centralizados

```dart
// lib/core/design/app_colors.dart
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.outlineStrong,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.accentText,
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.info,
    required this.stagePrep,
    required this.stageGrowth,
    required this.stageFlower,
    required this.stageHarvest,
    required this.stageDone,
  });

  final Color bg, surface, surfaceAlt, outline, outlineStrong;
  final Color ink, inkSoft, inkMuted;
  final Color primary, onPrimary, primarySoft, onPrimarySoft;
  final Color accent, onAccent, accentSoft, accentText;
  final Color positive, neutral, negative, info;
  final Color stagePrep, stageGrowth, stageFlower, stageHarvest, stageDone;

  static const light = AppColors(
    bg: Color(0xFFF5F1E8),
    surface: Color(0xFFFCFAF5),
    surfaceAlt: Color(0xFFEDE7DA),
    outline: Color(0xFFDDD5C4),
    outlineStrong: Color(0xFF857D68),
    ink: Color(0xFF1E1C17),
    inkSoft: Color(0xFF5A5445),
    inkMuted: Color(0xFF6F6855),
    primary: Color(0xFF2C4A3A),
    onPrimary: Color(0xFFF5F1E8),
    primarySoft: Color(0xFFDDE6D8),
    onPrimarySoft: Color(0xFF1B3025),
    accent: Color(0xFFC8892B),
    onAccent: Color(0xFF1E1C17),
    accentSoft: Color(0xFFF1E2C0),
    accentText: Color(0xFF7A5210),
    positive: Color(0xFF2F6B41),
    neutral: Color(0xFF6F695A),
    negative: Color(0xFFA63F27),
    info: Color(0xFF2F5F73),
    stagePrep: Color(0xFF7A5A3A),
    stageGrowth: Color(0xFF2F6B41),
    stageFlower: Color(0xFF7B4B6A),
    stageHarvest: Color(0xFF8A5C0E),
    stageDone: Color(0xFF6F695A),
  );

  static const dark = AppColors(
    bg: Color(0xFF14130F),
    surface: Color(0xFF1C1B16),
    surfaceAlt: Color(0xFF25231D),
    outline: Color(0xFF38352B),
    outlineStrong: Color(0xFF6F6958),
    ink: Color(0xFFEFEAD9),
    inkSoft: Color(0xFFBDB6A1),
    inkMuted: Color(0xFF8E8774),
    primary: Color(0xFF8DB89A),
    onPrimary: Color(0xFF12231A),
    primarySoft: Color(0xFF243629),
    onPrimarySoft: Color(0xFFCFE3D4),
    accent: Color(0xFFD9A453),
    onAccent: Color(0xFF1E1C17),
    accentSoft: Color(0xFF3A2F18),
    accentText: Color(0xFFD9A453),
    positive: Color(0xFF7FC08F),
    neutral: Color(0xFFA8A18E),
    negative: Color(0xFFE58A6F),
    info: Color(0xFF7FB3C8),
    stagePrep: Color(0xFFC9A27C),
    stageGrowth: Color(0xFF7FC08F),
    stageFlower: Color(0xFFC99BB8),
    stageHarvest: Color(0xFFD9A453),
    stageDone: Color(0xFFA8A18E),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors ? (t < 0.5 ? this : other) : this;
}

extension AppColorsX on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}
```

```dart
// lib/core/design/app_tokens.dart
import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 20.0, xxl = 24.0, x3 = 32.0, x4 = 48.0;
  static const screenH = 20.0;
}

abstract final class AppRadius {
  static const xs = 8.0, sm = 12.0, md = 16.0, lg = 20.0, xl = 28.0;
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get control => BorderRadius.circular(md);
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 320);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}

abstract final class AppShadow {
  static List<BoxShadow> level1(Color ink) => [
        BoxShadow(
          color: ink.withValues(alpha: 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
  static List<BoxShadow> level2(Color ink) => [
        BoxShadow(
          color: ink.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
```

### 12.2 Tema

```dart
// lib/core/design/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.accent,
      onSecondary: c.onAccent,
      error: c.negative,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.ink,
    );

    TextStyle ui(double size, double h, FontWeight w) => GoogleFonts.manrope(
          fontSize: size,
          height: h / size,
          fontWeight: w,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    TextStyle serif(double size, double h, FontWeight w) =>
        GoogleFonts.fraunces(
          fontSize: size,
          height: h / size,
          fontWeight: w,
          color: c.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    final text = TextTheme(
      displayLarge: serif(40, 44, FontWeight.w500),
      displayMedium: serif(32, 38, FontWeight.w500),
      headlineMedium: serif(24, 30, FontWeight.w600),
      titleMedium: ui(18, 24, FontWeight.w700),
      bodyLarge: ui(16, 24, FontWeight.w500),
      bodyMedium: ui(14, 20, FontWeight.w500),
      labelLarge: ui(14, 20, FontWeight.w600),
      labelSmall: ui(12, 16, FontWeight.w700).copyWith(letterSpacing: 0.8),
      bodySmall: ui(12, 16, FontWeight.w600).copyWith(color: c.inkMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      textTheme: text,
      extensions: [c],
      splashFactory: InkRipple.splashFactory,
      dividerColor: c.outline,
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: c.ink,
          side: BorderSide(color: c.outlineStrong, width: 1.5),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.outlineStrong, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.outlineStrong, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.negative, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.negative, width: 2),
        ),
        helperStyle: text.bodySmall,
        errorStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.control),
      ),
    );
  }
}
```

### 12.3 Reglas de código

- **Cero hex en widgets.** Solo `context.c.<token>`.
- Un widget por componente (clase propia, no métodos privados `_buildX`): `AppCard`, `AppStageBadge`, `VerdictTiles`, `UnitField`, `TimelineEvent`, `MetricCard`, `EmptyState`, `OfflineBanner`, `QuickAddFab`.
- Tamaños de pantalla con `MediaQuery.sizeOf(context)`.
- Opacidades con `color.withValues(alpha: …)`.
- Estado con Provider; los componentes reciben datos por parámetros, sin lógica de negocio.

Ejemplo base de tarjeta:

```dart
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.compact = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.outline),
        boxShadow: AppShadow.level1(c.ink),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadius.card,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpace.lg : AppSpace.xl),
            child: child,
          ),
        ),
      ),
    );
  }
}
```

---

## 13. Lista de verificación antes de entregar una pantalla

- [ ] Usa una de las 5 plantillas (A–E)
- [ ] Solo tokens de `AppColors`, `AppSpace`, `AppRadius`, sin hex ni medidas sueltas
- [ ] Una sola acción primaria; a lo sumo un uso fuerte del ocre
- [ ] Todo estado tiene icono + texto, no solo color
- [ ] Zonas táctiles ≥48, acciones principales 56
- [ ] Etiquetas visibles en todos los campos; errores junto al campo con solución
- [ ] Probada en claro y oscuro, 360 px de ancho, horizontal y texto al 130%
- [ ] Estados cubiertos: cargando (skeleton), vacío, error con reintento, sin conexión
- [ ] Contenido no tapado por barras fijas ni *safe areas*
- [ ] Animaciones 150–320 ms y con movimiento reducido respetado
- [ ] Iconos de una sola familia (Phosphor regular), con `Semantics`
