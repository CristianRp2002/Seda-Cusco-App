import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/operacion_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/operacion_service.dart';

class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key});

  @override
  State<RegistrosScreen> createState() => _RegistrosScreenState();
}

class _RegistrosScreenState extends State<RegistrosScreen> {
  List<OperacionModel> _operaciones = [];
  List<OperacionModel> _filtradas = [];
  bool _isLoading = true;
  String? _error;

  // Filtros
  final int _anioActual = DateTime.now().year;
  late int _anioSeleccionado;
  int? _mesSeleccionado;

  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  // Colores
  static const Color _primary      = Color(0xFF0D47A1);
  static const Color _accent       = Color(0xFF00BCD4);
  static const Color _surface      = Color(0xFFF8FAFF);
  static const Color _cardBg       = Colors.white;
  static const Color _textPrimary  = Color(0xFF0A1628);
  static const Color _textSec      = Color(0xFF5C6B8A);
  static const Color _border       = Color(0xFFDDE3F0);
  static const Color _success      = Color(0xFF00897B);

  @override
  void initState() {
    super.initState();
    _anioSeleccionado = _anioActual;
    _mesSeleccionado  = DateTime.now().month;
    _cargar();
  }

  // ── Carga de datos ─────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final token = context.read<AuthProvider>().token ?? '';

      final resultado = await OperacionService.getOperaciones(
        token: token,
        anio:  _anioSeleccionado.toString(),
        mes:   _mesSeleccionado != null ? _mesSeleccionado.toString() : null,
      );

      if (!mounted) return;
      setState(() {
        _operaciones = resultado;
        _filtradas   = resultado;
        _isLoading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Error al cargar registros: $e';
        _isLoading = false;
      });
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _formatNum(double n) => n.toStringAsFixed(2);

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(children: [
        _buildHeader(),
        _buildFiltrosMes(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(
                child: Text(
                  'Mis Registros',
                  style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
              ),
              // Selector de año
              _buildAnioSelector(),
            ]),
            const SizedBox(height: 4),
            Text(
              '${_operaciones.length} parte${_operaciones.length == 1 ? '' : 's'} encontrado${_operaciones.length == 1 ? '' : 's'}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAnioSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _anioSeleccionado,
          dropdownColor: const Color(0xFF0D47A1),
          style: const TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w600),
          icon: const Icon(Icons.expand_more_rounded, color: Colors.white, size: 18),
          isDense: true,
          items: List.generate(5, (i) => _anioActual - i)
              .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _anioSeleccionado = v);
              _cargar();
            }
          },
        ),
      ),
    );
  }

  // ── Filtro de meses ────────────────────────────────────────────────────────
  Widget _buildFiltrosMes() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Chip "Todos"
            _buildMesChip(label: 'Todos', isSelected: _mesSeleccionado == null,
                onTap: () {
                  setState(() => _mesSeleccionado = null);
                  _cargar();
                }),
            const SizedBox(width: 8),
            ...List.generate(12, (i) {
              final mes = i + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildMesChip(
                  label: _meses[i],
                  isSelected: _mesSeleccionado == mes,
                  onTap: () {
                    setState(() => _mesSeleccionado = mes);
                    _cargar();
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMesChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected ? _primary : Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  // ── Cuerpo principal ───────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline_rounded, size: 48,
                color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: _textSec)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
            ),
          ]),
        ),
      );
    }

    if (_filtradas.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.assignment_outlined, size: 60,
              color: _textSec.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Sin registros para este período',
              style: TextStyle(fontSize: 16, color: _textSec,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Prueba seleccionando otro mes o año.',
              style: TextStyle(fontSize: 13,
                  color: _textSec.withOpacity(0.7))),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _filtradas.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _buildCard(_filtradas[index]),
          );
        },
      ),
    );
  }

  // ── Tarjeta de registro ────────────────────────────────────────────────────
  Widget _buildCard(OperacionModel op) {
    final operador1 = op.operadores.isNotEmpty
        ? op.operadores
        .firstWhere((o) => o.turno == '1',
        orElse: () => op.operadores.first)
        .nombreOperador
        : '—';

    final totalHorasBombeo = op.detallesBombeo
        .fold<double>(0, (sum, b) => sum + b.horasBombeo);

    final bombasNombres = op.detallesBombeo
        .map((b) => b.nombreBomba ?? 'Bomba')
        .toSet()
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header tarjeta ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary.withOpacity(0.07), _accent.withOpacity(0.03)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.water_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  op.estacion.nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: _textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatFecha(op.fechaFolio),
                  style: const TextStyle(fontSize: 12, color: _textSec),
                ),
              ]),
            ),
            // Badge producción
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _success.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.water_drop_rounded, size: 13, color: _success),
                const SizedBox(width: 4),
                Text(
                  '${_formatNum(op.produccionCalculada)} m³',
                  style: const TextStyle(fontSize: 12, color: _success,
                      fontWeight: FontWeight.w700),
                ),
              ]),
            ),
          ]),
        ),

        // ── Body tarjeta ──
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            // Fila métricas
            Row(children: [
              _buildMetric(
                icon: Icons.analytics_outlined,
                label: 'Totalizador ini.',
                value: '${_formatNum(op.totalizadorInicial)} m³',
                color: _primary,
              ),
              _buildDivider(),
              _buildMetric(
                icon: Icons.analytics_rounded,
                label: 'Totalizador fin.',
                value: '${_formatNum(op.totalizadorFinal)} m³',
                color: _primary,
              ),
              _buildDivider(),
              _buildMetric(
                icon: Icons.timer_outlined,
                label: 'Hrs bombeo',
                value: '${_formatNum(totalHorasBombeo)} h',
                color: _accent,
              ),
            ]),

            if (operador1 != '—' || bombasNombres.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 12),
            ],

            // Operador
            if (operador1 != '—')
              _buildInfoRow(
                icon: Icons.person_rounded,
                label: 'Operador',
                value: operador1,
              ),

            // Bombas
            if (bombasNombres.isNotEmpty)
              _buildInfoRow(
                icon: Icons.water_damage_rounded,
                label: 'Bombas',
                value: bombasNombres,
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: color),
            textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 10, color: _textSec),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: _border,
        margin: const EdgeInsets.symmetric(horizontal: 8));
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: _textSec.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: _textSec)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: _textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}