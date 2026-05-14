class OperacionModel {
  final String id;
  final DateTime fechaFolio;
  final double totalizadorInicial;
  final double totalizadorFinal;
  final double produccionCalculada;
  final String interruptorLlegada10kvEstado;
  final double? transformadorTemperatura;
  final EstacionResumen estacion;
  final List<OperadorModel> operadores;
  final List<DetalleBombeoModel> detallesBombeo;

  OperacionModel({
    required this.id,
    required this.fechaFolio,
    required this.totalizadorInicial,
    required this.totalizadorFinal,
    required this.produccionCalculada,
    required this.interruptorLlegada10kvEstado,
    this.transformadorTemperatura,
    required this.estacion,
    required this.operadores,
    required this.detallesBombeo,
  });

  factory OperacionModel.fromJson(Map<String, dynamic> json) {
    return OperacionModel(
      id: json['id']?.toString() ?? '',
      fechaFolio: DateTime.tryParse(json['fecha_folio']?.toString() ?? '') ?? DateTime.now(),
      totalizadorInicial: double.tryParse(json['totalizador_inicial']?.toString() ?? '0') ?? 0,
      totalizadorFinal: double.tryParse(json['totalizador_final']?.toString() ?? '0') ?? 0,
      produccionCalculada: double.tryParse(json['produccion_calculada']?.toString() ?? '0') ?? 0,
      interruptorLlegada10kvEstado: json['interruptor_llegada_10kv_estado']?.toString() ?? '',
      transformadorTemperatura: double.tryParse(json['transformador_temperatura']?.toString() ?? ''),
      estacion: EstacionResumen.fromJson(json['estacion'] ?? {}),
      operadores: (json['operadores'] as List<dynamic>? ?? [])
          .map((o) => OperadorModel.fromJson(o))
          .toList(),
      detallesBombeo: (json['detallesBombeo'] as List<dynamic>? ?? [])
          .map((b) => DetalleBombeoModel.fromJson(b))
          .toList(),
    );
  }
}

class EstacionResumen {
  final String id;
  final String nombre;

  EstacionResumen({required this.id, required this.nombre});

  factory EstacionResumen.fromJson(Map<String, dynamic> json) {
    return EstacionResumen(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
    );
  }
}

class OperadorModel {
  final String nombreOperador;
  final String turno;

  OperadorModel({required this.nombreOperador, required this.turno});

  factory OperadorModel.fromJson(Map<String, dynamic> json) {
    return OperadorModel(
      nombreOperador: json['nombre_operador']?.toString() ?? '',
      turno: json['turno']?.toString() ?? '',
    );
  }
}

class DetalleBombeoModel {
  final String? bombaId;        // ← nuevo
  final String? nombreBomba;
  final double horasBombeo;
  final String? encendido;      // ← nuevo
  final String? apagado;        // ← nuevo
  final double? horometroInicial; // ← nuevo
  final double? horometroFinal;   // ← nuevo

  DetalleBombeoModel({
    this.bombaId,
    this.nombreBomba,
    required this.horasBombeo,
    this.encendido,
    this.apagado,
    this.horometroInicial,
    this.horometroFinal,
  });

  factory DetalleBombeoModel.fromJson(Map<String, dynamic> json) {
    return DetalleBombeoModel(
      bombaId: json['bomba']?['id']?.toString(),
      nombreBomba: json['bomba']?['nombre']?.toString(),
      horasBombeo: double.tryParse(json['horas_bombeo']?.toString() ?? '0') ?? 0,
      encendido: json['encendido']?.toString(),
      apagado: json['apagado']?.toString(),
      horometroInicial: double.tryParse(json['horometro_inicial']?.toString() ?? ''),
      horometroFinal: double.tryParse(json['horometro_final']?.toString() ?? ''),
    );
  }
}