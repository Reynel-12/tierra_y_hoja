import 'package:flutter/widgets.dart';

import '../../../core/design/app_icons.dart';

/// Información de un campo de entrada dentro de un formulario para el tour guiado.
class TourInputFieldInfo {
  const TourInputFieldInfo({
    required this.name,
    required this.dataType,
    required this.description,
    this.isRequired = false,
  });

  /// Nombre del campo (ej. "Nombre del terreno", "Dosis").
  final String name;

  /// Tipo de dato aceptado (ej. "Texto libre", "Número > 0 + Unidad", "Selector de un toque").
  final String dataType;

  /// Explicación concisa de para qué sirve o qué valor poner.
  final String description;

  /// Indica si es obligatorio u opcional.
  final bool isRequired;
}

/// Representa una etapa completa del recorrido guiado de aprendizaje.
class TourStepData {
  const TourStepData({
    required this.stepNumber,
    required this.shortName,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.whyOrder,
    required this.appLocation,
    required this.screenPurpose,
    required this.inputsSummary,
    required this.agriculturalTip,
  });

  final int stepNumber;
  final String shortName;
  final String title;
  final String tagline;
  final IconData icon;
  final String whyOrder;
  final String appLocation;
  final String screenPurpose;
  final List<TourInputFieldInfo> inputsSummary;
  final String agriculturalTip;

  /// Lista exhaustiva y ordenada de los 9 pasos reales del flujo agrícola.
  static const List<TourStepData> steps = [
    // -------------------------------------------------------------
    // PASO 1: LOTES / PARCELAS
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 1,
      shortName: '1. Lotes',
      title: 'Módulo de Parcelas y Lotes',
      tagline: 'El Terreno · Primer paso obligatorio',
      icon: AppIcons.plot,
      whyOrder:
          'Antes de sembrar cualquier semilla o comprar fertilizantes, se debe definir en qué pedazo de tierra trabajará. Cada lote posee un tipo de suelo, acceso a agua y topografía propios.',
      appLocation:
          'Pestaña inferior "Lotes" ➔ Botón "+" en la esquina superior derecha.',
      screenPurpose:
          'Crea la ficha del terreno para que luego todas las siembras, insumos y costos queden registrados en esa tierra específica.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Nombre o apodo',
          dataType: 'Texto libre',
          description:
              'Nombre con el que conoce la tierra (ej. "El Rincón", "La Vega", "Lote Alto").',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Área o extensión',
          dataType: 'Número mayor a 0 + Unidad',
          description:
              'Tamaño del lote en Manzanas (mz), Hectáreas (ha), Tareas o Metros cuadrados (m²).',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Perfil del suelo',
          dataType: 'Selector rápido de 1 toque',
          description:
              'Textura del suelo (Arcilloso, Arenoso, Franco, Franco-arcilloso o Pedregoso).',
        ),
        TourInputFieldInfo(
          name: 'Topografía y Agua',
          dataType: 'Selector de botones',
          description:
              'Terreno plano o ladera; y si tiene riego por goteo, canal o solo lluvia (temporal).',
        ),
        TourInputFieldInfo(
          name: 'GPS y Foto',
          dataType: 'Ubicación satelital y Cámara',
          description:
              'Guarda las coordenadas geográficas del terreno y una foto panorámica de referencia.',
        ),
      ],
      agriculturalTip:
          'Si un sector de su propiedad retiene más humedad que otro, regístrelo como un lote separado para comparar rendimientos futuros.',
    ),

    // -------------------------------------------------------------
    // PASO 2: CICLOS DE SIEMBRA
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 2,
      shortName: '2. Siembras',
      title: 'Módulo de Ciclos de Siembra',
      tagline: 'El Núcleo del Sistema · Apertura de campaña',
      icon: AppIcons.cycle,
      whyOrder:
          'Una vez registrada la tierra, se abre formalmente la siembra o temporada productiva en ese lote.',
      appLocation:
          'Pestaña inferior "Siembras" ➔ Botón "+" en la esquina superior derecha, o desde el botón flotante (+).',
      screenPurpose:
          'Administra el ciclo completo de cultivo desde la siembra hasta la cosecha, acompañando las 5 fases biológicas del cultivo.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Selección de lote',
          dataType: 'Selector desplegable',
          description:
              'Elige la parcela de tierra previamente creada donde se sembrará.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Cultivo y variedad',
          dataType: 'Texto o chips sugeridos',
          description:
              'Especie y variedad exacta (ej. "Maíz híbrido DK-7088", "Frijol rojo seda", "Tomate pólder").',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Fecha de siembra',
          dataType: 'Fecha (Calendario)',
          description:
              'Día exacto en que se sembró la semilla o se realizó el trasplante.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Densidad sembrada',
          dataType: 'Número + Unidad',
          description:
              'Cantidad de semilla sembrada (ej. 25 Libras, 10,000 Plántulas o distancia entre surcos).',
        ),
        TourInputFieldInfo(
          name: 'Etapas del cultivo',
          dataType: 'Visualización automática',
          description:
              'Transición por etapas: En preparación ➔ En desarrollo ➔ En floración ➔ En cosecha ➔ Finalizado.',
        ),
      ],
      agriculturalTip:
          'Registrar la variedad exacta del cultivo le permite comprobar qué casa comercial o híbrido produce mejor en su tipo de suelo.',
    ),

    // -------------------------------------------------------------
    // PASO 3: BITÁCORA — APLICACIÓN DE INSUMOS
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 3,
      shortName: '3. Insumos',
      title: 'Módulo de Bitácora de Campo',
      tagline: 'Nutrición y Protección · Registro de aplicaciones',
      icon: AppIcons.application,
      whyOrder:
          'A medida que la planta crece, se aplican fertilizantes y protectores. Registrar cada aplicación evita sobredosis y gasto a ciegas.',
      appLocation:
          'Botón flotante central (+) ➔ "Aplicación de insumo", o desde el detalle de la siembra activa.',
      screenPurpose:
          'Anota qué producto aplicó, la dosis exacta, método y clima, programando un recordatorio para evaluar si funcionó.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Tipo de insumo',
          dataType: 'Selector rápido de 1 toque',
          description:
              'Fertilizante granular, Foliar, Insecticida, Fungicida, Herbicida, Biofertilizante o Enmienda.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Nombre del producto',
          dataType: 'Texto libre',
          description:
              'Nombre comercial o compuesto (ej. "Urea 46%", "Nitrato de Calcio", "Cal agrícola").',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Dosis y método',
          dataType: 'Número + Unidad + Método',
          description:
              'Cantidad aplicada (ej. 1.5 Quintales, 2 Copas/bomba) y forma (Al pie o Al follaje).',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Clima y momento',
          dataType: 'Chips ilustrados',
          description:
              'Soleado, Nublado, Suelo húmedo; Mañana fresca o Tarde con sol.',
        ),
        TourInputFieldInfo(
          name: 'Recordatorio de revisión',
          dataType: 'Selección de días (3, 5 o 7)',
          description:
              'El sistema programa una alerta local en su teléfono para revisar la respuesta del cultivo.',
        ),
      ],
      agriculturalTip:
          'Evite aplicar foliares con sol ardiente de mediodía. Registrar el clima le mostrará en qué horas la planta absorbe mejor los nutrientes.',
    ),

    // -------------------------------------------------------------
    // PASO 4: SEGUIMIENTO Y VEREDICTO
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 4,
      shortName: '4. Veredicto',
      title: 'Seguimiento y Reacción al Insumo',
      tagline: 'Comprobación Biológica · ¿Funcionó la aplicación?',
      icon: AppIcons.checkCircle,
      whyOrder:
          'A los pocos días de aplicar un producto, la regla de oro es revisar el cultivo para comprobar si respondió favorablemente o si hubo daño.',
      appLocation:
          'En la pantalla de "Inicio" aparece una tarjeta "Revisión pendiente", o directamente en la bitácora de la siembra.',
      screenPurpose:
          'Asienta el veredicto visual rápido y los síntomas observados para construir la memoria histórica de la finca.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Veredicto visual (3 botones)',
          dataType: 'Botón táctil grande',
          description:
              '🟢 Positiva (vigor, verdor) | ⚪ Sin cambio (neutral) | 🔴 Negativa (daño, hoja quemada).',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Síntomas y notas de voz',
          dataType: 'Texto o Dictado por micrófono',
          description:
              'Descripción de los cambios observados. Puede dictar por voz si tiene las manos de tierra.',
        ),
        TourInputFieldInfo(
          name: 'Fotos antes y después',
          dataType: 'Cámara y Galería local',
          description:
              'Permite adjuntar una foto de cómo estaba la planta antes y cómo quedó tras la aplicación.',
        ),
      ],
      agriculturalTip:
          'El botón de dictado por voz es ideal para el campo: hable con naturalidad y el teléfono transcribirá sus observaciones sin ensuciar la pantalla.',
    ),

    // -------------------------------------------------------------
    // PASO 5: LABORES CULTURALES E INCIDENCIAS
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 5,
      shortName: '5. Labores y Plagas',
      title: 'Labores Culturales e Incidencias',
      tagline: 'Manejo Físico y Emergencias · Plagas y Clima',
      icon: AppIcons.task,
      whyOrder:
          'El éxito del cultivo no solo depende de químicos: las labores manuales (aporco, riego) y el ataque de plagas o clima definen la cosecha.',
      appLocation:
          'Botón flotante central (+) ➔ "Labor cultural" o "Incidencia / Plaga".',
      screenPurpose:
          'Lleva el registro de trabajos mecánicos, horas de riego por bombeo y alertas de plagas con su nivel de gravedad.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Tipo de labor',
          dataType: 'Chips predefinidos',
          description:
              'Preparación, Deshierbe manual o chapea, Aporco, Tutorado o Riego.',
        ),
        TourInputFieldInfo(
          name: 'Riego y operarios',
          dataType: 'Número de horas y trabajadores',
          description:
              'Duración del riego en horas o lámina en mm, y cantidad de jornales dedicados.',
        ),
        TourInputFieldInfo(
          name: 'Incidencia o plaga',
          dataType: 'Tipo + Nombre + Severidad',
          description:
              'Plaga (gusano cogollero), Enfermedad (roya) o Clima adverso (sequía, granizo). Severidad: Leve, Moderada o Crítica.',
        ),
        TourInputFieldInfo(
          name: 'Acción correctiva tomada',
          dataType: 'Texto libre',
          description:
              'Qué medida inmediata se tomó para contener el problema antes de que se propague.',
        ),
      ],
      agriculturalTip:
          'Registrar las plagas cuando apenas están en nivel "Leve" le ayuda a recordar qué fechas del año suelen llegar los insectos a su zona.',
    ),

    // -------------------------------------------------------------
    // PASO 6: COSTOS Y FINANZAS
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 6,
      shortName: '6. Finanzas',
      title: 'Módulo de Costos y Ventas',
      tagline: 'Economía del Productor · Cuentas claras en el bolsillo',
      icon: AppIcons.costs,
      whyOrder:
          'Para saber si una siembra fue realmente rentable, se deben contabilizar los gastos desde el día uno y compararlos con las ventas.',
      appLocation:
          'Botón flotante (+) ➔ "Gasto", y en pestaña "Más" ➔ "Costos y Finanzas Globales".',
      screenPurpose:
          'Calcula automáticamente el total invertido por categoría (abonos, jornales, semilla) vs. las ventas obtenidas, mostrando la ganancia neta en Lempiras.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Categoría de gasto',
          dataType: 'Selector rápido de 1 toque',
          description:
              'Insumos, Jornales (mano de obra), Semilla, Riego, Maquinaria, Flete o Herramientas.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Monto en dinero (L)',
          dataType: 'Número decimal positivo',
          description:
              'Precio total pagado en Lempiras (L). Puede desglosar cantidad y precio unitario.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Registro de ventas',
          dataType: 'Cantidad + Precio + Comprador',
          description:
              'Quintales o cajas vendidas, precio cobrado por quintal y nombre del comprador.',
        ),
        TourInputFieldInfo(
          name: 'Ganancia neta y ROI %',
          dataType: 'Cálculo en vivo automático',
          description:
              'La app resta automáticamente los gastos de los ingresos para mostrar su ganancia real.',
        ),
      ],
      agriculturalTip:
          'No olvide anotar el costo de transporte ni los pequeños gastos de gasolina: sumados representan una parte importante de la inversión.',
    ),

    // -------------------------------------------------------------
    // PASO 7: CIERRE DE CICLO Y COSECHA
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 7,
      shortName: '7. Cosecha',
      title: 'Cierre de Ciclo y Cosecha',
      tagline: 'Rendimiento Final · Lecciones aprendidas',
      icon: AppIcons.harvest,
      whyOrder:
          'Al finalizar la cosecha, se asienta la producción total obtenida y se reflexiona sobre los aciertos y fallos de la temporada.',
      appLocation:
          'Desde el detalle de la siembra activa ➔ Botón "Cerrar y cosechar ciclo".',
      screenPurpose:
          'Finaliza formalmente la siembra activa, almacena el volumen cosechado y califica la calidad del producto.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Rendimiento total',
          dataType: 'Número + Unidad de medida',
          description:
              'Total cosechado (ej. 180 Quintales, 450 Cajas, 3 Toneladas, 2,500 Libras).',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: 'Calidad del producto',
          dataType: 'Selector rápido de 1 toque',
          description: 'Primera calidad, Segunda calidad o Descarte / Merma.',
          isRequired: true,
        ),
        TourInputFieldInfo(
          name: '¿Qué funcionó bien?',
          dataType: 'Texto reflexivo',
          description:
              'Anotaciones de lo que dio buen resultado (ej. "El riego por goteo temprano aumentó tamaño del grano").',
        ),
        TourInputFieldInfo(
          name: '¿Qué falló o debe mejorarse?',
          dataType: 'Texto reflexivo',
          description:
              'Notas de fallos a evitar en la siguiente siembra (ej. "Deshierbe tardío en la tercera semana").',
        ),
      ],
      agriculturalTip:
          'Escribir honestamente qué falló es lo más valioso del cuaderno: le evitará repetir costosos errores en la próxima temporada.',
    ),

    // -------------------------------------------------------------
    // PASO 8: HISTORIAL Y MEMORIA AGRÍCOLA
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 8,
      shortName: '8. Memoria',
      title: 'Historial y Base de Conocimiento',
      tagline: 'Inteligencia Agrícola · Comparador y Exportación',
      icon: AppIcons.history,
      whyOrder:
          'Los datos del ciclo no se quedan guardados sin uso: se transforman en conocimiento para tomar mejores decisiones cada año.',
      appLocation:
          'Pestaña inferior "Memoria", y en pestaña "Más" (Comparador de siembras).',
      screenPurpose:
          'Permite consultar la línea de tiempo completa del cultivo, comparar dos siembras frente a frente.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Línea de tiempo cronológica',
          dataType: 'Visualización fotográfica',
          description:
              'Recorrido día a día con todas las aplicaciones, labores, fotos y veredictos del ciclo.',
        ),
        TourInputFieldInfo(
          name: 'Búsqueda de experiencias',
          dataType: 'Filtro por producto o cultivo',
          description:
              'Consulte qué pasó la última vez que aplicó un foliar específico en suelo arcilloso.',
        ),
        TourInputFieldInfo(
          name: 'Comparador de 2 siembras',
          dataType: 'Comparativa lado a lado',
          description:
              'Compara dos cosechas del mismo cultivo para identificar cuál método produjo más quintales.',
        ),
        // TourInputFieldInfo(
        //   name: 'Exportación a PDF / WhatsApp',
        //   dataType: 'Documento PDF compartible',
        //   description:
        //       'Genera un informe técnico con formato oficial para compartir con cooperativas, bancos o técnicos.',
        // ),
      ],
      agriculturalTip:
          'La exportación a PDF le sirve como comprobante ante peritos bancarios si tramita un crédito o asistencia técnica.',
    ),

    // -------------------------------------------------------------
    // PASO 9: COPIAS DE SEGURIDAD Y RESPALDO
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 9,
      shortName: '9. Copias',
      title: 'Copias de Seguridad y Respaldo',
      tagline: 'Protección de sus Datos · Toda su finca y fotos seguras',
      icon: AppIcons.database,
      whyOrder:
          'Después de registrar sus parcelas, siembras, labores y cosechas, es fundamental proteger todo su esfuerzo. Una copia de seguridad le garantiza que nunca perderá su información si extravía o cambia de teléfono.',
      appLocation:
          'Pestaña inferior "Más" ➔ Opción "Copias de Seguridad y Restauración".',
      screenPurpose:
          'Guarda todas las notas de su finca y todas las fotografías en un solo archivo protegido. Puede crear copias en cualquier momento, enviarlas por WhatsApp o restaurarlas en un nuevo teléfono.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Carpeta de guardado',
          dataType: 'Carpeta en su teléfono',
          description:
              'Lugar donde se guardan sus copias. Se recomienda cambiar la carpeta predeterminada por una fácil de recordar (como "Descargas") para que encuentre sus archivos rápidamente.',
        ),
        TourInputFieldInfo(
          name: 'Crear copia de seguridad',
          dataType: 'Botón de 1 toque',
          description:
              'Empaqueta todas sus siembras, fotos, cuentas y notas en un solo archivo liviano y seguro sin necesidad de internet.',
        ),
        TourInputFieldInfo(
          name: 'Compartir copia por WhatsApp',
          dataType: 'Envío directo desde el teléfono',
          description:
              'Le permite enviar el archivo de su copia a un familiar, a su técnico o guardarlo en su correo para mayor tranquilidad.',
        ),
        TourInputFieldInfo(
          name: 'Restaurar copia de seguridad',
          dataType: 'Selección de archivo',
          description:
              'Si cambia de teléfono, solo elija su archivo de copia y la aplicación recuperará automáticamente todos sus datos y fotografías.',
        ),
      ],
      agriculturalTip:
          'Recomendación de oro: Cambie la carpeta donde se guardan las copias a "Descargas". Así sabrá exactamente dónde buscar su archivo cuando quiera enviarlo por WhatsApp o guardarlo en una memoria.',
    ),

    // -------------------------------------------------------------
    // PASO 10: PANTALLA DE INICIO Y ACCESO RÁPIDO
    // -------------------------------------------------------------
    TourStepData(
      stepNumber: 10,
      shortName: '10. Inicio y FAB',
      title: 'Pantalla de Inicio y Acceso Rápido',
      tagline: 'Centro de Operaciones Diario · 100% Offline',
      icon: AppIcons.home,
      whyOrder:
          'Ahora que conoce todo el funcionamiento, la pantalla de Inicio y el botón flotante (+) son las herramientas que usará todos los días en el campo.',
      appLocation:
          'Pestaña inferior "Inicio" y botón flotante verde (+) en la parte inferior de la pantalla.',
      screenPurpose:
          'Le muestra en un vistazo sus siembras activas, tareas pendientes y recordatorios de revisión de insumos.',
      inputsSummary: [
        TourInputFieldInfo(
          name: 'Botón flotante (+)',
          dataType: 'Menú de 1 toque',
          description:
              'Registra aplicaciones, labores, incidencias o gastos en menos de 3 toques mientras camina la parcela.',
        ),
        TourInputFieldInfo(
          name: 'Alertas de revisión pendientes',
          dataType: 'Tarjetas de aviso',
          description:
              'Le avisa automáticamente cuando se cumple el plazo para evaluar la respuesta a un fertilizante.',
        ),
        TourInputFieldInfo(
          name: 'Garantía 100% Offline',
          dataType: 'Almacenamiento local seguro',
          description:
              'La aplicación no necesita señal ni internet. Todo se graba en su teléfono al instante y de forma segura.',
        ),
      ],
      agriculturalTip:
          '¡Felicitaciones! Ha completado la guía. Al presionar el botón inferior, la app quedará lista para que registre sus datos reales.',
    ),
  ];
}
