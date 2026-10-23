1. Módulo de Parcelas / Lotes (El Terreno)
Antes de registrar un cultivo, el agricultor necesita definir en qué pedazo de tierra está trabajando, ya que las condiciones del suelo cambian incluso dentro de una misma propiedad.

Ficha del Lote / Parcela:

Nombre o apodo del terreno (ej. El Rincón, Lote Alto, La Vega).

Área o extensión (manzanas, tareas, hectáreas o metros cuadrados).

Ubicación básica (coordenadas GPS opcionales tomadas con el teléfono).

Perfil del Suelo:

Tipo de textura: Arcilloso, arenoso, franco, franco-arcilloso, pedregoso.

Topografía: Plano, ladera suave, ladera inclinada.

Acceso a agua: Riego por goteo, aspersión, canal/gravedad o únicamente de temporal (lluvia).

Notas de historial previo: Qué cultivo estuvo sembrado antes en esa tierra (para rotación de cultivos).

2. Módulo de Ciclos de Siembra (El Núcleo del Sistema)
Este módulo gestiona cada campaña o ciclo productivo desde que se prepara la tierra hasta la cosecha final.

Apertura de Siembra:

Selección de la parcela / lote.

Cultivo y variedad (ej. Maíz híbrido, Frijol rojo, Tomate pólder, Chile jalapeño).

Fecha exacta de siembra o trasplante.

Densidad o cantidad sembrada (ej. libras de semilla, número de plántulas, distanciamiento entre surcos).

Estado del Ciclo:

Indicador de estado: En preparación, En desarrollo/crecimiento, En floración/fructificación, En cosecha, Finalizado.

Cierre de Ciclo y Cosecha:

Fecha de inicio y fin de la cosecha.

Rendimiento total obtenido (quintales, cajas, sacos, libras o toneladas).

Calidad general percibida (Primera, segunda, descarte/merma).

Evaluación general del ciclo (notas de qué funcionó y qué falló).

3. Módulo de Bitácora de Campo y Manejo de Insumos
Es el registro diario o semanal de todo lo que se le hace al cultivo. Cada entrada en la bitácora debe ser rápida de crear.

Registro de Aplicación de Insumos / Implementos:

Tipo de insumo: Fertilizante granular, foliar (ej. Calcio, Boro, Fósforo), biofertilizante, enmienda (cal agrícola, materia orgánica), insecticida, fungicida o herbicida.

Nombre comercial o compuesto: (ej. Nitrato de calcio, Urea 46%, Abono orgánico).

Dosis aplicada y método: (ej. 2 copas por bomba de 20L, 1 quintal por manzana, al pie o al follaje).

Fecha y hora de aplicación: (importante registrar si se aplicó en mañana fresca o con sol fuerte).

Condiciones climáticas al aplicar: Soleado, nublado, suelo húmedo, lluvia posterior.

Seguimiento y Registro de Reacción (Post-Aplicación):

Alerta o recordatorio para revisar el cultivo a los 3, 5 o 7 días de la aplicación.

Veredicto visual rápido: Botones grandes para seleccionar:

🟢 Positiva: El cultivo respondió bien (follaje más verde, vigor, detuvo caída de flor).

⚪ Neutral: No se observó cambio visible ni mejoría.

🔴 Negativa: Daño, fitotoxicidad (hoja quemada, amarillamiento, marchitez).

Descripción de la reacción: Campo de texto o nota de voz transcribible con los síntomas observados.

Foto comparativa: Posibilidad de adjuntar una foto del "antes" y del "después".

4. Módulo de Labores Culturales y Eventos Climáticos
No todo lo que se hace en la parcela es aplicar químicos o fertilizantes; las labores mecánicas y el clima determinan el éxito del cultivo.

Registro de Labores:

Preparación de tierra (arado, rastra, surcado manual).

Deshierbe o chapea (manual, con azadón o mecánico).

Aporco, deschuponado o tutorado (estacado/amarre).

Riegos realizados (duración en horas o lámina de agua).

Registro de Incidencias y Plagas:

Aparición de plagas o enfermedades (ej. gusano cogollero, mosca blanca, roya).

Severidad (Leve, moderada, crítica).

Eventos climáticos adversos: sequía prolongada, exceso de lluvia, granizo, viento fuerte.

5. Módulo de Historial y Cuaderno de Aprendizaje (Base de Conocimiento)
Este módulo convierte los datos aislados en lecciones útiles para futuras temporadas.

Línea de Tiempo del Cultivo:

Vista cronológica completa de la siembra: desde el día 0 hasta la cosecha, viendo en una sola pantalla todas las aplicaciones, fotos y reacciones.

Filtros de Búsqueda de Experiencias:

Buscar por insumo: "¿Qué pasó la última vez que apliqué Calcio en suelo arcilloso?"

Buscar por cultivo: "Ver todas las siembras de Tomate en el Lote 2 y comparar rendimientos".

Comparador de Siembras:

Comparar dos ciclos del mismo cultivo: fechas de siembra, productos aplicados y rendimiento final obtenido para identificar qué manejo dio más cosecha.

Exportación de Bitácora:

Generación de un reporte simple en PDF o para compartir por WhatsApp con un técnico agrícola, cooperativa o perito de banco.

6. Módulo Básico de Costos
Muchos productores saben cuánto cosecharon, pero no cuánto invirtieron exactamente en cada manzana.

Registro rápido de compras de insumos (precio del saco de abono, semilla, jornales).

Cálculo automático del costo total del ciclo vs. la venta de la cosecha para mostrar la ganancia neta real.

Consideraciones Técnicas Críticas para Flutter
Arquitectura Offline-First:

En el campo la señal móvil suele ser nula o inestable. La app debe funcionar al 100% de forma local usando una base de datos embebida de SQLite.

Entrada de Datos Adaptada:

Botones táctiles grandes (tamaño mínimo de 48x48 dp), fuentes legibles bajo luz solar directa (alto contraste), selectores rápidos (chips/tags predefinidos en vez de escribir todo con teclado) y opción para adjuntar fotos directamente desde la cámara comprimidas localmente para no llenar la memoria del teléfono.