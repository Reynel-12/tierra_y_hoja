import 'package:flutter/widgets.dart';

import '../../../core/database/row_reader.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/utils/choice_option.dart';

/// Unidad de medida para el área del lote/parcela.
enum AreaUnit implements ChoiceOption {
  manzanas('Manzanas', 'mz', AppIcons.ruler),
  tareas('Tareas', 'tareas', AppIcons.ruler),
  hectareas('Hectáreas', 'ha', AppIcons.ruler),
  metrosCuadrados('Metros cuadrados', 'm²', AppIcons.ruler);

  const AreaUnit(this.label, this.symbol, this.icon);

  @override
  final String label;

  final String symbol;

  @override
  final IconData icon;
}

/// Textura del suelo del lote.
enum SoilTexture implements ChoiceOption {
  arcilloso('Arcilloso', AppIcons.tree),
  arenoso('Arenoso', AppIcons.waves),
  franco('Franco', AppIcons.tree),
  francoArcilloso('Franco-arcilloso', AppIcons.tree),
  pedregoso('Pedregoso', AppIcons.grains);

  const SoilTexture(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Topografía del terreno.
enum Topography implements ChoiceOption {
  plano('Plano', AppIcons.waves),
  laderaSuave('Ladera suave', AppIcons.trendUp),
  laderaInclinada('Ladera inclinada', AppIcons.trendUp);

  const Topography(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Acceso a agua para el lote.
enum WaterAccess implements ChoiceOption {
  riegoGoteo('Riego por goteo', AppIcons.water),
  aspersion('Aspersión', AppIcons.sprayBottle),
  canalGravedad('Canal / gravedad', AppIcons.waves),
  temporalLluvia('Temporal (lluvia)', AppIcons.climate);

  const WaterAccess(this.label, this.icon);

  @override
  final String label;

  @override
  final IconData icon;
}

/// Entidad inmutable que representa una parcela o lote de tierra.
class Plot {
  const Plot({
    this.id,
    required this.name,
    required this.area,
    required this.areaUnit,
    this.latitude,
    this.longitude,
    this.soilTexture,
    this.topography,
    this.waterAccess,
    this.previousCrops,
    this.photoPath,
    required this.createdAt,
    required this.updatedAt,
    this.activeCropName,
  });

  final int? id;
  final String name;
  final double area;
  final AreaUnit areaUnit;
  final double? latitude;
  final double? longitude;
  final SoilTexture? soilTexture;
  final Topography? topography;
  final WaterAccess? waterAccess;
  final String? previousCrops;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Nombre del cultivo activo si tiene uno abierto (para la tarjeta de parcela).
  final String? activeCropName;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get areaDisplay => '${area == area.roundToDouble() ? area.toInt() : area} ${areaUnit.label}';

  factory Plot.fromRow(Map<String, Object?> row, {String? activeCropName}) {
    return Plot(
      id: row.integerOrNull('id'),
      name: row.text('name'),
      area: row.decimal('area'),
      areaUnit: enumFromName(AreaUnit.values, row['area_unit'], AreaUnit.manzanas),
      latitude: row.decimalOrNull('latitude'),
      longitude: row.decimalOrNull('longitude'),
      soilTexture: enumFromNameOrNull(SoilTexture.values, row['soil_texture']),
      topography: enumFromNameOrNull(Topography.values, row['topography']),
      waterAccess: enumFromNameOrNull(WaterAccess.values, row['water_access']),
      previousCrops: row.textOrNull('previous_crops'),
      photoPath: row.textOrNull('photo_path'),
      createdAt: row.date('created_at'),
      updatedAt: row.date('updated_at'),
      activeCropName: activeCropName,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'area': area,
      'area_unit': areaUnit.name,
      'latitude': latitude,
      'longitude': longitude,
      'soil_texture': soilTexture?.name,
      'topography': topography?.name,
      'water_access': waterAccess?.name,
      'previous_crops': previousCrops,
      'photo_path': photoPath,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Plot copyWith({
    int? id,
    String? name,
    double? area,
    AreaUnit? areaUnit,
    double? latitude,
    double? longitude,
    SoilTexture? soilTexture,
    Topography? topography,
    WaterAccess? waterAccess,
    String? previousCrops,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? activeCropName,
  }) {
    return Plot(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      soilTexture: soilTexture ?? this.soilTexture,
      topography: topography ?? this.topography,
      waterAccess: waterAccess ?? this.waterAccess,
      previousCrops: previousCrops ?? this.previousCrops,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeCropName: activeCropName ?? this.activeCropName,
    );
  }
}
