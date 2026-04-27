import 'package:flutter/material.dart';

class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key});

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _initialized = false;

  static const Color _primary = Color(0xFF0057B8);

  // Campos por estación — AQUÍ defines los campos reales cuando me digas los nombres
  static const Map<int, List<Map<String, dynamic>>> _camposPorEstacion = {
    1: [
      {'label': 'Campo 1', 'hint': 'Ingresa valor', 'tipo': 'numero'},
      {'label': 'Campo 2', 'hint': 'Ingresa valor', 'tipo': 'numero'},
    ],
    2: [
      {'label': 'Campo A', 'hint': 'Ingresa valor', 'tipo': 'numero'},
      {'label': 'Campo B', 'hint': 'Ingresa valor', 'tipo': 'numero'},
    ],
    3: [
      {'label': 'Campo X', 'hint': 'Ingresa valor', 'tipo': 'numero'},
    ],
    4: [
      {'label': 'Campo Y', 'hint': 'Ingresa valor', 'tipo': 'numero'},
      {'label': 'Campo Z', 'hint': 'Ingresa valor', 'tipo': 'texto'},
    ],
  };

  late int _estacionId;
  late String _estacionNombre;
  late List<Map<String, dynamic>> _campos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
      _estacionId = args['estacionId'];
      _estacionNombre = args['estacionNombre'];
      _campos = _camposPorEstacion[_estacionId] ?? [];
      for (final campo in _campos) {
        _controllers[campo['label']] = TextEditingController();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  void _enviar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Aquí irá el DataService.enviar() en el siguiente paso
      await Future.delayed(const Duration(seconds: 1)); // simulado

      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Datos registrados correctamente'),
          ]),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Limpiar formulario
      for (final c in _controllers.values) c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _estacionNombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/historial',
                arguments: {
                  'estacionId': _estacionId,
                  'estacionNombre': _estacionNombre,
                }),
            icon: const Icon(Icons.history, color: Colors.white, size: 18),
            label: const Text('Historial',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _primary.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: _primary),
                    const SizedBox(width: 8),
                    Text(
                      'Registro: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 12, color: _primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Campos dinámicos
              ..._campos.map((campo) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campo['label'].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _controllers[campo['label']],
                          keyboardType: campo['tipo'] == 'numero'
                              ? const TextInputType.numberWithOptions(
                                  decimal: true)
                              : TextInputType.text,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: campo['hint'],
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 14),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE0E0E0), width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: _primary, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFC62828), width: 1),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Este campo es requerido'
                              : null,
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Guardar registro',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}