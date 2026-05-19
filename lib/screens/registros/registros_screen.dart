import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool _isLoading = true;
  String? _error;

  final int _anioActual = DateTime.now().year;
  late int _anioSeleccionado;
  int? _mesSeleccionado;

  // ── Estado filtros avanzados ─────────────────────────────────────────────────
  bool _modoAvanzado = false;

  static const _meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  // ── Colores ──────────────────────────────────────────────────────────────────
  static const Color _primary     = Color(0xFF0D47A1);
  static const Color _accent      = Color(0xFF00BCD4);
  static const Color _surface     = Color(0xFFF8FAFF);
  static const Color _cardBg      = Colors.white;
  static const Color _textPrimary = Color(0xFF0A1628);
  static const Color _textSec     = Color(0xFF5C6B8A);
  static const Color _border      = Color(0xFFDDE3F0);
  static const Color _success     = Color(0xFF00897B);
  static const Color _warning     = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    _anioSeleccionado = _anioActual;
    _mesSeleccionado  = DateTime.now().month;
    _cargar();
  }

  // ── Carga ────────────────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final token = context.read<AuthProvider>().token ?? '';

      final resultado = await OperacionService.getOperaciones(
        token: token,
        anio:  _anioSeleccionado.toString(),
        mes:   _mesSeleccionado?.toString(),
      );

      if (!mounted) return;
      setState(() {
        _operaciones = resultado;
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

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _formatFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';

  String _formatNum(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.$decPart';
  }

  // ── Lógica de filtros rápidos ────────────────────────────────────────────────
  bool _esSeleccionHoy() {
    if (_modoAvanzado) return false;
    final hoy = DateTime.now();
    return _mesSeleccionado == hoy.month && _anioSeleccionado == hoy.year;
  }

  bool _esSeleccionAyer() {
    // Implementar si tu API soporta filtro por día
    return false;
  }

  bool _esSeleccionEsteMes() {
    if (_modoAvanzado) return false;
    final hoy = DateTime.now();
    return _mesSeleccionado == hoy.month && _anioSeleccionado == hoy.year;
  }

  void _seleccionarHoy() {
    final hoy = DateTime.now();
    setState(() {
      _anioSeleccionado = hoy.year;
      _mesSeleccionado  = hoy.month;
      _modoAvanzado     = false;
    });
    _cargar();
  }

  void _seleccionarAyer() {
    final ayer = DateTime.now().subtract(const Duration(days: 1));
    setState(() {
      _anioSeleccionado = ayer.year;
      _mesSeleccionado  = ayer.month;
      _modoAvanzado     = false;
    });
    _cargar();
  }

  void _seleccionarEsteMes() {
    final hoy = DateTime.now();
    setState(() {
      _anioSeleccionado = hoy.year;
      _mesSeleccionado  = hoy.month;
      _modoAvanzado     = false;
    });
    _cargar();
  }

  String _etiquetaSeleccionAvanzada() {
    if (!_modoAvanzado) return 'Más...';
    final mesNombre = _meses[(_mesSeleccionado ?? 1) - 1];
    return '$mesNombre $_anioSeleccionado';
  }

  void _mostrarSelectorAvanzado() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _buildBottomSheetAvanzado(),
    );
  }

  Widget _buildBottomSheetAvanzado() {
    // Usamos StatefulBuilder para que el setState dentro del sheet funcione
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
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
                  color: _textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Selector de año
            Row(children: [
              const Text('Año:',
                  style: TextStyle(color: _textSec, fontSize: 14)),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _anioSeleccionado,
                items: List.generate(5, (i) => _anioActual - i)
                    .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _anioSeleccionado = v);
                    setSheetState(() {});
                  }
                },
              ),
            ]),
            const SizedBox(height: 8),

            // Grid de meses
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (i) {
                final mes = i + 1;
                final sel = _mesSeleccionado == mes;
                return GestureDetector(
                  onTap: () {
                    setState(() => _mesSeleccionado = mes);
                    setSheetState(() {});
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _primary : _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel ? _primary : _border),
                    ),
                    child: Text(
                      _meses[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: sel ? Colors.white : _textSec,
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
                  setState(() => _modoAvanzado = true);
                  Navigator.pop(context);
                  _cargar();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Ver registros',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
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

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final completos  = _operaciones.where((o) => o.esCompleto).length;
    final pendientes = _operaciones.where((o) => !o.esCompleto).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis Registros',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (_operaciones.isNotEmpty)
                  Row(children: [
                    if (completos > 0) ...[
                      _buildResumenBadge(
                        icon: Icons.check_circle_rounded,
                        label:
                        '$completos completo${completos == 1 ? '' : 's'}',
                        color: _success,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (pendientes > 0)
                      _buildResumenBadge(
                        icon: Icons.pending_rounded,
                        label:
                        '$pendientes pendiente${pendientes == 1 ? '' : 's'}',
                        color: _warning,
                      ),
                  ])
                else if (!_isLoading)
                  Text(
                    'Sin registros para este período',
                    style: TextStyle(
                        color: Colors.white.withAlpha(179), fontSize: 13),
                  ),
              ]),
        ),
      ),
    );
  }

  Widget _buildResumenBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(64)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  Widget _buildFiltrosMes() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _buildChipRapido(
              label: 'Hoy',
              icon: Icons.today_rounded,
              isSelected: _esSeleccionHoy(),
              onTap: _seleccionarHoy,
            ),
            const SizedBox(width: 8),
            _buildChipRapido(
              label: 'Ayer',
              icon: Icons.history_rounded,
              isSelected: _esSeleccionAyer(),
              onTap: _seleccionarAyer,
            ),
            const SizedBox(width: 8),
            _buildChipRapido(
              label: 'Este mes',
              icon: Icons.calendar_month_rounded,
              isSelected: _esSeleccionEsteMes(),
              onTap: _seleccionarEsteMes,
            ),
            const Spacer(),
            GestureDetector(
              onTap: _mostrarSelectorAvanzado,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: Colors.white.withAlpha(60)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.tune_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _etiquetaSeleccionAvanzada(),
                    style: TextStyle(
                      color: Colors.white.withAlpha(220),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildChipRapido({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
          isSelected ? Colors.white : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withAlpha(64),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            icon,
            size: 13,
            color: isSelected
                ? _primary
                : Colors.white.withAlpha(204),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: isSelected
                  ? _primary
                  : Colors.white.withAlpha(204),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Cuerpo ───────────────────────────────────────────────────────────────────
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
                Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _textSec)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _cargar,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary),
                ),
              ]),
        ),
      );
    }

    if (_operaciones.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 60, color: _textSec.withAlpha(77)),
              const SizedBox(height: 16),
              const Text('Sin registros para este período',
                  style: TextStyle(
                      fontSize: 16,
                      color: _textSec,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('Prueba seleccionando otro mes o año.',
                  style: TextStyle(
                      fontSize: 13,
                      color: _textSec.withAlpha(179))),
            ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _operaciones.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _buildCard(_operaciones[index]),
        ),
      ),
    );
  }

  // ── Tarjeta ──────────────────────────────────────────────────────────────────
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

    final produccionValida =
        op.esCompleto && op.produccionCalculada >= 0;

    final folioStr = op.id != null ? '#${op.id}' : '';

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header tarjeta ──
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primary.withAlpha(18),
                    _accent.withAlpha(8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                border:
                Border(bottom: BorderSide(color: _border)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF1565C0)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.water_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(
                              op.estacion.nombre,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (folioStr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primary.withAlpha(18),
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text(
                                folioStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color:
                                  _primary.withAlpha(200),
                                ),
                              ),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 2),
                        Text(
                          _formatFecha(op.fechaFolio),
                          style: const TextStyle(
                              fontSize: 12, color: _textSec),
                        ),
                      ]),
                ),

                if (produccionValida) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _success.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _success.withAlpha(77)),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop_rounded,
                              size: 13, color: _success),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatNum(op.produccionCalculada)} m³',
                            style: const TextStyle(
                                fontSize: 12,
                                color: _success,
                                fontWeight: FontWeight.w700),
                          ),
                        ]),
                  ),
                  const SizedBox(width: 8),
                ],

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: op.esCompleto
                        ? _success.withAlpha(26)
                        : _warning.withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: op.esCompleto
                          ? _success.withAlpha(77)
                          : _warning.withAlpha(77),
                    ),
                  ),
                  child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          op.esCompleto
                              ? Icons.check_circle_rounded
                              : Icons.pending_rounded,
                          size: 13,
                          color: op.esCompleto
                              ? _success
                              : _warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          op.esCompleto ? 'Completo' : 'Inicial',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: op.esCompleto
                                ? _success
                                : _warning,
                          ),
                        ),
                      ]),
                ),
              ]),
            ),

            // ── Body tarjeta ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  _buildMetric(
                    icon: Icons.analytics_outlined,
                    label: 'Totalizador ini.',
                    value:
                    '${_formatNum(op.totalizadorInicial)} m³',
                    color: _primary,
                  ),
                  _buildDivider(),
                  _buildMetric(
                    icon: Icons.analytics_rounded,
                    label: 'Totalizador fin.',
                    value: op.esCompleto
                        ? '${_formatNum(op.totalizadorFinal)} m³'
                        : '—',
                    color: _primary,
                  ),
                  _buildDivider(),
                  _buildMetric(
                    icon: Icons.timer_outlined,
                    label: 'Hrs bombeo',
                    value: totalHorasBombeo > 0
                        ? '${_formatNum(totalHorasBombeo)} h'
                        : '—',
                    color: _accent,
                  ),
                ]),

                if (operador1 != '—' ||
                    bombasNombres.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: _border),
                  const SizedBox(height: 12),
                ],

                if (operador1 != '—')
                  _buildInfoRow(
                    icon: Icons.person_rounded,
                    label: 'Operador',
                    value: operador1,
                  ),

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
        Icon(icon, size: 18, color: color.withAlpha(179)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
    return Container(
        width: 1,
        height: 40,
        color: _border,
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
        Icon(icon, size: 15, color: _textSec.withAlpha(153)),
        const SizedBox(width: 8),
        Text('$label: ',
            style:
            const TextStyle(fontSize: 12, color: _textSec)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}