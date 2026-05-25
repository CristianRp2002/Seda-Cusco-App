class OperacionModel {
  final String id;
  final DateTime fechaFolio;
  final double totalizadorInicial;
  final double totalizadorFinal;
  final double produccionCalculada;
  final String interruptorLlegada10kvEstado;
  final double? transformadorTemperatura;
  final String estado;
  final int? cambiosRealizados;
  final EstacionResumen estacion;
  final List<OperadorModel> operadores;
  final List<DetalleBombeoModel> detallesBombeo;
  final LecturaModel lecturaInicial;
  final LecturaModel lecturaFinal;

  OperacionModel({
    required this.id,
    required this.fechaFolio,
    required this.totalizadorInicial,
    required this.totalizadorFinal,
    required this.produccionCalculada,
    required this.interruptorLlegada10kvEstado,
    this.transformadorTemperatura,
    this.estado = 'INICIAL',
    this.cambiosRealizados = 0,
    required this.estacion,
    required this.operadores,
    required this.detallesBombeo,
    required this.lecturaInicial,
    required this.lecturaFinal,
  });

  bool get esCompleto => estado == 'COMPLETO';

  factory OperacionModel.fromJson(Map<String, dynamic> json) {
    print('JSON OPERACION:');
    print(json);
    return OperacionModel(
      id: json['id']?.toString() ?? '',
      fechaFolio: DateTime.tryParse(json['fecha_folio']?.toString() ?? '') ?? DateTime.now(),
      totalizadorInicial: double.tryParse(json['totalizador_inicial']?.toString() ?? '0') ?? 0,
      totalizadorFinal: double.tryParse(json['totalizador_final']?.toString() ?? '0') ?? 0,
      produccionCalculada: double.tryParse(json['produccion_calculada']?.toString() ?? '0') ?? 0,
      interruptorLlegada10kvEstado: json['interruptor_llegada_10kv_estado']?.toString() ?? '',
      transformadorTemperatura: double.tryParse(json['transformador_temperatura']?.toString() ?? ''),
      estado: json['estado']?.toString() ?? 'INICIAL',
      cambiosRealizados: json['cambios_realizados']?.toInt() ?? 0,
      lecturaInicial: LecturaModel.fromJson(json['lectura_inicial']),
      lecturaFinal: LecturaModel.fromJson(json['lectura_final']),
      estacion: EstacionResumen.fromJson(json['estacion'] ?? {}),
      operadores: (json['operadores'] as List<dynamic>? ?? [])
          .map((o) => OperadorModel.fromJson(o))
          .toList(),
      detallesBombeo: (json['detallesBombeo'] as List<dynamic>? ?? [])
          .map((b) => DetalleBombeoModel.fromJson(b))
          .toList(),
    );
  }

  OperacionModel copyWith({
    String? id,
    DateTime? fechaFolio,
    double? totalizadorInicial,
    double? totalizadorFinal,
    double? produccionCalculada,
    String? interruptorLlegada10kvEstado,
    double? transformadorTemperatura,
    String? estado,
    int? cambiosRealizados,
    EstacionResumen? estacion,
    List<OperadorModel>? operadores,
    List<DetalleBombeoModel>? detallesBombeo,
    LecturaModel? lecturaInicial,
    LecturaModel? lecturaFinal,
  }) {
    return OperacionModel(
      id: id ?? this.id,
      fechaFolio: fechaFolio ?? this.fechaFolio,
      totalizadorInicial: totalizadorInicial ?? this.totalizadorInicial,
      totalizadorFinal: totalizadorFinal ?? this.totalizadorFinal,
      produccionCalculada: produccionCalculada ?? this.produccionCalculada,
      interruptorLlegada10kvEstado: interruptorLlegada10kvEstado ?? this.interruptorLlegada10kvEstado,
      transformadorTemperatura: transformadorTemperatura ?? this.transformadorTemperatura,
      estado: estado ?? this.estado,
      cambiosRealizados: cambiosRealizados ?? this.cambiosRealizados,
      estacion: estacion ?? this.estacion,
      operadores: operadores ?? this.operadores,
      detallesBombeo: detallesBombeo ?? this.detallesBombeo,
      lecturaInicial: lecturaInicial ?? this.lecturaInicial,
      lecturaFinal: lecturaFinal ?? this.lecturaFinal,
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
  final String? bombaId;
  final String? nombreBomba;
  final double horasBombeo;
  final DateTime? encendido;
  final DateTime? apagado;
  final double? horometroInicial;
  final double? horometroFinal;

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
      encendido: json['encendido'] != null
          ? DateTime.tryParse(json['encendido'].toString())
          : null,
      apagado: json['apagado'] != null
          ? DateTime.tryParse(json['apagado'].toString())
          : null,
      horometroInicial: double.tryParse(json['horometro_inicial']?.toString() ?? ''),
      horometroFinal: double.tryParse(json['horometro_final']?.toString() ?? ''),
    );
  }
}

class LecturaModel {
  final String? horaRegistro;
  final double? nivelCisterna;
  final double? presionLinea;
  final double? presionJatunHuaylla;
  final double? totalizador;

  LecturaModel({
    this.horaRegistro,
    this.nivelCisterna,
    this.presionLinea,
    this.presionJatunHuaylla,
    this.totalizador,
  });

  factory LecturaModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return LecturaModel();
    }

    return LecturaModel(
      horaRegistro: json['hora_registro']?.toString(),
      nivelCisterna: double.tryParse(
        json['nivel_cisterna']?.toString() ?? '',
      ),
      presionLinea: double.tryParse(
        json['presion_linea']?.toString() ?? '',
      ),
      presionJatunHuaylla: double.tryParse(
        json['presion_jatun_huaylla']?.toString() ?? '',
      ),
      totalizador: double.tryParse(
        json['totalizador']?.toString() ?? '',
      ),
    );
  }
}
