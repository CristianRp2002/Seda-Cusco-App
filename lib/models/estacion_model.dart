class CampoModel {
  final String id;
  final String nombreCampo;
  final String etiqueta;
  final String tipoInput;
  final bool requerido;
  final int orden;
  final String? unidad;
  final Map<String, dynamic>? config;

  CampoModel({
    required this.id,
    required this.nombreCampo,
    required this.etiqueta,
    required this.tipoInput,
    required this.requerido,
    required this.orden,
    this.unidad,
    this.config,
  });

  factory CampoModel.fromJson(Map<String, dynamic> json) {
    return CampoModel(
      id: json['id'],
      nombreCampo: json['nombre_campo'],
      etiqueta: json['etiqueta'],
      tipoInput: json['tipo_input'],
      requerido: json['requerido'] ?? false,
      orden: json['orden'] ?? 0,
      unidad: json['unidad'],
      config: json['config'],
    );
  }
}

class TipoActivoModel {
  final String id;
  final String codigo;
  final String nombre;
  final List<CampoModel> campos;

  TipoActivoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.campos,
  });

  factory TipoActivoModel.fromJson(Map<String, dynamic> json) {
    return TipoActivoModel(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      campos: (json['campos'] as List)
          .map((c) => CampoModel.fromJson(c))
          .toList()
        ..sort((a, b) => a.orden.compareTo(b.orden)),
    );
  }
}

class ActivoModel {
  final String id;
  final String nombre;
  final bool activo;
  final TipoActivoModel tipoActivo;

  ActivoModel({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.tipoActivo,
  });

  factory ActivoModel.fromJson(Map<String, dynamic> json) {
    return ActivoModel(
      id: json['id'],
      nombre: json['nombre'] ?? 'Sin nombre',
      activo: json['activo'] ?? false,
      tipoActivo: TipoActivoModel.fromJson(json['tipoActivo']),
    );
  }
}

class BombaModel {
  final String id;
  final String nombre;
  final bool activa;
  final String numeroSerie;
  final double ultimoHorometro;

  BombaModel({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.numeroSerie,
    required this.ultimoHorometro,
  });

  factory BombaModel.fromJson(Map<String, dynamic> json) {
    return BombaModel(
      id: json['id'],
      nombre: json['nombre'],
      activa: json['activa'] ?? false,
      numeroSerie: json['numero_serie'] ?? '',
      ultimoHorometro: double.tryParse(json['ultimo_horometro'].toString()) ?? 0,
    );
  }
}

// ✅ NUEVO: Clase TableroModel
class TableroModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  TableroModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.activo,
  });

  factory TableroModel.fromJson(Map<String, dynamic> json) {
    return TableroModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activo: json['activo'] ?? false,
    );
  }
}

class EstacionModel {
  final String id;
  final String nombre;
  final List<BombaModel> bombas;
  final List<ActivoModel> activos;
  final List<TableroModel> tableros;
  final double? ultimoTotalizador;

  EstacionModel({
    required this.id,
    required this.nombre,
    required this.bombas,
    required this.activos,
    required this.tableros,
    this.ultimoTotalizador,
  });

  factory EstacionModel.fromJson(Map<String, dynamic> json) {
    return EstacionModel(
      id: json['id'],
      nombre: json['nombre'],
      bombas: (json['bombas'] as List)
          .map((b) => BombaModel.fromJson(b))
          .toList(),
      activos: (json['activos'] as List)
          .map((a) => ActivoModel.fromJson(a))
          .toList(),
      tableros: (json['tableros'] as List?)
          ?.map((t) => TableroModel.fromJson(t))
          .toList() ?? [],
      ultimoTotalizador: json['ultimo_totalizador'] != null
          ? double.tryParse(json['ultimo_totalizador'].toString())
          : null,
    );
  }
}