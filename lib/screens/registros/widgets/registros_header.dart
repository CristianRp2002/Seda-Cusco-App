import 'package:flutter/material.dart';
import '../constants/registros_colors.dart';
import '../utils/registros_utils.dart';

class RegistrosHeader extends StatelessWidget {
  final List<dynamic> operaciones;
  final bool isLoading;

  const RegistrosHeader({
    super.key,
    required this.operaciones,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final completos =
        operaciones.where((o) => o.esCompleto).length;
    final pendientes =
        operaciones.where((o) => !o.esCompleto).length;

    return Container(
      decoration: const BoxDecoration(
        gradient: RegistrosColors.primaryGradient,
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
              if (operaciones.isNotEmpty)
                Row(
                  children: [
                    if (completos > 0) ...[
                      _buildResumenBadge(
                        icon: Icons.check_circle_rounded,
                        label:
                        '$completos completo${RegistrosUtils.getPluralSufijo(completos)}',
                        color: RegistrosColors.success,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (pendientes > 0)
                      _buildResumenBadge(
                        icon: Icons.pending_rounded,
                        label:
                        '$pendientes pendiente${RegistrosUtils.getPluralSufijo(pendientes)}',
                        color: RegistrosColors.warning,
                      ),
                  ],
                )
              else if (!isLoading)
                Text(
                  'Sin registros para este período',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 13,
                  ),
                ),
            ],
          ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }
}
