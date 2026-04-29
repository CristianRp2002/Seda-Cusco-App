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

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return ['SPAU_110C', 'SPAU_111C', 'SPAU_180_C_P_1', 'SPAU_180_C_E_1']
            .every((key) => _formData[key]?.isNotEmpty ?? false);
      case 1:
        return ['TABLERO_GENERAL_ESTADO', 'TABLERO_BOMBA_1_ESTADO', 'TABLERO_BOMBA_2_ESTADO']
            .every((key) => _formData[key]?.isNotEmpty ?? false);
      case 2:
        return ['NIVEL_CISTERNA_INICIAL', 'PRESION_LINEA_INICIAL', 
                'TOTALIZADOR_INICIAL', 'PRESION_CISTERNA_INICIAL']
            .every((key) => _formData[key]?.isNotEmpty ?? false);
      case 3:
        return widget.estacion.bombas.every((bomba) =>
          (_formData['bomba_${bomba.id}_encendido']?.isNotEmpty ?? false) &&
          (_formData['bomba_${bomba.id}_apagado']?.isNotEmpty ?? false) &&
          (_formData['bomba_${bomba.id}_horometro_final']?.isNotEmpty ?? false)
        );
      case 4:
        return ['NIVEL_CISTERNA_FINAL', 'PRESION_LINEA_FINAL',
                'TOTALIZADOR_FINAL', 'PRESION_CISTERNA_FINAL']
            .every((key) => _formData[key]?.isNotEmpty ?? false);
      case 5:
        return ['OPERADOR_TURNO_1', 'TOTAL_PRODUCCION', 'HORAS_BOMBEO_TOTAL']
            .every((key) => _formData[key]?.isNotEmpty ?? false);
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 5) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _showSnackbar('Complete todos los campos requeridos', isError: true);
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
    if (!_validateCurrentStep()) {
      _showSnackbar('Complete todos los campos requeridos', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token!;
      final valores = <Map<String, dynamic>>[];

      // Build the payload from _formData
      for (final activo in widget.estacion.activos) {
        for (final campo in activo.tipoActivo.campos) {
          final key = '${activo.id}_${campo.id}';
          final valor = _formData[key];

          if (valor != null && valor.isNotEmpty) {
            valores.add({
              'campo_id': campo.id,
              'activo_id': activo.id,
              'valor': valor,
            });
          }
        }
      }

      final result = await OperacionService.registrar(
        token: token,
        estacionId: widget.estacion.id.toString(),
        valores: valores,
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
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', isError: true);
      }
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