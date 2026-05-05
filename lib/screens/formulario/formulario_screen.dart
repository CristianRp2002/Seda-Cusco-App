import 'package:flutter/material.dart';
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

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  // Data storage
  final Map<String, String> _formData = {};
  
  bool _isLoading = false;
  int _currentStep = 0;
  
  final List<String> _stepTitles = [
    'Inspección',
    'Equipos',
    'Lectura Inicial',
    'Bombas',
    'Lectura Final',
    'Operadores'
  ];

  final List<IconData> _stepIcons = [
    Icons.search_rounded,
    Icons.settings_input_component_rounded,
    Icons.play_circle_outline_rounded,
    Icons.water_damage_rounded,
    Icons.stop_circle_outlined,
    Icons.people_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Initialize with default values
    for (var bomba in widget.estacion.bombas) {
      _formData['bomba_${bomba.id}_horometro_inicial'] = bomba.ultimoHorometro.toString();
    }
    _formData['TABLERO_GENERAL_ESTADO'] = 'OK';
    _formData['TABLERO_BOMBA_1_ESTADO'] = 'OK';
    _formData['TABLERO_BOMBA_2_ESTADO'] = 'OK';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Inspección
        for (final key in ['SPAU_110C', 'SPAU_111C', 'SPAU_180_C_P_1', 'SPAU_180_C_E_1']) {
          if (_formData[key]?.trim().isEmpty ?? true) {
            return 'Complete todos los campos de inspección';
          }
        }
        return null;

      case 1: // Tableros
        for (final key in ['TABLERO_GENERAL_ESTADO', 'TABLERO_BOMBA_1_ESTADO', 'TABLERO_BOMBA_2_ESTADO']) {
          if (_formData[key]?.isEmpty ?? true) {
            return 'Seleccione el estado de todos los tableros';
          }
        }
        return null;

      case 2: // Lectura Inicial
        for (final key in ['NIVEL_CISTERNA_INICIAL', 'PRESION_LINEA_INICIAL',
                           'TOTALIZADOR_INICIAL', 'PRESION_CISTERNA_INICIAL']) {
          final val = _formData[key];
          if (val == null || val.trim().isEmpty) {
            return 'Complete todos los campos de lectura inicial';
          }
          if (double.tryParse(val) == null) {
            return 'Todos los valores deben ser números válidos';
          }
        }
        return null;

      case 3: // Bombas
        for (final bomba in widget.estacion.bombas) {
          final encendido = _formData['bomba_${bomba.id}_encendido'];
          final apagado   = _formData['bomba_${bomba.id}_apagado'];
          final horIni    = _formData['bomba_${bomba.id}_horometro_inicial'];
          final horFin    = _formData['bomba_${bomba.id}_horometro_final'];

          if (encendido == null || encendido.isEmpty) return 'Ingrese hora de encendido de ${bomba.nombre}';
          if (apagado == null   || apagado.isEmpty)   return 'Ingrese hora de apagado de ${bomba.nombre}';

          // Apagado debe ser después del encendido
          final partsEnc = encendido.split(':');
          final partsApa = apagado.split(':');
          final minutosEnc = int.parse(partsEnc[0]) * 60 + int.parse(partsEnc[1]);
          final minutosApa = int.parse(partsApa[0]) * 60 + int.parse(partsApa[1]);
          if (minutosApa <= minutosEnc) {
            return 'La hora de apagado debe ser después del encendido en ${bomba.nombre}';
          }

          // Horómetros
          if (horIni == null || horIni.isEmpty) return 'Ingrese horómetro inicial de ${bomba.nombre}';
          if (horFin == null || horFin.isEmpty) return 'Ingrese horómetro final de ${bomba.nombre}';
          if (double.tryParse(horIni) == null)  return 'Horómetro inicial inválido en ${bomba.nombre}';
          if (double.tryParse(horFin) == null)  return 'Horómetro final inválido en ${bomba.nombre}';

          // Horómetro final debe ser mayor al inicial
          final ini = double.parse(horIni);
          final fin = double.parse(horFin);
          if (fin < ini) {
            return 'El horómetro final debe ser mayor al inicial en ${bomba.nombre}';
          }
        }
        return null;

      case 4: // Lectura Final
        for (final key in ['NIVEL_CISTERNA_FINAL', 'PRESION_LINEA_FINAL',
                           'TOTALIZADOR_FINAL', 'PRESION_CISTERNA_FINAL']) {
          final val = _formData[key];
          if (val == null || val.trim().isEmpty) {
            return 'Complete todos los campos de lectura final';
          }
          if (double.tryParse(val) == null) {
            return 'Todos los valores deben ser números válidos';
          }
        }

        // Totalizador final debe ser mayor al inicial
        final totIni = double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '');
        final totFin = double.tryParse(_formData['TOTALIZADOR_FINAL'] ?? '');
        if (totIni != null && totFin != null && totFin < totIni) {
          return 'El totalizador final debe ser mayor al inicial';
        }
        return null;

      case 5: // Operadores
        final operador1 = _formData['OPERADOR_TURNO_1'];
        if (operador1 == null || operador1.trim().isEmpty) {
          return 'El operador del turno 1 es obligatorio';
        }

        // Solo letras y espacios en nombres
        final soloLetras = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
        for (int i = 1; i <= 3; i++) {
          final nombre = _formData['OPERADOR_TURNO_$i'];
          if (nombre != null && nombre.isNotEmpty) {
            if (!soloLetras.hasMatch(nombre.trim())) {
              return 'El nombre del operador $i solo puede contener letras';
            }
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

  void _nextStep() {
    final error = _validateCurrentStep();
    if (error == null) {
      if (_currentStep < 5) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _showSnackbar(error, isError: true);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  Future<void> _guardar() async {
    final error = _validateCurrentStep();
    if (error != null) {
      _showSnackbar(error, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token!;

      // ── Operadores ──────────────────────────────────────────────
      final operadores = <Map<String, dynamic>>[];
      for (int turno = 1; turno <= 3; turno++) {
        final nombre = _formData['OPERADOR_TURNO_$turno'];
        if (nombre != null && nombre.trim().isNotEmpty) {
          operadores.add({
            'nombre': nombre.trim(),   // ← 'nombre' no 'nombre_operador'
            'turno': turno,            // ← int no String
          });
        }
      }

      // ── Bombeos ──────────────────────────────────────────────────
      final bombeos = <Map<String, dynamic>>[];
      for (final bomba in widget.estacion.bombas) {
        final encendido = _formData['bomba_${bomba.id}_encendido'];
        final apagado   = _formData['bomba_${bomba.id}_apagado'];
        final horIni    = _formData['bomba_${bomba.id}_horometro_inicial'];
        final horFin    = _formData['bomba_${bomba.id}_horometro_final'];

        if (encendido != null && apagado != null) {
          final hoy = DateTime.now();
          final partsEnc = encendido.split(':');
          final partsApa = apagado.split(':');

          bombeos.add({
            'bomba_id': bomba.id,
            'encendido': DateTime(hoy.year, hoy.month, hoy.day,
                int.parse(partsEnc[0]), int.parse(partsEnc[1])).toIso8601String(),
            'apagado': DateTime(hoy.year, hoy.month, hoy.day,
                int.parse(partsApa[0]), int.parse(partsApa[1])).toIso8601String(),
            'horometro_inicial': horIni != null ? double.tryParse(horIni) : null,
            'horometro_final':   horFin != null ? double.tryParse(horFin) : null,
          });
        }
      }

      // ── Tableros ─────────────────────────────────────────────────
      final tableros = [
        {'nombre': 'Tablero General', 'estado': _formData['TABLERO_GENERAL_ESTADO'] ?? 'OK'},
        {'nombre': 'Tablero Bomba 1', 'estado': _formData['TABLERO_BOMBA_1_ESTADO'] ?? 'OK'},
        {'nombre': 'Tablero Bomba 2', 'estado': _formData['TABLERO_BOMBA_2_ESTADO'] ?? 'OK'},
      ];

      // ── Payload final ────────────────────────────────────────────
      final payload = {
        'estacion_id':           widget.estacion.id.toString(),
        'fecha_folio':           DateTime.now().toIso8601String().substring(0, 10),
        'totalizador_inicial':   double.tryParse(_formData['TOTALIZADOR_INICIAL'] ?? '0') ?? 0.0,
        'totalizador_final':     double.tryParse(_formData['TOTALIZADOR_FINAL']   ?? '0') ?? 0.0,
        'lectura_inicial': {
          'nivel_cisterna':        _formData['NIVEL_CISTERNA_INICIAL'],
          'presion_linea':         _formData['PRESION_LINEA_INICIAL'],
          'totalizador':           _formData['TOTALIZADOR_INICIAL'],
          'presion_jatun_huaylla': _formData['PRESION_CISTERNA_INICIAL'],
        },
        'lectura_final': {
          'nivel_cisterna':        _formData['NIVEL_CISTERNA_FINAL'],
          'presion_linea':         _formData['PRESION_LINEA_FINAL'],
          'totalizador':           _formData['TOTALIZADOR_FINAL'],
          'presion_jatun_huaylla': _formData['PRESION_CISTERNA_FINAL'],
        },
        'bombeos':   bombeos,    // ← era 'detallesBombeo'
        'tableros':  tableros,   // ← nuevo campo requerido
        'operadores': operadores,
        // ← eliminados: produccion_calculada, observaciones
      };

      final result = await OperacionService.registrar(
        token: token,
        payload: payload,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackbar('✓ Registro guardado correctamente');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackbar(result['message']?.toString() ?? 'Error al guardar', isError: true);
      }
    } catch (e) {
      if (mounted) _showSnackbar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Registro de Operación',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
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
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: Colors.white,
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade300,
                        ),
                      ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.primaryColor
                            : isActive
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted || isActive
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Icon(
                              _stepIcons[index],
                              color: isActive ? AppTheme.primaryColor : Colors.grey.shade400,
                              size: 18,
                            ),
                    ),
                    if (index < _stepTitles.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _stepTitles[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive || isCompleted 
                        ? Colors.black87 
                        : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Paso ${_currentStep + 1} de ${_stepTitles.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String label,
    required String key,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    String? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            initialValue: readOnly ? _formData[key] : null,
            onChanged: readOnly ? null : (value) => _formData[key] = value,
            decoration: InputDecoration(
              hintText: hint ?? 'Ingrese $label',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              suffixText: suffix,
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(String label, String key) {
    final options = ['OK', 'Defectuoso', 'Revisión'];
    final selectedValue = _formData[key] ?? 'OK';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _formData[key] = option),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 1: Inspección
  Widget _buildInspeccionStep() {
    return _buildStepContainer(
      title: 'Inspección del Sistema',
      icon: Icons.search_rounded,
      children: [
        _buildModernTextField(
          label: 'SPAU 110C',
          key: 'SPAU_110C',
          icon: Icons.check_circle_outline,
          hint: 'Estado del componente',
        ),
        _buildModernTextField(
          label: 'SPAU 111C',
          key: 'SPAU_111C',
          icon: Icons.check_circle_outline,
          hint: 'Estado del componente',
        ),
        _buildModernTextField(
          label: 'SPAU 180 C P-1',
          key: 'SPAU_180_C_P_1',
          icon: Icons.check_circle_outline,
          hint: 'Estado del componente',
        ),
        _buildModernTextField(
          label: 'SPAU 180 C E-1',
          key: 'SPAU_180_C_E_1',
          icon: Icons.check_circle_outline,
          hint: 'Estado del componente',
        ),
      ],
    );
  }

  // Step 2: Habilitación
  Widget _buildHabilitacionStep() {
    return _buildStepContainer(
      title: 'Habilitación de Equipos',
      icon: Icons.settings_input_component_rounded,
      children: [
        _buildStatusSelector('Tablero General', 'TABLERO_GENERAL_ESTADO'),
        _buildStatusSelector('Tablero Bomba 1', 'TABLERO_BOMBA_1_ESTADO'),
        _buildStatusSelector('Tablero Bomba 2', 'TABLERO_BOMBA_2_ESTADO'),
      ],
    );
  }

  // Step 3: Lectura Inicial
  Widget _buildLecturaInicialStep() {
    return _buildStepContainer(
      title: 'Lectura Inicial',
      icon: Icons.play_circle_outline_rounded,
      children: [
        _buildModernTextField(
          label: 'Nivel Cisterna',
          key: 'NIVEL_CISTERNA_INICIAL',
          icon: Icons.water_drop_outlined,
          keyboardType: TextInputType.number,
          suffix: 'm',
        ),
        _buildModernTextField(
          label: 'Presión Línea',
          key: 'PRESION_LINEA_INICIAL',
          icon: Icons.speed,
          keyboardType: TextInputType.number,
          suffix: 'bar',
        ),
        _buildModernTextField(
          label: 'Totalizador',
          key: 'TOTALIZADOR_INICIAL',
          icon: Icons.analytics_outlined,
          keyboardType: TextInputType.number,
          suffix: 'm³',
        ),
        _buildModernTextField(
          label: 'Presión Cisterna',
          key: 'PRESION_CISTERNA_INICIAL',
          icon: Icons.compress,
          keyboardType: TextInputType.number,
          suffix: 'bar',
        ),
      ],
    );
  }

  // Step 4: Bombas
  Widget _buildBombasStep() {
    return _buildStepContainer(
      title: 'Control de Bombas',
      icon: Icons.water_damage_rounded,
      children: widget.estacion.bombas.map((bomba) => _buildBombaCard(bomba)).toList(),
    );
  }

  Widget _buildBombaCard(BombaModel bomba) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.water_damage_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                bomba.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  label: 'Encendido',
                  key: 'bomba_${bomba.id}_encendido',
                  icon: Icons.play_arrow,
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _formData['bomba_${bomba.id}_encendido'] =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernTextField(
                  label: 'Apagado',
                  key: 'bomba_${bomba.id}_apagado',
                  icon: Icons.stop,
                  readOnly: true,
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _formData['bomba_${bomba.id}_apagado'] =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildModernTextField(
                  label: 'Horómetro Inicial',
                  key: 'bomba_${bomba.id}_horometro_inicial',
                  icon: Icons.av_timer,
                  keyboardType: TextInputType.number,
                  suffix: 'h',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernTextField(
                  label: 'Horómetro Final',
                  key: 'bomba_${bomba.id}_horometro_final',
                  icon: Icons.av_timer,
                  keyboardType: TextInputType.number,
                  suffix: 'h',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 5: Lectura Final
  Widget _buildLecturaFinalStep() {
    return _buildStepContainer(
      title: 'Lectura Final',
      icon: Icons.stop_circle_outlined,
      children: [
        _buildModernTextField(
          label: 'Nivel Cisterna',
          key: 'NIVEL_CISTERNA_FINAL',
          icon: Icons.water_drop_outlined,
          keyboardType: TextInputType.number,
          suffix: 'm',
        ),
        _buildModernTextField(
          label: 'Presión Línea',
          key: 'PRESION_LINEA_FINAL',
          icon: Icons.speed,
          keyboardType: TextInputType.number,
          suffix: 'bar',
        ),
        _buildModernTextField(
          label: 'Totalizador',
          key: 'TOTALIZADOR_FINAL',
          icon: Icons.analytics_outlined,
          keyboardType: TextInputType.number,
          suffix: 'm³',
        ),
        _buildModernTextField(
          label: 'Presión Cisterna',
          key: 'PRESION_CISTERNA_FINAL',
          icon: Icons.compress,
          keyboardType: TextInputType.number,
          suffix: 'bar',
        ),
      ],
    );
  }

  // Step 6: Operadores
  Widget _buildOperadoresStep() {
    return _buildStepContainer(
      title: 'Información Final',
      icon: Icons.people_rounded,
      children: [
        _buildModernTextField(
          label: 'Operador Turno 1',
          key: 'OPERADOR_TURNO_1',
          icon: Icons.person,
        ),
        _buildModernTextField(
          label: 'Operador Turno 2 (Opcional)',
          key: 'OPERADOR_TURNO_2',
          icon: Icons.person_outline,
        ),
        _buildModernTextField(
          label: 'Operador Turno 3 (Opcional)',
          key: 'OPERADOR_TURNO_3',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 8),
        const Divider(height: 32),
        const SizedBox(height: 8),
        _buildModernTextField(
          label: 'Total Producción',
          key: 'TOTAL_PRODUCCION',
          icon: Icons.show_chart,
          keyboardType: TextInputType.number,
          suffix: 'm³',
        ),
        _buildModernTextField(
          label: 'Horas Bombeo Total',
          key: 'HORAS_BOMBEO_TOTAL',
          icon: Icons.timer,
          keyboardType: TextInputType.number,
          suffix: 'h',
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Observaciones',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 4,
                onChanged: (value) => _formData['OBSERVACIONES'] = value,
                decoration: InputDecoration(
                  hintText: 'Ingrese observaciones adicionales...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Atrás',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : _currentStep == 5
                        ? _guardar
                        : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep == 5 ? 'Guardar Registro' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}