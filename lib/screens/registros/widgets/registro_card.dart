import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/operacion_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/operacion_service.dart';
import '../../formulario/formulario_screen.dart';
import '../constants/registros_colors.dart';
import '../utils/registros_utils.dart';

class RegistroCard extends StatelessWidget {
  final OperacionModel operacion;
  final VoidCallback onCargar;

  const RegistroCard({
    super.key,
    required this.operacion,
    required this.onCargar,
  });

  @override
  Widget build(BuildContext context) {
    final operador1 = _obtenerOperador();
    final totalHorasBombeo = _calcularHorasBombeo();
    final bombasNombres = _obtenerBombas();
    final produccionValida =
        operacion.esCompleto && operacion.produccionCalculada >= 0;
    final folioStr = operacion.id != null ? '#${operacion.id}' : '';

    return GestureDetector(
      onTap: operacion.esCompleto ? null : () => _abrirFormulario(context),
      child: Container(
        decoration: BoxDecoration(
          color: RegistrosColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: RegistrosColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: RegistrosColors.primary.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(folioStr, produccionValida),
            if (!operacion.esCompleto) _buildPendingWarning(),
            _buildCardBody(operador1, totalHorasBombeo, bombasNombres),
          ],
        ),
      ),
    );
  }

  String _obtenerOperador() {
    if (operacion.operadores.isEmpty) return '—';
    try {
      return operacion.operadores
          .firstWhere((o) => o.turno == '1')
          .nombreOperador;
    } catch (_) {
      return operacion.operadores.first.nombreOperador;
    }
  }

  double _calcularHorasBombeo() {
    return operacion.detallesBombeo.fold<double>(0, (sum, b) => sum + b.horasBombeo);
  }

  String _obtenerBombas() {
    return operacion.detallesBombeo
        .map((b) => b.nombreBomba ?? 'Bomba')
        .toSet()
        .join(', ');
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    // Mostrar loading
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
        estacionId: operacion.estacion.id,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // cierra el loading

      if (estacion == null) {
        _mostrarError(context, 'No se pudo cargar la estación');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FormularioScreen(
            estacion: estacion,
            operacionExistente: operacion,
          ),
        ),
      );

      onCargar();
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _mostrarError(context, 'Error: $e');
    }
  }

  void _mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildCardHeader(String folioStr, bool produccionValida) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RegistrosColors.primary.withAlpha(18),
            RegistrosColors.accent.withAlpha(8),
          ],
        ),
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: RegistrosColors.border)),
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
                    operacion.estacion.nombre,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: RegistrosColors.textPrimary),
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
                      color: RegistrosColors.primary.withAlpha(18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      folioStr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: RegistrosColors.primary.withAlpha(200),
                      ),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                RegistrosUtils.formatFecha(operacion.fechaFolio),
                style: const TextStyle(
                    fontSize: 12, color: RegistrosColors.textSecondary),
              ),
            ],
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (produccionValida) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RegistrosColors.success.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: RegistrosColors.success.withAlpha(77)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.water_drop_rounded,
                    size: 13, color: RegistrosColors.success),
                const SizedBox(width: 4),
                Text(
                  '${RegistrosUtils.formatNum(operacion.produccionCalculada)} m³',
                  style: const TextStyle(
                      fontSize: 12,
                      color: RegistrosColors.success,
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
              color: operacion.esCompleto
                  ? RegistrosColors.success.withAlpha(26)
                  : RegistrosColors.warning.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: operacion.esCompleto
                    ? RegistrosColors.success.withAlpha(77)
                    : RegistrosColors.warning.withAlpha(77),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                operacion.esCompleto
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                size: 13,
                color: operacion.esCompleto
                    ? RegistrosColors.success
                    : RegistrosColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                operacion.esCompleto ? 'Completo' : 'Inicial',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: operacion.esCompleto
                      ? RegistrosColors.success
                      : RegistrosColors.warning,
                ),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPendingWarning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(children: [
        const Icon(Icons.edit_rounded, size: 13,
            color: RegistrosColors.warning),
        const SizedBox(width: 6),
        Text(
          'Toca para completar el registro',
          style: TextStyle(
            fontSize: 12,
            color: RegistrosColors.warning.withAlpha(200),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right_rounded,
            size: 16,
            color: RegistrosColors.warning.withAlpha(200)),
      ]),
    );
  }

  Widget _buildCardBody(
      String operador1, double totalHorasBombeo, String bombasNombres) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          _buildMetric(
            icon: Icons.analytics_outlined,
            label: 'Totalizador ini.',
            value: '${RegistrosUtils.formatNum(operacion.totalizadorInicial)} m³',
            color: RegistrosColors.primary,
          ),
          _buildDivider(),
          _buildMetric(
            icon: Icons.analytics_rounded,
            label: 'Totalizador fin.',
            value: operacion.esCompleto
                ? '${RegistrosUtils.formatNum(operacion.totalizadorFinal)} m³'
                : '—',
            color: RegistrosColors.primary,
          ),
          _buildDivider(),
          _buildMetric(
            icon: Icons.timer_outlined,
            label: 'Hrs bombeo',
            value: totalHorasBombeo > 0
                ? '${RegistrosUtils.formatNum(totalHorasBombeo)} h'
                : '—',
            color: RegistrosColors.accent,
          ),
        ]),
        if (operador1 != '—' || bombasNombres.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: RegistrosColors.border),
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
            style: const TextStyle(
                fontSize: 10, color: RegistrosColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildDivider() {
    return Container(
        width: 1,
        height: 40,
        color: RegistrosColors.border,
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
        Icon(icon, size: 15,
            color: RegistrosColors.textSecondary.withAlpha(153)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: RegistrosColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RegistrosColors.textPrimary),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}