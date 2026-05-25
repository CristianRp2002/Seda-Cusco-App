import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/operacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/operacion_service.dart';
import '../formulario/formulario_screen.dart';
import 'constants/registros_colors.dart';
import 'utils/registros_utils.dart';
import 'widgets/filtros_mes_widget.dart';
import 'widgets/registros_header.dart';
import 'widgets/registro_card.dart';

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

enum EstadoFiltro { todos, completos, pendientes }

class _RegistrosScreenState extends State<RegistrosScreen> {
  List<OperacionModel> _operaciones = [];
  bool _isLoading = true;
  String? _error;

  final int _anioActual = DateTime.now().year;
  late int _anioSeleccionado;
  int? _mesSeleccionado;
  bool _modoAvanzado = false;

  // ✅ NUEVO: Filtro por estado
  EstadoFiltro _estadoFiltro = EstadoFiltro.todos;

  @override
  void initState() {
    super.initState();
    _anioSeleccionado = _anioActual;
    _mesSeleccionado = DateTime.now().month;
    _cargar();
  }

  // ── Carga
  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token ?? '';

      final resultado = await OperacionService.getOperaciones(
        token: token,
        anio: _anioSeleccionado.toString(),
        mes: _mesSeleccionado?.toString(),
      );

      if (!mounted) return;
      setState(() {
        _operaciones = resultado;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar registros: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ NUEVO: Filtrar operaciones por estado
  List<OperacionModel> _getOperacionesFiltradas() {
    switch (_estadoFiltro) {
      case EstadoFiltro.completos:
        return _operaciones.where((o) => o.esCompleto).toList();
      case EstadoFiltro.pendientes:
        return _operaciones.where((o) => !o.esCompleto).toList();
      case EstadoFiltro.todos:
      default:
        return _operaciones;
    }
  }

  // ── Lógica de filtros rápidos
  bool _esSeleccionHoy() {
    if (_modoAvanzado) return false;
    final hoy = DateTime.now();
    return _mesSeleccionado == hoy.month &&
        _anioSeleccionado == hoy.year;
  }

  bool _esSeleccionAyer() {
    if (_modoAvanzado) return false;
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    return _mesSeleccionado == ayer.month &&
        _anioSeleccionado == ayer.year;
  }

  bool _esSeleccionEsteMes() {
    if (_modoAvanzado) return false;
    final hoy = DateTime.now();
    return _mesSeleccionado == hoy.month &&
        _anioSeleccionado == hoy.year;
  }

  void _seleccionarHoy() {
    final hoy = DateTime.now();
    setState(() {
      _anioSeleccionado = hoy.year;
      _mesSeleccionado = hoy.month;
      _modoAvanzado = false;
    });
    _cargar();
  }

  void _seleccionarAyer() {
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _anioSeleccionado = ayer.year;
      _mesSeleccionado = ayer.month;
      _modoAvanzado = false;
    });
    _cargar();
  }

  void _seleccionarEsteMes() {
    final hoy = DateTime.now();
    setState(() {
      _anioSeleccionado = hoy.year;
      _mesSeleccionado = hoy.month;
      _modoAvanzado = false;
    });
    _cargar();
  }

  String _etiquetaSeleccionAvanzada() {
    if (!_modoAvanzado) return 'Más...';
    final mesNombre = RegistrosUtils.getMesNombre(_mesSeleccionado ?? 1);
    return '$mesNombre $_anioSeleccionado';
  }

  void _mostrarSelectorAvanzado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BottomSheetAvanzado(
        anioActual: _anioActual,
        anioSeleccionado: _anioSeleccionado,
        mesSeleccionado: _mesSeleccionado ?? 1,
        onAplica: (anio, mes) {
          setState(() {
            _anioSeleccionado = anio;
            _mesSeleccionado = mes;
            _modoAvanzado = true;
          });
          Navigator.pop(context);
          _cargar();
        },
      ),
    );
  }

  Future<void> _abrirFormulario(OperacionModel op) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final token = context.read<AuthProvider>().token ?? '';
      final estacion = await OperacionService.getEstacion(
        token: token,
        estacionId: op.estacion.id,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (estacion == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la estación'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormularioScreen(
            estacion: estacion,
            operacionExistente: op,
          ),
        ),
      );
      _cargar();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegistrosColors.surface,
      body: Column(
        children: [
          RegistrosHeader(
            operaciones: _operaciones,
            isLoading: _isLoading,
          ),
          FiltrosMesWidget(
            onSeleccionarHoy: _seleccionarHoy,
            onSeleccionarAyer: _seleccionarAyer,
            onSeleccionarEsteMes: _seleccionarEsteMes,
            onMostrarSelectorAvanzado: _mostrarSelectorAvanzado,
            etiquetaAvanzada: _etiquetaSeleccionAvanzada(),
            isHoySeleccionado: _esSeleccionHoy(),
            isAyerSeleccionado: _esSeleccionAyer(),
            isEstesMesSeleccionado: _esSeleccionEsteMes(),
          ),
          // ✅ NUEVO: Filtro por estado
          _buildFiltroEstado(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ✅ NUEVO: Widget para filtrar por estado
  Widget _buildFiltroEstado() {
    return Container(
      color: RegistrosColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildBotonFiltroEstado(
              label: 'Todos',
              isSelected: _estadoFiltro == EstadoFiltro.todos,
              onTap: () => setState(() => _estadoFiltro = EstadoFiltro.todos),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBotonFiltroEstado(
              label: 'Completos',
              isSelected: _estadoFiltro == EstadoFiltro.completos,
              onTap: () => setState(() => _estadoFiltro = EstadoFiltro.completos),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBotonFiltroEstado(
              label: 'Pendientes',
              isSelected: _estadoFiltro == EstadoFiltro.pendientes,
              onTap: () => setState(() => _estadoFiltro = EstadoFiltro.pendientes),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltroEstado({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withAlpha(64),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? RegistrosColors.primary
                  : Colors.white.withAlpha(204),
            ),
          ),
        ),
      ),
    );
  }

  // ── Cuerpo
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RegistrosColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RegistrosColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ MEJORADO: Usar operaciones filtradas
    final operacionesFiltradas = _getOperacionesFiltradas();

    if (operacionesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 60,
              color: RegistrosColors.textSecondary.withAlpha(77),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin registros para este período',
              style: TextStyle(
                fontSize: 16,
                color: RegistrosColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba seleccionando otro mes o año.',
              style: TextStyle(
                fontSize: 13,
                color: RegistrosColors.textSecondary.withAlpha(179),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: operacionesFiltradas.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: RegistroCard(
            operacion: operacionesFiltradas[index],
            onCargar: _cargar,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetAvanzado extends StatefulWidget {
  final int anioActual;
  final int anioSeleccionado;
  final int mesSeleccionado;
  final Function(int anio, int mes) onAplica;

  const _BottomSheetAvanzado({
    required this.anioActual,
    required this.anioSeleccionado,
    required this.mesSeleccionado,
    required this.onAplica,
  });

  @override
  State<_BottomSheetAvanzado> createState() => _BottomSheetAvanzadoState();
}

class _BottomSheetAvanzadoState extends State<_BottomSheetAvanzado> {
  late int _anioTemp;
  late int _mesTemp;

  @override
  void initState() {
    super.initState();
    _anioTemp = widget.anioSeleccionado;
    _mesTemp = widget.mesSeleccionado;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: RegistrosColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Buscar por período',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: RegistrosColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de año
          Row(
            children: [
              const Text(
                'Año:',
                style: TextStyle(
                  color: RegistrosColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _anioTemp,
                items: List.generate(5, (i) => widget.anioActual - i)
                    .map((a) => DropdownMenuItem(
                  value: a,
                  child: Text('$a'),
                ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _anioTemp = v);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Grid de meses
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (i) {
              final mes = i + 1;
              final estaSeleccionado = _mesTemp == mes;
              return GestureDetector(
                onTap: () {
                  setState(() => _mesTemp = mes);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: estaSeleccionado
                        ? RegistrosColors.primary
                        : RegistrosColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: estaSeleccionado
                          ? RegistrosColors.primary
                          : RegistrosColors.border,
                    ),
                  ),
                  child: Text(
                    RegistrosUtils.getMesNombre(mes),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: estaSeleccionado
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: estaSeleccionado
                          ? Colors.white
                          : RegistrosColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onAplica(_anioTemp, _mesTemp);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: RegistrosColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Ver registros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}