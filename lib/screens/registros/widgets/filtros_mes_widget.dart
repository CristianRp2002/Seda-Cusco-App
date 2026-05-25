import 'package:flutter/material.dart';
import '../constants/registros_colors.dart';
import '../utils/registros_utils.dart';

class FiltrosMesWidget extends StatelessWidget {
  final VoidCallback onSeleccionarHoy;
  final VoidCallback onSeleccionarAyer;
  final VoidCallback onSeleccionarEsteMes;
  final VoidCallback onMostrarSelectorAvanzado;
  final String etiquetaAvanzada;
  final bool isHoySeleccionado;
  final bool isAyerSeleccionado;
  final bool isEstesMesSeleccionado;

  const FiltrosMesWidget({
    super.key,
    required this.onSeleccionarHoy,
    required this.onSeleccionarAyer,
    required this.onSeleccionarEsteMes,
    required this.onMostrarSelectorAvanzado,
    required this.etiquetaAvanzada,
    this.isHoySeleccionado = false,
    this.isAyerSeleccionado = false,
    this.isEstesMesSeleccionado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RegistrosColors.primary,
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildChipRapido(
                  label: 'Hoy',
                  icon: Icons.today_rounded,
                  isSelected: isHoySeleccionado,
                  onTap: onSeleccionarHoy,
                ),
                const SizedBox(width: 8),
                _buildChipRapido(
                  label: 'Ayer',
                  icon: Icons.history_rounded,
                  isSelected: isAyerSeleccionado,
                  onTap: onSeleccionarAyer,
                ),
                const SizedBox(width: 8),
                _buildChipRapido(
                  label: 'Este mes',
                  icon: Icons.calendar_month_rounded,
                  isSelected: isEstesMesSeleccionado,
                  onTap: onSeleccionarEsteMes,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onMostrarSelectorAvanzado,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          etiquetaAvanzada,
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(64),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? RegistrosColors.primary
                  : Colors.white.withAlpha(204),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected
                    ? RegistrosColors.primary
                    : Colors.white.withAlpha(204),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
