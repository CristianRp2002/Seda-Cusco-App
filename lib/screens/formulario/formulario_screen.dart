import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/estacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/operacion_service.dart';
import '../../models/operacion_model.dart';

class FormularioScreen extends StatefulWidget {
  final EstacionModel estacion;
  final OperacionModel? operacionExistente;
  const FormularioScreen({super.key, required this.estacion, this.operacionExistente,});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  final Map<String, String> _formData = {};
  final Map<String, TextEditingController> _controllers = {};

  bool _isLoading = false;
  int _currentStep = 0;
  int _turnoEditor = 1;
  final Set<int> _turnosBloqueados = {};
  bool _formInitialized = false;
  bool _isPrimerLlenado = true;

  TableroModel? _tableroSeleccionado;
  final Set<String> _bombasActivas = {};
  final List<BombaModel> _bombasExtra = [];
  int _nextBombaId = 1000;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final DateTime _fechaReferencia;

  // ─── Paleta
  static const Color _primary       = Color(0xFF0D47A1);
  static const Color _primaryLight  = Color(0xFF1565C0);
  static const Color _accent        = Color(0xFF00BCD4);
  static const Color _surface       = Color(0xFFF8FAFF);
  static const Color _cardBg        = Colors.white;
  static const Color _textPrimary   = Color(0xFF0A1628);
  static const Color _textSecondary = Color(0xFF5C6B8A);
  static const Color _border        = Color(0xFFDDE3F0);
  static const Color _success       = Color(0xFF00897B);
  static const Color _error         = Color(0xFFD32F2F);
  static const Color _nightColor    = Color(0xFF7B1FA2);
  static const Color _chipActive    = Color(0xFFE3F2FD);
  static const List<_StepInfo> _allSteps = [
    _StepInfo('Inspección',    Icons.manage_search_rounded,        'Verificación del sistema'),
    _StepInfo('Habilitación',  Icons.electrical_services_rounded,  'Tensiones y tableros'),
    _StepInfo('Lect. Inicial', Icons.play_circle_rounded,          'Valores al inicio'),
    _StepInfo('Bombas',        Icons.water_damage_rounded,         'Control de operación'),
    _StepInfo('Activos',       Icons.category_rounded,             'Equipos de estación'),
    _StepInfo('Lect. Final',   Icons.stop_circle_rounded,          'Valores al cierre'),
    _StepInfo('Desactivación', Icons.electrical_services_rounded,  'Equipos de estación'),
    _StepInfo('Operadores',    Icons.badge_rounded,                'Personal y producción'),
  ];

  // Índices que se ocultan en el primer llenado
  static const Set<int> _indicesOcultosEnPrimerLlenado = {5, 6};

  // ─── Getters dinámicos ────────────────────────────────────────────────────

  /// Pasos que se muestran según el modo actual
  List<_StepInfo> get _stepsVisibles {
    if (_isPrimerLlenado) {
      return [
        for (int i = 0; i < _allSteps.length; i++)
          if (!_indicesOcultosEnPrimerLlenado.contains(i)) _allSteps[i],
      ];
    }
    return _allSteps;
  }

  /// Mapea el índice visible → índice real en _allSteps
  int _indiceReal(int indiceVisible) {
    if (!_isPrimerLlenado) return indiceVisible;
    int real = 0;
    int visible = 0;
    while (real < _allSteps.length) {
      if (!_indicesOcultosEnPrimerLlenado.contains(real)) {
        if (visible == indiceVisible) return real;
        visible++;
      }
      real++;
    }
    return real;
  }

  /// Páginas del PageView en el orden correcto según el modo
  List<Widget> get _paginasVisibles {
    final todas = [
      _buildInspeccionStep(),
      _buildHabilitacion(),
      _buildLecturaInicialStep(),
      _buildBombasStep(),
      _buildActivosStep(),
      _buildLecturaFinalStep(),
      _buildDesactivacion(),
      _buildOperadoresStep(),
    ];
    if (_isPrimerLlenado) {
      return [
        for (int i = 0; i < todas.length; i++)
          if (!_indicesOcultosEnPrimerLlenado.contains(i)) todas[i],
      ];
    }
    return todas;
  }

  // ─── Lifecycle ───────
  @override
  void initState() {
    super.initState();
    _fechaReferencia = DateTime.now();
    final tableros = widget.estacion.tableros ?? [];
    if (tableros.isNotEmpty) _tableroSeleccionado = tableros.first;

    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_formInitialized) {
      _initializeFormData();
      _formInitialized = true;
    }
  }

  void _initializeFormData() {
    final op = widget.operacionExistente;
    if (op != null) {
      _isPrimerLlenado = false;

      // Paso 0 — Inspección
      _formData['INTERRUPTOR_10KV_ESTADO'] = op.interruptorLlegada10kvEstado;
      if (op.transformadorTemperatura != null) {
        _formData['TRANSFORMADOR_TEMPERATURA'] =
            op.transformadorTemperatura!.toString();
      }

      // Paso 2 — Lectura inicial (todos los campos)
      _formData['TOTALIZADOR_INICIAL'] = op.totalizadorInicial.toString();
      if (op.lecturaInicial.horaRegistro != null) {
        _formData['HORA_INICIAL'] = op.lecturaInicial.horaRegistro!;
        try {
          final dt = DateTime.parse(op.lecturaInicial.horaRegistro!);
          _formData['HORA_INICIAL_DISPLAY'] =
          '${dt.day.toString().padLeft(2, '0')}/'
              '${dt.month.toString().padLeft(2, '0')}/'
              '${dt.year}  '
              '${dt.hour.toString().padLeft(2, '0')}:'
              '${dt.minute.toString().padLeft(2, '0')}';
          _getController('HORA_INICIAL').text = _formData['HORA_INICIAL_DISPLAY']!;
        } catch (_) {
          _getController('HORA_INICIAL').text = op.lecturaInicial.horaRegistro!;
        }
      }
      if (op.lecturaInicial.nivelCisterna != null) {
        _formData['NIVEL_CISTERNA_INICIAL'] =
            op.lecturaInicial.nivelCisterna!.toString();
      }
      if (op.lecturaInicial.presionLinea != null) {
        _formData['PRESION_LINEA_INICIAL'] =
            op.lecturaInicial.presionLinea!.toString();
      }
      if (op.lecturaInicial.presionJatunHuaylla != null) {
        _formData['PRESION_JATUN_HUAYLLA_INICIAL'] =
            op.lecturaInicial.presionJatunHuaylla!.toString();
      }
      if (op.lecturaInicial.totalizador != null) {
        _formData['TOTALIZADOR_INICIAL'] =
            op.lecturaInicial.totalizador!.toString();
      }

      // Paso 5 — Lectura final (todos los campos)
      if (op.totalizadorFinal != 0) {
        _formData['TOTALIZADOR_FINAL'] = op.totalizadorFinal.toString();
      }
      if (op.lecturaFinal.horaRegistro != null) {
        _formData['HORA_FINAL'] = op.lecturaFinal.horaRegistro!;
        try {
          final dt = DateTime.parse(op.lecturaFinal.horaRegistro!);
          _formData['HORA_FINAL_DISPLAY'] =
          '${dt.day.toString().padLeft(2, '0')}/'
              '${dt.month.toString().padLeft(2, '0')}/'
              '${dt.year}  '
              '${dt.hour.toString().padLeft(2, '0')}:'
              '${dt.minute.toString().padLeft(2, '0')}';
          _getController('HORA_FINAL').text = _formData['HORA_FINAL_DISPLAY']!;
        } catch (_) {
          _getController('HORA_FINAL').text = op.lecturaFinal.horaRegistro!;
        }
      }
      if (op.lecturaFinal.nivelCisterna != null) {
        _formData['NIVEL_CISTERNA_FINAL'] =
            op.lecturaFinal.nivelCisterna!.toString();
      }
      if (op.lecturaFinal.presionLinea != null) {
        _formData['PRESION_LINEA_FINAL'] =
            op.lecturaFinal.presionLinea!.toString();
      }
      if (op.lecturaFinal.presionJatunHuaylla != null) {
        _formData['PRESION_JATUN_HUAYLLA_FINAL'] =
            op.lecturaFinal.presionJatunHuaylla!.toString();
      }
      if (op.lecturaFinal.totalizador != null) {
        _formData['TOTALIZADOR_FINAL'] =
            op.lecturaFinal.totalizador!.toString();
      }

      // Paso 7 — Operadores
      for (int i = 0; i < op.operadores.length; i++) {
        _formData['OPERADOR_TURNO_${i + 1}'] = op.operadores[i].nombreOperador;
      }
    }

    // Horómetros por defecto
    for (var bomba in (widget.estacion.bombas ?? [])) {
      _formData.putIfAbsent(
        'bomba_${bomba.id}_horometro_inicial',
            () => bomba.ultimoHorometro.toString(),
      );
    }

    // Bombas existentes
    if (op != null) {
      for (final detalle in op.detallesBombeo) {
        final id = detalle.bombaId;
        if (id == null) continue;
        _bombasActivas.add(id);
        if (detalle.encendido != null) {
          final enc = detalle.encendido!;
          final horaEnc = '${enc.hour.toString().padLeft(2, '0')}:${enc.minute.toString().padLeft(2, '0')}';

          _formData['bomba_${id}_encendido'] = horaEnc;          // ← para mostrar y validar
          _formData['bomba_${id}_encendido_iso'] = detalle.encendido!.toIso8601String(); // ← para enviar
          _getController('bomba_${id}_encendido').text = horaEnc;
        }
        if (detalle.apagado != null) {
          final apa = detalle.apagado!;
          final horaApa = '${apa.hour.toString().padLeft(2, '0')}:${apa.minute.toString().padLeft(2, '0')}';

          _formData['bomba_${id}_apagado'] = horaApa;
          _formData['bomba_${id}_apagado_iso'] = detalle.apagado!.toIso8601String();
          _getController('bomba_${id}_apagado').text = horaApa;
        }
        if (detalle.horometroInicial != null) {
          _formData['bomba_${id}_horometro_inicial'] =
              detalle.horometroInicial!.toString();
        }
        if (detalle.horometroFinal != null) {
          _formData['bomba_${id}_horometro_final'] =
              detalle.horometroFinal!.toString();
        }
      }
    }
    for (var tablero in (widget.estacion.tableros ?? [])) {
      for (final momento in ['HABILITACION', 'DESACTIVACION']) {
        final prefix = 'tablero_${tablero.id}_$momento';
        for (final campo in ['interruptor', 'selector', 'parada', 'variador', 'alarma']) {
          _formData.putIfAbsent('${prefix}_$campo', () => 'OK');
        }
      }
    }
    final user = context.read<AuthProvider>().user;
    for (int i = 1; i <= 3; i++) {
      if (i == _turnoEditor && user != null &&
          (_formData['OPERADOR_TURNO_$i']?.isEmpty ?? true)) {
        _formData['OPERADOR_TURNO_$i'] = user.nombreCompleto;
        _turnosBloqueados.add(i);
      }
    }
  }

  TextEditingController _getController(String key) {
    return _controllers.putIfAbsent(
        key, () => TextEditingController(text: _formData[key] ?? ''));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  List<BombaModel> get _todasLasBombas =>
      [...(widget.estacion.bombas ?? []), ..._bombasExtra];

  List<BombaModel> get _bombasSeleccionadas =>
      _todasLasBombas.where((b) => _bombasActivas.contains(b.id.toString())).toList();

  void _toggleBomba(dynamic id) {
    final key = id.toString();
    setState(() => _bombasActivas.contains(key)
        ? _bombasActivas.remove(key)
        : _bombasActivas.add(key));
  }

  void _mostrarDialogoNuevaBomba() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nueva bomba',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: _textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nombre de la bomba',
            hintText: 'Ej. Bomba Sur',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final nombre = ctrl.text.trim();
              if (nombre.isNotEmpty) {
                setState(() {
                  final b = BombaModel(id: _nextBombaId.toString(), nombre: nombre, activa: true, numeroSerie: '', ultimoHorometro: 0);
                  _bombasExtra.add(b);
                  _bombasActivas.add(b.id.toString());
                  _nextBombaId++;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }
    if (_currentStep < _stepsVisibles.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
      _fadeController..reset()..forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
      _fadeController..reset()..forward();
    }
  }
  void _toggleModo() {
    final hayDatos = _formData.values.any((v) => v.isNotEmpty);
    if (hayDatos && _currentStep > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cambiar modo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: _textPrimary)),
          content: Text(
            _isPrimerLlenado
                ? 'Pasarás al modo completo. Los datos ingresados se conservan.'
                : 'Pasarás al modo primer turno. Los pasos de Lectura Final y Desactivación quedarán ocultos.',
            style: const TextStyle(fontSize: 14, color: _textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _aplicarCambioModo();
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
    } else {
      _aplicarCambioModo();
    }
  }

  void _aplicarCambioModo() {
    setState(() {
      _isPrimerLlenado = !_isPrimerLlenado;
      _currentStep = 0;
      _pageController.jumpToPage(0);
    });
  }

  // ─── Validación ───
  String? _validateCurrentStep() {
    final realIndex = _indiceReal(_currentStep);
    switch (realIndex) {
      case 0:
        if (_formData['INTERRUPTOR_10KV_ESTADO']?.isEmpty ?? true) {
          return 'Seleccione el estado del interruptor de llegada 10kV';
        }
        if (_formData['TRANSFORMADOR_TEMPERATURA']?.isEmpty ?? true) {
          return 'Ingrese la temperatura del transformador';
        }
        if (double.tryParse(_formData['TRANSFORMADOR_TEMPERATURA'] ?? '') == null) {
          return 'La temperatura debe ser un número válido';
        }
        return null;

      case 1:
        for (var tablero in (widget.estacion.tableros ?? [])) {
          for (final momento in ['HABILITACION', 'DESACTIVACION']) {
            final prefix = 'tablero_${tablero.id}_$momento';
            for (final campo in ['interruptor', 'selector', 'parada', 'variador', 'alarma']) {
              if (_formData['${prefix}_$campo']?.isEmpty ?? true) {
                return 'Complete el estado de todos los tableros (${tablero.nombre} - $momento)';
              }
            }
          }
        }
        return null;

      case 2:
        for (final k in ['NIVEL_CISTERNA_INICIAL', 'PRESION_LINEA_INICIAL',
          'TOTALIZADOR_INICIAL', 'PRESION_JATUN_HUAYLLA_INICIAL']) {
          final v = _formData[k];
          if (v == null || v.trim().isEmpty) return 'Complete todos los campos de lectura inicial';
          if (double.tryParse(v) == null) return 'Todos los valores deben ser números válidos';
        }
        return null;

      case 3:
        if (_bombasSeleccionadas.isEmpty) {
          return 'Seleccione al menos una bomba para registrar';
        }
        for (final bomba in _bombasSeleccionadas) {
          final enc    = _formData['bomba_${bomba.id}_encendido'];
          final apa    = _formData['bomba_${bomba.id}_apagado'];
          final horIni = _formData['bomba_${bomba.id}_horometro_inicial'];
          final horFin = _formData['bomba_${bomba.id}_horometro_final'];

          if (enc == null || enc.isEmpty) return 'Ingrese hora de encendido de ${bomba.nombre}';
          if (apa == null || apa.isEmpty) return 'Ingrese hora de apagado de ${bomba.nombre}';

          final partsEnc = enc.split(':');
          final partsApa = apa.split(':');
          final minEnc   = int.parse(partsEnc[0]) * 60 + int.parse(partsEnc[1]);
          final minApa   = int.parse(partsApa[0]) * 60 + int.parse(partsApa[1]);
          final esDiaSig = _formData['bomba_${bomba.id}_apagado_siguiente_dia'] == '1';

          if (!esDiaSig && minApa <= minEnc) {
            return 'Hora de apagado debe ser posterior al encendido en ${bomba.nombre}';
          }
          if (horIni == null || horIni.isEmpty) return 'Ingrese horómetro inicial de ${bomba.nombre}';
          if (horFin == null || horFin.isEmpty) return 'Ingrese horómetro final de ${bomba.nombre}';
          if (double.tryParse(horIni) == null) return 'Horómetro inicial inválido en ${bomba.nombre}';
          if (double.tryParse(horFin) == null) return 'Horómetro final inválido en ${bomba.nombre}';
          if (double.parse(horFin) < double.parse(horIni)) {
            return 'Horómetro final debe ser mayor al inicial en ${bomba.nombre}';
          }
        }
        return null;

      case 4:
        for (var activo in (widget.estacion.activos ?? []).where((a) => a.activo)) {
          for (var campo in activo.tipoActivo.campos.where((c) => c.requerido)) {
            final key = 'activo_${activo.id}_campo_${campo.id}';
            if (_formData[key]?.trim().isEmpty ?? true) {
              return 'Complete el campo "${campo.nombreCampo}" en ${activo.nombre}';
            }
          }
        }
        return null;

      case 5:
        for (final k in ['NIVEL_CISTERNA_FINAL', 'PRESION_LINEA_FINAL',
          'TOTALIZADOR_FINAL', 'PRESION_JATUN_HUAYLLA_FINAL']) {
          final v = _formData[k];
          if (v == null || v.trim().isEmpty) return 'Complete todos los campos de lectura final';
          if (double.tryParse(v) == null) return 'Todos los valores deben ser números válidos';
        }
        final totIni = double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '');
        final totFin = double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '');
        if (totIni != null && totFin != null && totFin < totIni) {
          return 'El totalizador final debe ser mayor al inicial';
        }
        return null;

      case 6:
      // Desactivación — sin validación obligatoria
        return null;

      case 7:
        final op1 = _formData['OPERADOR_TURNO_1'];
        if (op1 == null || op1.trim().isEmpty) return 'El operador del turno 1 es obligatorio';
        final soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
        for (int i = 1; i <= 3; i++) {
          final nombre = _formData['OPERADOR_TURNO_$i'];
          if (nombre != null && nombre.isNotEmpty && !soloLetras.hasMatch(nombre.trim())) {
            return 'El nombre del operador $i solo puede contener letras';
          }
        }
        return null;

      default:
        return null;
    }
  }
  String _horaAIso(String? horaHHmm, {bool esSiguienteDia = false}) {
    if (horaHHmm == null || horaHHmm.isEmpty) return '';
    final parts = horaHHmm.split(':');
    if (parts.length < 2) return '';
    final hora = int.tryParse(parts[0]) ?? 0;
    final min  = int.tryParse(parts[1]) ?? 0;
    final fecha = esSiguienteDia
        ? DateTime(_fechaReferencia.year, _fechaReferencia.month,
        _fechaReferencia.day + 1, hora, min)
        : DateTime(_fechaReferencia.year, _fechaReferencia.month,
        _fechaReferencia.day, hora, min);
    return fecha.toIso8601String();
  }

  // ─── Guardar
  Future<void> _guardar() async {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token!;

      final operadores = <Map<String, dynamic>>[];
      for (int i = 1; i <= 3; i++) {
        final nombre = _formData['OPERADOR_TURNO_$i'];
        if (nombre != null && nombre.trim().isNotEmpty) {
          operadores.add({'nombre_operador': nombre.trim(), 'numero_turno': i});
        }
      }

      final bombeos = <Map<String, dynamic>>[];
      for (final bomba in _bombasSeleccionadas) {
        final encendido = _formData['bomba_${bomba.id}_encendido'];
        final apagado   = _formData['bomba_${bomba.id}_apagado'];
        final horIni    = _formData['bomba_${bomba.id}_horometro_inicial'];
        final horFin    = _formData['bomba_${bomba.id}_horometro_final'];
        final encIso = _formData['bomba_${bomba.id}_encendido_iso']
            ?? _horaAIso(encendido, esSiguienteDia: false);
        final apaIso = _formData['bomba_${bomba.id}_apagado_iso']
            ?? _horaAIso(apagado, esSiguienteDia:
            _formData['bomba_${bomba.id}_apagado_siguiente_dia'] == '1');
        if (encendido != null && apagado != null) {
          bombeos.add({
            'bomba_id':          bomba.id,
            'encendido':         encendido,
            'apagado':           apagado,
            'horometro_inicial': horIni != null ? double.tryParse(horIni) : null,
            'horometro_final':   horFin != null ? double.tryParse(horFin) : null,
            'observacion':       _formData['bomba_${bomba.id}_observacion'],
          });
        }
      }

      final tableros = <Map<String, dynamic>>[];
      for (final tablero in (widget.estacion.tableros ?? [])) {
        for (final momento in ['HABILITACION', 'DESACTIVACION']) {
          final prefix = 'tablero_${tablero.id}_$momento';
          tableros.add({
            'tablero_id':               tablero.id,
            'momento':                  momento,
            'interruptor_estado':       _formData['${prefix}_interruptor'] ?? '',
            'selector_estado':          _formData['${prefix}_selector']    ?? '',
            'parada_emergencia_estado': _formData['${prefix}_parada']      ?? '',
            'variador_estado':          _formData['${prefix}_variador']    ?? '',
            'alarma_estado':            _formData['${prefix}_alarma']      ?? '',
          });
        }
      }

      final registrosActivo = <Map<String, dynamic>>[];
      for (var activo in (widget.estacion.activos ?? []).where((a) => a.activo)) {
        for (var campo in activo.tipoActivo.campos) {
          final key   = 'activo_${activo.id}_campo_${campo.id}';
          final valor = _formData[key];
          if (valor != null && valor.trim().isNotEmpty) {
            registrosActivo.add({
              'activo_id': activo.id,
              'campo_id':  campo.id,
              'valor':     valor.trim(),
            });
          }
        }
      }

      final payload = <String, dynamic>{
        'estacion_id':       widget.estacion.id.toString(),
        'fecha_folio': DateTime.now().toIso8601String().substring(0, 10),
        'interruptor_llegada_10kv_estado': _formData['INTERRUPTOR_10KV_ESTADO'] ?? '',
        'transformador_temperatura':
        double.tryParse(_formData['TRANSFORMADOR_TEMPERATURA'] ?? ''),
        'tension_llegada': {
          'fase_R': double.tryParse(_formData['LLEGADA_FASE_R'] ?? ''),
          'fase_S': double.tryParse(_formData['LLEGADA_FASE_S'] ?? ''),
          'fase_T': double.tryParse(_formData['LLEGADA_FASE_T'] ?? ''),
        },
        'tension_tablero': {
          'fase_R': double.tryParse(_formData['TABLERO_FASE_R'] ?? ''),
          'fase_S': double.tryParse(_formData['TABLERO_FASE_S'] ?? ''),
          'fase_T': double.tryParse(_formData['TABLERO_FASE_T'] ?? ''),
        },
        'totalizador_inicial':
        double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '0') ?? 0.0,
        'lectura_inicial': {
          'hora_registro': _formData['HORA_INICIAL']?.isNotEmpty == true
              ? _formData['HORA_INICIAL']
              : null,
          'nivel_cisterna':        double.tryParse(_formData['NIVEL_CISTERNA_INICIAL'] ?? ''),
          'presion_linea':         double.tryParse(_formData['PRESION_LINEA_INICIAL'] ?? ''),
          'totalizador':           double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? ''),
          'presion_jatun_huaylla': double.tryParse(_formData['PRESION_JATUN_HUAYLLA_INICIAL'] ?? ''),
        },
        'totalizador_final':
        double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '0') ?? 0.0,
        'nivel_cisterna_final': double.tryParse(_formData['NIVEL_CISTERNA_FINAL'] ?? ''),
        'presion_linea_final':  double.tryParse(_formData['PRESION_LINEA_FINAL'] ?? ''),
        'lectura_final': {
          'hora_registro': _formData['HORA_FINAL']?.isNotEmpty == true
              ? _formData['HORA_FINAL']
              : null,
          'nivel_cisterna':        double.tryParse(_formData['NIVEL_CISTERNA_FINAL'] ?? ''),
          'presion_linea':         double.tryParse(_formData['PRESION_LINEA_FINAL'] ?? ''),
          'totalizador':           double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? ''),
          'presion_jatun_huaylla': double.tryParse(_formData['PRESION_JATUN_HUAYLLA_FINAL'] ?? ''),
        },
        'condicion_habilitacion': {
          'estado_telemetria': _formData['HABILITACION_ESTADO_TELEMETRIA'],
          'presion_ingreso':   double.tryParse(_formData['HABILITACION_PRESION_INGRESO'] ?? ''),
        },
        'condicion_desactivacion': {
          'estado_telemetria': _formData['DESACTIVACION_ESTADO_TELEMETRIA'],
          'presion_ingreso':   double.tryParse(_formData['DESACTIVACION_PRESION_INGRESO'] ?? ''),
        },
        'operadores':       operadores,
        'bombeos':          bombeos,
        'tableros':         tableros,
        if (registrosActivo.isNotEmpty) 'registros_activo': registrosActivo,
      };

      if (widget.operacionExistente != null) {

        final operacionActualizada = await OperacionService.updateOperacion(
          token: token,
          operacionId: widget.operacionExistente!.id,
          payload: payload,
        );

        if (!mounted) return;

        if (operacionActualizada != null) {
          _showSnackbar('✓ Registro actualizado correctamente');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context, operacionActualizada);
          }
        } else {
          _showSnackbar('Error al actualizar el registro', isError: true);
        }
      } else {
        // ✅ CREACIÓN - Crear nueva operación
        final result = await OperacionService.registrar(token: token, payload: payload);
        if (!mounted) return;

        if (result['success'] == true) {
          _showSnackbar('✓ Registro guardado correctamente');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) Navigator.pop(context);
        } else {
          _showSnackbar(result['message']?.toString() ?? 'Error al guardar', isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error: ${e.toString()}', isError: true);
      debugPrint('❌ Error en _guardar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? _error : _success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 6,
    ));
  }

  // ─── Build ───
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        _buildStepper(),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _paginasVisibles,
            ),
          ),
        ),
        _buildBottomBar(),
      ]),
    );
  }

  // ─── Header ──
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [_primary, _primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
          child: Row(children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Registro de Operación',
                    style: TextStyle(color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(widget.estacion.nombre,
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ]),
            ),
            // ── Toggle primer llenado / completo ──────────────────────────
            GestureDetector(
              onTap: () {
                setState(() {
                  _isPrimerLlenado = !_isPrimerLlenado;
                  if (_currentStep >= _stepsVisibles.length) {
                    _currentStep = _stepsVisibles.length - 1;
                  }
                  _pageController.jumpToPage(_currentStep);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _isPrimerLlenado
                        ? Colors.white.withOpacity(0.2)
                        : _accent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isPrimerLlenado
                            ? Colors.white.withOpacity(0.4)
                            : _accent,
                        width: 1.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _isPrimerLlenado ? Icons.first_page_rounded : Icons.all_inclusive_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isPrimerLlenado ? '1° turno' : 'Completo',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_currentStep + 1} / ${_stepsVisibles.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Stepper ─
  Widget _buildStepper() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _stepsVisibles.length,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: List.generate(_stepsVisibles.length, (i) {
                final isActive = i == _currentStep;
                final isDone   = i < _currentStep;
                return GestureDetector(
                  onTap: isDone
                      ? () {
                    setState(() => _currentStep = i);
                    _pageController.animateToPage(i,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut);
                  }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 6, bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : isDone
                          ? Colors.white.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.white
                            : isDone
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          isDone ? Icons.check_circle_rounded : _stepsVisibles[i].icon,
                          size: 14,
                          color: isActive
                              ? _primary
                              : Colors.white.withOpacity(isDone ? 0.9 : 0.5)),
                      const SizedBox(width: 5),
                      Text(_stepsVisibles[i].title,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              color: isActive
                                  ? _primary
                                  : Colors.white.withOpacity(isDone ? 0.9 : 0.5))),
                    ]),
                  ),
                );
              })),
        ),
      ]),
    );
  }

  // ─── Contenedor de paso
  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(color: _primary.withOpacity(0.06), blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primary, _primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                        color: _textPrimary, letterSpacing: -0.3)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: _textSecondary)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  // ─── Campo de texto ────
  Widget _buildField({
    required String label,
    required String key,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
    bool optional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textPrimary, letterSpacing: 0.1)),
          if (optional)
            const Text('  (opcional)',
                style: TextStyle(fontSize: 11, color: _textSecondary)),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: _getController(key),
          initialValue: null,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: readOnly ? _textSecondary : _textPrimary,
            fontWeight: FontWeight.w500,
          ),
          onChanged: readOnly ? null : (v) => _formData[key] = v,
          decoration: InputDecoration(
            hintText: hint ?? 'Ingrese $label',
            hintStyle: const TextStyle(color: Color(0xFFB0BAD3), fontSize: 14),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: _textSecondary,
                fontWeight: FontWeight.w600, fontSize: 13),
            prefixIcon: icon != null
                ? Icon(icon, size: 19,
                color: readOnly ? _textSecondary : _primary.withOpacity(0.7))
                : null,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF0F2F8) : _cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: readOnly ? _border : _primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ]),
    );
  }

  // ─── Campo de hora ─────
  Widget _buildTimeField({
    required String label,
    required String key,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final hasValue = (_formData[key]?.isNotEmpty ?? false);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: _textSecondary, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: hasValue ? iconColor.withOpacity(0.06) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: hasValue ? iconColor.withOpacity(0.4) : _border,
                width: hasValue ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: hasValue
                  ? Text(_getController(key).text,
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700, color: _textPrimary))
                  : Text('Seleccionar',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ),
            Icon(Icons.access_time_rounded, size: 15, color: Colors.grey.shade400),
          ]),
        ),
      ),
    ]);
  }

  // ─── Selector de estado
  Widget _buildStatusSelector(String label, String key) {
    const options = ['OK', 'Defectuoso', 'Revisión'];
    final selected = _formData[key] ?? 'OK';
    final colors = {
      'OK':         _success,
      'Defectuoso': _error,
      'Revisión':   const Color(0xFFF57C00),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: _textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: options.map((opt) {
              final isSelected = selected == opt;
              final color = colors[opt]!;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _formData[key] = opt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: isSelected ? color : Colors.grey.shade200,
                            width: isSelected ? 2 : 1),
                      ),
                      child: Column(children: [
                        Icon(
                            opt == 'OK'
                                ? Icons.check_circle_rounded
                                : opt == 'Defectuoso'
                                ? Icons.cancel_rounded
                                : Icons.warning_rounded,
                            color: isSelected ? color : Colors.grey.shade400,
                            size: 20),
                        const SizedBox(height: 4),
                        Text(opt,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected ? color : Colors.grey.shade500)),
                      ]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  //  PASOS

  Widget _buildInspeccionStep() {
    return _buildStepContainer(
      title: 'Inspección del Sistema',
      subtitle: 'De Protección Sub Estación',
      icon: Icons.manage_search_rounded,
      children: [
        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.group_rounded, color: _primary, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Operadores de turno',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
          const SizedBox(height: 14),
          _buildField(label: 'Operador 1 *', key: 'OPERADOR_TURNO_1',
              icon: Icons.person_rounded,
              readOnly: _turnosBloqueados.contains(1)),
          _buildField(label: 'Operador 2', key: 'OPERADOR_TURNO_2',
              icon: Icons.person_outline_rounded, optional: true,
              readOnly: _turnosBloqueados.contains(2)),
          _buildField(label: 'Operador 3', key: 'OPERADOR_TURNO_3',
              icon: Icons.person_outline_rounded, optional: true,
              readOnly: _turnosBloqueados.contains(3)),
        ]),
        _buildCard(children: [
          const Text('Interruptor y transformador',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 12),
          _buildStatusSelector('Interruptor llegada 10kV', 'INTERRUPTOR_10KV_ESTADO'),
          _buildField(label: 'Temperatura transformador',
              key: 'TRANSFORMADOR_TEMPERATURA',
              icon: Icons.thermostat_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: '°C'),
        ]),
        _buildCard(children: [
          const Text('Tensión de llegada',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildField(label: 'Fase R', key: 'LLEGADA_FASE_R',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildField(label: 'Fase S', key: 'LLEGADA_FASE_S',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildField(label: 'Fase T', key: 'LLEGADA_FASE_T',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
          ]),
        ]),
        _buildCard(children: [
          const Text('Tensión en tablero',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _buildField(label: 'Fase R', key: 'TABLERO_FASE_R',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildField(label: 'Fase S', key: 'TABLERO_FASE_S',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
            const SizedBox(width: 8),
            Expanded(child: _buildField(label: 'Fase T', key: 'TABLERO_FASE_T',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                suffix: 'V', optional: true)),
          ]),
        ]),
      ],
    );
  }

  Widget _buildHabilitacion() {
    return _buildStepContainer(
      title: 'Habilitación de equipos',
      subtitle: 'Sala de Mandos',
      icon: Icons.electrical_services_rounded,
      children: [
        if ((widget.estacion.tableros ?? []).isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (widget.estacion.tableros ?? []).map((tablero) {
                final isSelected = _tableroSeleccionado?.id == tablero.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tablero.nombre),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _tableroSeleccionado = tablero),
                    selectedColor: _primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        if (_tableroSeleccionado != null)
          _buildCard(children: [
            Text(_tableroSeleccionado!.nombre,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 4),
            const Text('HABILITACIÓN',
                style: TextStyle(fontSize: 11, color: _textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStatusSelector('Interruptor',       'tablero_${_tableroSeleccionado!.id}_HABILITACION_interruptor'),
            _buildStatusSelector('Selector',          'tablero_${_tableroSeleccionado!.id}_HABILITACION_selector'),
            _buildStatusSelector('Parada emergencia', 'tablero_${_tableroSeleccionado!.id}_HABILITACION_parada'),
            _buildStatusSelector('Variador',          'tablero_${_tableroSeleccionado!.id}_HABILITACION_variador'),
            _buildStatusSelector('Alarma',            'tablero_${_tableroSeleccionado!.id}_HABILITACION_alarma'),
          ]),
        _buildCard(children: [
          const Text('Condición de habilitación',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 12),
          _buildField(label: 'Estado telemetría', key: 'HABILITACION_ESTADO_TELEMETRIA',
              icon: Icons.sensors_rounded, optional: true),
          _buildField(label: 'Presión de ingreso', key: 'HABILITACION_PRESION_INGRESO',
              icon: Icons.speed_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar', optional: true),
        ]),
      ],
    );
  }

  Widget _buildLecturaInicialStep() {
    return _buildStepContainer(
      title: 'Lectura Inicial',
      subtitle: 'Valores registrados al inicio del turno',
      icon: Icons.play_circle_rounded,
      children: [
        _buildCard(children: [
          _buildTimeField(
            label: 'Fecha y hora de registro',
            key: 'HORA_INICIAL',
            icon: Icons.access_time_rounded,
            iconColor: _primary,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('es', 'ES'),
              );
              if (pickedDate == null) return;
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (pickedTime == null) return;
              final formatted =
                  '${pickedDate.year}-'
                  '${pickedDate.month.toString().padLeft(2, '0')}-'
                  '${pickedDate.day.toString().padLeft(2, '0')}T'
                  '${pickedTime.hour.toString().padLeft(2, '0')}:'
                  '${pickedTime.minute.toString().padLeft(2, '0')}:00';
              setState(() {
                _formData['HORA_INICIAL'] = formatted;
                _getController('HORA_INICIAL').text = formatted;
              });
            },
          ),
          _buildField(label: 'Nivel cisterna', key: 'NIVEL_CISTERNA_INICIAL',
              icon: Icons.water_drop_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm'),
          _buildField(label: 'Presión línea', key: 'PRESION_LINEA_INICIAL',
              icon: Icons.speed_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
          _buildField(label: 'Totalizador', key: 'TOTALIZADOR_INICIAL',
              icon: Icons.analytics_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm³'),
          _buildField(label: 'Presión Jatun Huaylla', key: 'PRESION_JATUN_HUAYLLA_INICIAL',
              icon: Icons.compress_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
        ]),
      ],
    );
  }

  // ─── PASO BOMBAS
  Widget _buildBombasStep() {
    return _buildStepContainer(
      title: 'Control de Bombas',
      subtitle: 'Seleccioná las bombas que operaron este turno',
      icon: Icons.water_damage_rounded,
      children: [
        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.water_damage_rounded, color: _primary, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Bombas activas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const Spacer(),
            if (_bombasSeleccionadas.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _success.withOpacity(0.3))),
                child: Text('${_bombasSeleccionadas.length} seleccionada${_bombasSeleccionadas.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: _success,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._todasLasBombas.map((bomba) {
                final activa = _bombasActivas.contains(bomba.id);
                return GestureDetector(
                  onTap: () => _toggleBomba(bomba.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: activa ? _chipActive : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: activa ? _primary.withOpacity(0.6) : _border,
                        width: activa ? 1.5 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: activa ? _primary : _border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(bomba.nombre,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: activa ? FontWeight.w600 : FontWeight.w400,
                              color: activa ? _primary : _textSecondary)),
                    ]),
                  ),
                );
              }),
              GestureDetector(
                onTap: _mostrarDialogoNuevaBomba,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: _border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, size: 15, color: _textSecondary),
                    const SizedBox(width: 5),
                    Text('Agregar bomba',
                        style: TextStyle(fontSize: 13, color: _textSecondary)),
                  ]),
                ),
              ),
            ],
          ),
        ]),

        if (_bombasSeleccionadas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border, width: 1.5),
            ),
            child: Column(children: [
              Icon(Icons.water_damage_outlined, size: 40,
                  color: _textSecondary.withOpacity(0.35)),
              const SizedBox(height: 12),
              const Text('Ninguna bomba seleccionada',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      color: _textSecondary)),
              const SizedBox(height: 4),
              const Text('Tocá una bomba de la lista para activarla.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: _textSecondary)),
            ]),
          )
        else
          ..._bombasSeleccionadas.map((b) => _buildBombaCard(b)),
      ],
    );
  }

  Widget _buildBombaCard(BombaModel bomba) {
    final encKey   = 'bomba_${bomba.id}_encendido';
    final apaKey   = 'bomba_${bomba.id}_apagado';
    final esDiaSig = _formData['bomba_${bomba.id}_apagado_siguiente_dia'] == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [_primary.withOpacity(0.07), _accent.withOpacity(0.03)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.water_damage_rounded, color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(bomba.nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _textPrimary)),
            ),
            if (esDiaSig)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _nightColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _nightColor.withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.nights_stay_rounded, size: 12, color: _nightColor),
                  SizedBox(width: 4),
                  Text('Turno nocturno',
                      style: TextStyle(fontSize: 11, color: _nightColor,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _bombasActivas.remove(bomba.id.toString())),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: _error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.close_rounded,
                    size: 15, color: _error.withOpacity(0.7)),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Encendido', key: encKey,
                  icon: Icons.play_arrow_rounded, iconColor: _success,
                  onTap: () async {
                    final t = await showTimePicker(context: context,
                        initialTime: TimeOfDay.now());
                    if (t != null) {
                      final val = '${t.hour.toString().padLeft(2, '0')}:'
                          '${t.minute.toString().padLeft(2, '0')}';
                      setState(() {
                        _formData[encKey] = val;
                        _formData.remove('bomba_${bomba.id}_encendido_iso');
                        _getController(encKey).text = val;
                      });
                    }
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: _textSecondary, size: 18),
              ),
              Expanded(
                child: _buildTimeField(
                  label: 'Apagado', key: apaKey,
                  icon: Icons.stop_rounded, iconColor: _error,
                  onTap: () async {
                    final t = await showTimePicker(context: context,
                        initialTime: TimeOfDay.now());
                    if (t != null) {
                      final encStr = _formData[encKey];
                      bool diaSig = false;
                      if (encStr != null && encStr.isNotEmpty) {
                        final partsEnc = encStr.split(':');
                        final minEnc = int.parse(partsEnc[0]) * 60 + int.parse(partsEnc[1]);
                        final minApa = t.hour * 60 + t.minute;
                        diaSig = minApa < minEnc;
                      }
                      final horaStr = '${t.hour.toString().padLeft(2, '0')}:'
                          '${t.minute.toString().padLeft(2, '0')}';
                      final display = diaSig ? '$horaStr (+1d)' : horaStr;
                      setState(() {
                        _formData[apaKey] = horaStr;
                        _formData.remove('bomba_${bomba.id}_apagado_iso');
                        _formData['bomba_${bomba.id}_apagado_siguiente_dia'] = diaSig ? '1' : '0';
                        _getController(apaKey).text = display;
                      });
                    }
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Divider(color: _border, height: 1),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _buildField(
                  label: 'Horómetro inicial',
                  key: 'bomba_${bomba.id}_horometro_inicial',
                  icon: Icons.av_timer_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'h',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Horómetro final',
                  key: 'bomba_${bomba.id}_horometro_final',
                  icon: Icons.av_timer_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'h',
                ),
              ),
            ]),
            _buildField(
              label: 'Observación',
              key: 'bomba_${bomba.id}_observacion',
              icon: Icons.notes_rounded,
              hint: 'Observación de operación (opcional)',
              optional: true,
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDesactivacion() {
    return _buildStepContainer(
      title: 'Desactivación de equipos',
      subtitle: 'Sala de Mandos',
      icon: Icons.electrical_services_rounded,
      children: [
        if ((widget.estacion.tableros ?? []).isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: (widget.estacion.tableros ?? []).map((tablero) {
                final isSelected = _tableroSeleccionado?.id == tablero.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tablero.nombre),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _tableroSeleccionado = tablero),
                    selectedColor: _primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        if (_tableroSeleccionado != null)
          _buildCard(children: [
            Text(_tableroSeleccionado!.nombre,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const SizedBox(height: 4),
            const Text('DESACTIVACIÓN',
                style: TextStyle(fontSize: 11, color: _textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _buildStatusSelector('Interruptor',       'tablero_${_tableroSeleccionado!.id}_DESACTIVACION_interruptor'),
            _buildStatusSelector('Selector',          'tablero_${_tableroSeleccionado!.id}_DESACTIVACION_selector'),
            _buildStatusSelector('Parada emergencia', 'tablero_${_tableroSeleccionado!.id}_DESACTIVACION_parada'),
            _buildStatusSelector('Variador',          'tablero_${_tableroSeleccionado!.id}_DESACTIVACION_variador'),
            _buildStatusSelector('Alarma',            'tablero_${_tableroSeleccionado!.id}_DESACTIVACION_alarma'),
          ]),
        _buildCard(children: [
          const Text('Condición de desactivación',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textSecondary)),
          const SizedBox(height: 12),
          _buildField(label: 'Estado telemetría', key: 'DESACTIVACION_ESTADO_TELEMETRIA',
              icon: Icons.sensors_rounded, optional: true),
          _buildField(label: 'Presión de ingreso', key: 'DESACTIVACION_PRESION_INGRESO',
              icon: Icons.speed_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar', optional: true),
        ]),
      ],
    );
  }

  Widget _buildActivosStep() {
    final activosActivos = (widget.estacion.activos ?? []).where((a) => a.activo).toList();

    if (activosActivos.isEmpty) {
      return _buildStepContainer(
        title: 'Activos de Estación',
        subtitle: 'No hay activos configurados',
        icon: Icons.category_rounded,
        children: [
          _buildCard(children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(children: [
                  Icon(Icons.inventory_2_outlined, size: 40, color: _textSecondary),
                  SizedBox(height: 12),
                  Text('Sin activos registrados para esta estación',
                      style: TextStyle(color: _textSecondary, fontSize: 14)),
                ]),
              ),
            ),
          ]),
        ],
      );
    }

    return _buildStepContainer(
      title: 'Activos de Estación',
      subtitle: 'Equipos y parámetros de operación',
      icon: Icons.category_rounded,
      children: activosActivos.map((activo) {
        final campos = activo.tipoActivo.campos
          ..sort((a, b) => a.orden.compareTo(b.orden));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(_getIconoPorTipo(activo.tipoActivo.nombre),
                      color: _primary, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(activo.nombre,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _textPrimary)),
                    Text(activo.tipoActivo.nombre,
                        style: const TextStyle(fontSize: 12, color: _textSecondary)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: campos.map((campo) {
                  final key = 'activo_${activo.id}_campo_${campo.id}';
                  return _buildCampoActivo(campo: campo, key: key);
                }).toList(),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildCampoActivo({required dynamic campo, required String key}) {
    final tipo = campo.tipoInput;
    if (tipo == 'booleano') {
      final valor = _formData[key] ?? 'false';
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Expanded(
            child: Text('${campo.nombreCampo}${campo.requerido ? ' *' : ''}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: _textPrimary)),
          ),
          Switch(
            value: valor == 'true',
            activeColor: _primary,
            onChanged: (v) => setState(() => _formData[key] = v.toString()),
          ),
        ]),
      );
    }

    return _buildField(
      label: '${campo.nombreCampo}${campo.requerido ? ' *' : ''}',
      key: key,
      hint: campo.etiqueta ?? 'Ingrese valor',
      suffix: campo.unidad?.isNotEmpty == true ? campo.unidad : null,
      keyboardType: tipo == 'numero'
          ? const TextInputType.numberWithOptions(decimal: true)
          : tipo == 'hora'
          ? TextInputType.datetime
          : TextInputType.text,
      optional: !campo.requerido,
    );
  }

  IconData _getIconoPorTipo(String tipo) {
    const iconos = {
      'Bomba':         Icons.water_damage_rounded,
      'Transformador': Icons.electrical_services_rounded,
      'Cisterna':      Icons.water_drop_rounded,
      'Medidor':       Icons.speed_rounded,
    };
    return iconos[tipo] ?? Icons.device_hub_rounded;
  }

  Widget _buildLecturaFinalStep() {
    return _buildStepContainer(
      title: 'Lectura Final',
      subtitle: 'Valores registrados al cierre del turno',
      icon: Icons.stop_circle_rounded,
      children: [
        _buildCard(children: [
          _buildTimeField(
            label: 'Fecha y hora de registro',
            key: 'HORA_FINAL',
            icon: Icons.access_time_rounded,
            iconColor: _primary,
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('es', 'ES'),
              );
              if (pickedDate == null) return;
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (pickedTime == null) return;
              final isoFormatted =
                  '${pickedDate.year}-'
                  '${pickedDate.month.toString().padLeft(2, '0')}-'
                  '${pickedDate.day.toString().padLeft(2, '0')}T'
                  '${pickedTime.hour.toString().padLeft(2, '0')}:'
                  '${pickedTime.minute.toString().padLeft(2, '0')}:00';
              final displayFormatted =
                  '${pickedDate.day.toString().padLeft(2, '0')}/'
                  '${pickedDate.month.toString().padLeft(2, '0')}/'
                  '${pickedDate.year}  '
                  '${pickedTime.hour.toString().padLeft(2, '0')}:'
                  '${pickedTime.minute.toString().padLeft(2, '0')}';
              setState(() {
                _formData['HORA_FINAL'] = isoFormatted;
                _formData['HORA_FINAL_DISPLAY'] = displayFormatted;
                _getController('HORA_FINAL').text = displayFormatted;
              });
            },
          ),
          _buildField(label: 'Nivel cisterna', key: 'NIVEL_CISTERNA_FINAL',
              icon: Icons.water_drop_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm'),
          _buildField(label: 'Presión línea', key: 'PRESION_LINEA_FINAL',
              icon: Icons.speed_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
          _buildField(label: 'Totalizador', key: 'TOTALIZADOR_FINAL',
              icon: Icons.analytics_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm³'),
          _buildField(label: 'Presión Jatun Huaylla', key: 'PRESION_JATUN_HUAYLLA_FINAL',
              icon: Icons.compress_rounded,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
        ]),
        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.show_chart_rounded, color: _accent, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Producción calculada',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
          const SizedBox(height: 16),
          Builder(builder: (ctx) {
            final ini = double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '') ?? 0;
            final fin = double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '') ?? 0;
            final prod = fin - ini;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withOpacity(0.2)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.water_rounded, color: _accent, size: 22),
                const SizedBox(width: 10),
                Text('${prod.toStringAsFixed(2)} m³',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                        color: _textPrimary)),
              ]),
            );
          }),
        ]),
      ],
    );
  }

  Widget _buildOperadoresStep() {
    return _buildStepContainer(
      title: 'Información Final',
      subtitle: 'Personal de turno y observaciones',
      icon: Icons.badge_rounded,
      children: [
        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.group_rounded, color: _primary, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Operadores de turno',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
          const SizedBox(height: 14),
          _buildField(
            label: 'Operador 1 *',
            key: 'OPERADOR_TURNO_1',
            icon: Icons.person_rounded,
            readOnly: _turnosBloqueados.contains(1),
          ),
          _buildField(
            label: 'Operador 2',
            key: 'OPERADOR_TURNO_2',
            icon: Icons.person_outline_rounded,
            optional: true,
            readOnly: _turnosBloqueados.contains(2),
          ),
          _buildField(
            label: 'Operador 3',
            key: 'OPERADOR_TURNO_3',
            icon: Icons.person_outline_rounded,
            optional: true,
            readOnly: _turnosBloqueados.contains(3),
          ),
        ]),
        _buildCard(children: [
          const Text('Observaciones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: _textPrimary),
            onChanged: (v) => _formData['OBSERVACIONES'] = v,
            decoration: InputDecoration(
              hintText: 'Observaciones adicionales...',
              hintStyle: const TextStyle(color: Color(0xFFB0BAD3), fontSize: 13),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ]),
      ],
    );
  }

  // ─── Barra inferior ────
  Widget _buildBottomBar() {
    final isLast = _currentStep == _stepsVisibles.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(children: [
          if (_currentStep > 0) ...[
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _previousStep,
              icon: const Icon(Icons.arrow_back_ios_new, size: 14),
              label: const Text('Atrás'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _border, width: 1.5),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : isLast ? _guardar : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? _success : _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                shadowColor: Colors.transparent,
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isLast ? Icons.cloud_upload_rounded
                    : Icons.arrow_forward_rounded, size: 18),
                const SizedBox(width: 8),
                Text(isLast ? 'Guardar registro' : 'Siguiente'),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Modelo auxiliar ───────
class _StepInfo {
  final String title, subtitle;
  final IconData icon;
  const _StepInfo(this.title, this.icon, this.subtitle);
}