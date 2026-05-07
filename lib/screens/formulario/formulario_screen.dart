import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/estacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/operacion_service.dart';

class FormularioScreen extends StatefulWidget {
  final EstacionModel estacion;
  const FormularioScreen({super.key, required this.estacion});

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ─── Paleta ──────────────────────────────────────────────────────────────
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

  final List<_StepInfo> _steps = [
    _StepInfo('Inspección',    Icons.manage_search_rounded,       'Verificación del sistema'),
    _StepInfo('Equipos',       Icons.electrical_services_rounded, 'Estado de tableros'),
    _StepInfo('Lect. Inicial', Icons.play_circle_rounded,         'Valores al inicio'),
    _StepInfo('Bombas',        Icons.water_damage_rounded,        'Control de operación'),
    _StepInfo('Lect. Final',   Icons.stop_circle_rounded,         'Valores al cierre'),
    _StepInfo('Operadores',    Icons.badge_rounded,               'Personal y producción'),
  ];

  // ─── Lifecycle ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  void _initializeFormData() {
    for (var bomba in widget.estacion.bombas) {
      _formData['bomba_${bomba.id}_horometro_inicial'] =
          bomba.ultimoHorometro.toString();
    }
    _formData['TABLERO_GENERAL_ESTADO'] = 'OK';
    _formData['TABLERO_BOMBA_1_ESTADO'] = 'OK';
    _formData['TABLERO_BOMBA_2_ESTADO'] = 'OK';
  }

  TextEditingController _getController(String key) {
    return _controllers.putIfAbsent(
        key, () => TextEditingController(text: _formData[key] ?? ''));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Navegación ──────────────────────────────────────────────────────────
  void _nextStep() {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
      _fadeController
        ..reset()
        ..forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic);
      _fadeController
        ..reset()
        ..forward();
    }
  }

  // ─── Validación ──────────────────────────────────────────────────────────
  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        for (final k in [
          'SPAU_110C',
          'SPAU_111C',
          'SPAU_180_C_P_1',
          'SPAU_180_C_E_1'
        ]) {
          if (_formData[k]?.trim().isEmpty ?? true) {
            return 'Complete todos los campos de inspección';
          }
        }
        return null;

      case 1:
        for (final k in [
          'TABLERO_GENERAL_ESTADO',
          'TABLERO_BOMBA_1_ESTADO',
          'TABLERO_BOMBA_2_ESTADO'
        ]) {
          if (_formData[k]?.isEmpty ?? true) {
            return 'Seleccione el estado de todos los tableros';
          }
        }
        return null;

      case 2:
        for (final k in [
          'NIVEL_CISTERNA_INICIAL',
          'PRESION_LINEA_INICIAL',
          'TOTALIZADOR_INICIAL',
          'PRESION_CISTERNA_INICIAL'
        ]) {
          final v = _formData[k];
          if (v == null || v.trim().isEmpty) {
            return 'Complete todos los campos de lectura inicial';
          }
          if (double.tryParse(v) == null) {
            return 'Todos los valores deben ser números válidos';
          }
        }
        return null;

      case 3:
        for (final bomba in widget.estacion.bombas) {
          final enc    = _formData['bomba_${bomba.id}_encendido'];
          final apa    = _formData['bomba_${bomba.id}_apagado'];
          final horIni = _formData['bomba_${bomba.id}_horometro_inicial'];
          final horFin = _formData['bomba_${bomba.id}_horometro_final'];

          if (enc == null || enc.isEmpty) {
            return 'Ingrese hora de encendido de ${bomba.nombre}';
          }
          if (apa == null || apa.isEmpty) {
            return 'Ingrese hora de apagado de ${bomba.nombre}';
          }

          final partsEnc = enc.split(':');
          final partsApa = apa.split(':');
          final minEnc =
              int.parse(partsEnc[0]) * 60 + int.parse(partsEnc[1]);
          final minApa =
              int.parse(partsApa[0]) * 60 + int.parse(partsApa[1]);
          final esDiaSig =
              _formData['bomba_${bomba.id}_apagado_siguiente_dia'] == '1';

          if (!esDiaSig && minApa <= minEnc) {
            return 'Hora de apagado debe ser posterior al encendido en ${bomba.nombre}';
          }
          if (horIni == null || horIni.isEmpty) {
            return 'Ingrese horómetro inicial de ${bomba.nombre}';
          }
          if (horFin == null || horFin.isEmpty) {
            return 'Ingrese horómetro final de ${bomba.nombre}';
          }
          if (double.tryParse(horIni) == null) {
            return 'Horómetro inicial inválido en ${bomba.nombre}';
          }
          if (double.tryParse(horFin) == null) {
            return 'Horómetro final inválido en ${bomba.nombre}';
          }
          if (double.parse(horFin) < double.parse(horIni)) {
            return 'Horómetro final debe ser mayor al inicial en ${bomba.nombre}';
          }
        }
        return null;

      case 4:
        for (final k in [
          'NIVEL_CISTERNA_FINAL',
          'PRESION_LINEA_FINAL',
          'TOTALIZADOR_FINAL',
          'PRESION_CISTERNA_FINAL'
        ]) {
          final v = _formData[k];
          if (v == null || v.trim().isEmpty) {
            return 'Complete todos los campos de lectura final';
          }
          if (double.tryParse(v) == null) {
            return 'Todos los valores deben ser números válidos';
          }
        }
        final totIni =
        double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '');
        final totFin =
        double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '');
        if (totIni != null && totFin != null && totFin < totIni) {
          return 'El totalizador final debe ser mayor al inicial';
        }
        return null;

      case 5:
        final op1 = _formData['OPERADOR_TURNO_1'];
        if (op1 == null || op1.trim().isEmpty) {
          return 'El operador del turno 1 es obligatorio';
        }
        final soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
        for (int i = 1; i <= 3; i++) {
          final nombre = _formData['OPERADOR_TURNO_$i'];
          if (nombre != null &&
              nombre.isNotEmpty &&
              !soloLetras.hasMatch(nombre.trim())) {
            return 'El nombre del operador $i solo puede contener letras';
          }
        }
        if (_formData['TOTAL_PRODUCCION']?.isEmpty ?? true) {
          return 'Ingrese el total de producción';
        }
        if (_formData['HORAS_BOMBEO_TOTAL']?.isEmpty ?? true) {
          return 'Ingrese las horas de bombeo total';
        }
        return null;

      default:
        return null;
    }
  }

  // ─── Guardar ─────────────────────────────────────────────────────────────
  Future<void> _guardar() async {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token!;

      // ── Operadores ──────────────────────────────────────────────────────
      // El API espera: nombre_operador (string) + numero_turno (int)
      final operadores = <Map<String, dynamic>>[];
      for (int i = 1; i <= 3; i++) {
        final nombre = _formData['OPERADOR_TURNO_$i'];
        if (nombre != null && nombre.trim().isNotEmpty) {
          operadores.add({
            'nombre_operador': nombre.trim(),
            'numero_turno': i,
          });
        }
      }

      // ── Bombeos ─────────────────────────────────────────────────────────
      // El API espera encendido/apagado en formato HH:mm (NO ISO8601)
      final bombeos = <Map<String, dynamic>>[];
      for (final bomba in widget.estacion.bombas) {
        final encendido = _formData['bomba_${bomba.id}_encendido'];
        final apagado   = _formData['bomba_${bomba.id}_apagado'];
        final horIni    = _formData['bomba_${bomba.id}_horometro_inicial'];
        final horFin    = _formData['bomba_${bomba.id}_horometro_final'];

        if (encendido != null && apagado != null) {
          bombeos.add({
            'bomba_id':          bomba.id,
            'encendido':         encendido, // HH:mm — formato requerido por el API
            'apagado':           apagado,   // HH:mm
            'horometro_inicial': horIni != null ? double.tryParse(horIni) : null,
            'horometro_final':   horFin != null ? double.tryParse(horFin) : null,
            'observacion':       null,
          });
        }
      }

      // ── Tableros ─────────────────────────────────────────────────────────
      // El API espera: tablero_id (UUID) + momento (HABILITACION | DESACTIVACION)
      final tableros = <Map<String, dynamic>>[];
      for (final tablero in widget.estacion.tableros) {
        for (final momento in ['HABILITACION', 'DESACTIVACION']) {
          final prefix = 'tablero_${tablero.id}_$momento';
          tableros.add({
            'tablero_id':               tablero.id,
            'momento':                  momento,
            'interruptor_estado':       _formData['${prefix}_interruptor']  ?? '',
            'selector_estado':          _formData['${prefix}_selector']     ?? '',
            'parada_emergencia_estado': _formData['${prefix}_parada']       ?? '',
            'variador_estado':          _formData['${prefix}_variador']     ?? '',
            'alarma_estado':            _formData['${prefix}_alarma']       ?? '',
          });
        }
      }

      // ── Payload final ─────────────────────────────────────────────────────
      final payload = {
        'estacion_id':       widget.estacion.id.toString(),
        'fecha_folio':       DateTime.now().toIso8601String().substring(0, 10),
        'totalizador_inicial':
        double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '0') ?? 0.0,
        'totalizador_final':
        double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '0') ?? 0.0,
        'lectura_inicial': {
          'hora_registro':         _formData['HORA_INICIAL'] ?? '',
          'nivel_cisterna':        _formData['NIVEL_CISTERNA_INICIAL'],
          'presion_linea':         _formData['PRESION_LINEA_INICIAL'],
          'totalizador':           _formData['TOTALIZADOR_INICIAL'],
          'presion_jatun_huaylla': _formData['PRESION_CISTERNA_INICIAL'],
        },
        'lectura_final': {
          'hora_registro':         _formData['HORA_FINAL'] ?? '',
          'nivel_cisterna':        _formData['NIVEL_CISTERNA_FINAL'],
          'presion_linea':         _formData['PRESION_LINEA_FINAL'],
          'totalizador':           _formData['TOTALIZADOR_FINAL'],
          'presion_jatun_huaylla': _formData['PRESION_CISTERNA_FINAL'],
        },
        'operadores': operadores,
        'bombeos':    bombeos,
        'tableros':   tableros,
      };

      final result =
      await OperacionService.registrar(token: token, payload: payload);
      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackbar('✓ Registro guardado correctamente');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackbar(
            result['message']?.toString() ?? 'Error al guardar',
            isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Snackbar ────────────────────────────────────────────────────────────
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: isError ? _error : _success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 6,
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════
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
              children: [
                _buildInspeccionStep(),
                _buildHabilitacionStep(),
                _buildLecturaInicialStep(),
                _buildBombasStep(),
                _buildLecturaFinalStep(),
                _buildOperadoresStep(),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ]),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
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
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Registro de Operación',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Text(widget.estacion.nombre,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13)),
                  ]),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${_currentStep + 1} / ${_steps.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Stepper ─────────────────────────────────────────────────────────────
  Widget _buildStepper() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
              children: List.generate(_steps.length, (i) {
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                          isDone
                              ? Icons.check_circle_rounded
                              : _steps[i].icon,
                          size: 14,
                          color: isActive
                              ? _primary
                              : Colors.white
                              .withOpacity(isDone ? 0.9 : 0.5)),
                      const SizedBox(width: 5),
                      Text(_steps[i].title,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isActive
                                  ? _primary
                                  : Colors.white
                                  .withOpacity(isDone ? 0.9 : 0.5))),
                    ]),
                  ),
                );
              })),
        ),
      ]),
    );
  }

  // ─── Step container ───────────────────────────────────────────────────────
  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                      color: _primary.withOpacity(0.06),
                      blurRadius: 12,
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
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                                letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 13, color: _textSecondary)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            ...children,
          ]),
    );
  }

  // ─── Campo de texto ───────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String key,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    letterSpacing: 0.1)),
            const SizedBox(height: 6),
            TextFormField(
              controller: readOnly ? _getController(key) : null,
              initialValue: readOnly ? null : (_formData[key] ?? ''),
              readOnly: readOnly,
              onTap: onTap,
              keyboardType: keyboardType,
              style: const TextStyle(
                  fontSize: 15,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500),
              onChanged: readOnly ? null : (v) => _formData[key] = v,
              decoration: InputDecoration(
                hintText: hint ?? 'Ingrese $label',
                hintStyle: const TextStyle(
                    color: Color(0xFFB0BAD3), fontSize: 14),
                suffixText: suffix,
                suffixStyle: const TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                prefixIcon: icon != null
                    ? Icon(icon,
                    size: 19, color: _primary.withOpacity(0.7))
                    : null,
                filled: true,
                fillColor: _cardBg,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: _border, width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: _primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
            ),
          ]),
    );
  }

  // ─── Campo de hora ────────────────────────────────────────────────────────
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
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
              letterSpacing: 0.3)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: hasValue
                ? iconColor.withOpacity(0.06)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: hasValue
                    ? iconColor.withOpacity(0.4)
                    : _border,
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
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary))
                  : Text('Seleccionar',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400)),
            ),
            Icon(Icons.access_time_rounded,
                size: 15, color: Colors.grey.shade400),
          ]),
        ),
      ),
    ]);
  }

  // ─── Selector de estado ───────────────────────────────────────────────────
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
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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
                        onTap: () =>
                            setState(() => _formData[key] = opt),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding:
                          const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.1)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isSelected
                                    ? color
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1),
                          ),
                          child: Column(children: [
                            Icon(
                                opt == 'OK'
                                    ? Icons.check_circle_rounded
                                    : opt == 'Defectuoso'
                                    ? Icons.cancel_rounded
                                    : Icons.warning_rounded,
                                color: isSelected
                                    ? color
                                    : Colors.grey.shade400,
                                size: 20),
                            const SizedBox(height: 4),
                            Text(opt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? color
                                        : Colors.grey.shade500)),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PASOS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildInspeccionStep() {
    return _buildStepContainer(
      title: 'Inspección del Sistema',
      subtitle: 'Verificación de componentes SPAU',
      icon: Icons.manage_search_rounded,
      children: [
        _buildCard(children: [
          _buildField(
              label: 'SPAU 110C',
              key: 'SPAU_110C',
              icon: Icons.radio_button_checked,
              hint: 'Estado del componente'),
          _buildField(
              label: 'SPAU 111C',
              key: 'SPAU_111C',
              icon: Icons.radio_button_checked,
              hint: 'Estado del componente'),
          _buildField(
              label: 'SPAU 180 C P-1',
              key: 'SPAU_180_C_P_1',
              icon: Icons.radio_button_checked,
              hint: 'Estado del componente'),
          _buildField(
              label: 'SPAU 180 C E-1',
              key: 'SPAU_180_C_E_1',
              icon: Icons.radio_button_checked,
              hint: 'Estado del componente'),
        ])
      ],
    );
  }

  Widget _buildHabilitacionStep() {
    return _buildStepContainer(
      title: 'Habilitación de Equipos',
      subtitle: 'Estado de los tableros eléctricos',
      icon: Icons.electrical_services_rounded,
      children: [
        _buildStatusSelector('Tablero General', 'TABLERO_GENERAL_ESTADO'),
        _buildStatusSelector('Tablero Bomba 1', 'TABLERO_BOMBA_1_ESTADO'),
        _buildStatusSelector('Tablero Bomba 2', 'TABLERO_BOMBA_2_ESTADO'),
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
          _buildField(
              label: 'Nivel Cisterna',
              key: 'NIVEL_CISTERNA_INICIAL',
              icon: Icons.water_drop_outlined,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm'),
          _buildField(
              label: 'Presión Línea',
              key: 'PRESION_LINEA_INICIAL',
              icon: Icons.speed_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
          _buildField(
              label: 'Totalizador',
              key: 'TOTALIZADOR_INICIAL',
              icon: Icons.analytics_outlined,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm³'),
          _buildField(
              label: 'Presión Cisterna',
              key: 'PRESION_CISTERNA_INICIAL',
              icon: Icons.compress_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
        ])
      ],
    );
  }

  Widget _buildBombasStep() {
    return _buildStepContainer(
      title: 'Control de Bombas',
      subtitle: 'Registro de operación por bomba',
      icon: Icons.water_damage_rounded,
      children:
      widget.estacion.bombas.map((b) => _buildBombaCard(b)).toList(),
    );
  }

  Widget _buildBombaCard(BombaModel bomba) {
    final encKey = 'bomba_${bomba.id}_encendido';
    final apaKey = 'bomba_${bomba.id}_apagado';
    final esDiaSig =
        _formData['bomba_${bomba.id}_apagado_siguiente_dia'] == '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // ── Header ───────────────────────────────────────────────────────
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              _primary.withOpacity(0.08),
              _accent.withOpacity(0.04)
            ]),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.water_damage_rounded,
                  color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text(bomba.nombre,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
            const Spacer(),
            if (esDiaSig)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF7B1FA2).withOpacity(0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.nights_stay_rounded,
                      size: 12, color: Color(0xFF7B1FA2)),
                  SizedBox(width: 4),
                  Text('Turno nocturno',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7B1FA2),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
        ),

        // ── Cuerpo ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Horas
            Row(children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Encendido',
                  key: encKey,
                  icon: Icons.play_arrow_rounded,
                  iconColor: _success,
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: _primary,
                                onSurface: _textPrimary)),
                        child: child!,
                      ),
                    );
                    if (t != null) {
                      // Formato HH:mm — requerido por el API
                      final val =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                      setState(() {
                        _formData[encKey] = val;
                        _getController(encKey).text = val;
                      });
                    }
                  },
                ),
              ),
              Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: _textSecondary, size: 18),
              ),
              Expanded(
                child: _buildTimeField(
                  label: 'Apagado',
                  key: apaKey,
                  icon: Icons.stop_rounded,
                  iconColor: _error,
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: _primary,
                                onSurface: _textPrimary)),
                        child: child!,
                      ),
                    );
                    if (t != null) {
                      final encStr = _formData[encKey];
                      bool diaSig = false;
                      if (encStr != null && encStr.isNotEmpty) {
                        final partsEnc = encStr.split(':');
                        final minEnc = int.parse(partsEnc[0]) * 60 +
                            int.parse(partsEnc[1]);
                        final minApa = t.hour * 60 + t.minute;
                        diaSig = minApa < minEnc; // cruza medianoche
                      }
                      // Guardamos HH:mm (formato API)
                      final horaStr =
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                      // Mostramos "+1d" solo visualmente
                      final display =
                      diaSig ? '$horaStr (+1d)' : horaStr;
                      setState(() {
                        _formData[apaKey] = horaStr;
                        _formData[
                        'bomba_${bomba.id}_apagado_siguiente_dia'] =
                        diaSig ? '1' : '0';
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

            // Horómetros
            Row(children: [
              Expanded(
                child: _buildField(
                  label: 'Horómetro Inicial',
                  key: 'bomba_${bomba.id}_horometro_inicial',
                  icon: Icons.av_timer_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  suffix: 'h',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  label: 'Horómetro Final',
                  key: 'bomba_${bomba.id}_horometro_final',
                  icon: Icons.av_timer_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  suffix: 'h',
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLecturaFinalStep() {
    return _buildStepContainer(
      title: 'Lectura Final',
      subtitle: 'Valores registrados al cierre del turno',
      icon: Icons.stop_circle_rounded,
      children: [
        _buildCard(children: [
          _buildField(
              label: 'Nivel Cisterna',
              key: 'NIVEL_CISTERNA_FINAL',
              icon: Icons.water_drop_outlined,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm'),
          _buildField(
              label: 'Presión Línea',
              key: 'PRESION_LINEA_FINAL',
              icon: Icons.speed_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
          _buildField(
              label: 'Totalizador',
              key: 'TOTALIZADOR_FINAL',
              icon: Icons.analytics_outlined,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'm³'),
          _buildField(
              label: 'Presión Cisterna',
              key: 'PRESION_CISTERNA_FINAL',
              icon: Icons.compress_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              suffix: 'bar'),
        ])
      ],
    );
  }

  Widget _buildOperadoresStep() {
    return _buildStepContainer(
      title: 'Información Final',
      subtitle: 'Personal de turno y producción',
      icon: Icons.badge_rounded,
      children: [
        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.group_rounded,
                  color: _primary, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Operadores de Turno',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
          const SizedBox(height: 14),
          _buildField(
              label: 'Operador 1 *',
              key: 'OPERADOR_TURNO_1',
              icon: Icons.person_rounded),
          _buildField(
              label: 'Operador 2 (opcional)',
              key: 'OPERADOR_TURNO_2',
              icon: Icons.person_outline_rounded),
          _buildField(
              label: 'Operador 3 (opcional)',
              key: 'OPERADOR_TURNO_3',
              icon: Icons.person_outline_rounded),
        ]),

        _buildCard(children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.show_chart_rounded,
                  color: _accent, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Métricas de Producción',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _buildField(
                  label: 'Total Producción',
                  key: 'TOTAL_PRODUCCION',
                  icon: Icons.show_chart_rounded,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'm³'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                  label: 'Horas Bombeo',
                  key: 'HORAS_BOMBEO_TOTAL',
                  icon: Icons.timer_rounded,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'h'),
            ),
          ]),
        ]),

        // Observaciones
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Observaciones',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            maxLines: 4,
            style:
            const TextStyle(fontSize: 14, color: _textPrimary),
            onChanged: (v) => _formData['OBSERVACIONES'] = v,
            decoration: InputDecoration(
              hintText: 'Ingrese observaciones adicionales...',
              hintStyle: const TextStyle(
                  color: Color(0xFFB0BAD3), fontSize: 13),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  const BorderSide(color: _primary, width: 2)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ]),
      ],
    );
  }

  // ─── Barra inferior ───────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentStep == _steps.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border, width: 1.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: _border, width: 1.5),
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed:
              _isLoading ? null : isLast ? _guardar : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? _success : _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                shadowColor: Colors.transparent,
                textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2),
              ),
              child: _isLoading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        isLast
                            ? Icons.cloud_upload_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(isLast ? 'Guardar Registro' : 'Siguiente'),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Modelo auxiliar ──────────────────────────────────────────────────────────
class _StepInfo {
  final String title, subtitle;
  final IconData icon;
  const _StepInfo(this.title, this.icon, this.subtitle);
}