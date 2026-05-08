import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/estacion_model.dart';
import '../screens/formulario/formulario_screen.dart';

class StationCard extends StatelessWidget {
  final EstacionModel estacion;

  final Function(num) formatearNumero;

  const StationCard({
    super.key,
    required this.estacion,
    required this.formatearNumero,
  });

  Color _estadoColor() {
    if (estacion.ultimoTotalizador == null) {
      return AppTheme.warningOrange;
    }

    if (estacion.ultimoTotalizador == 0) {
      return AppTheme.dangerRed;
    }

    return AppTheme.successGreen;
  }

  @override
  Widget build(BuildContext context) {
    final totalizado =
        estacion.ultimoTotalizador ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(26),

        boxShadow: AppTheme.mediumShadow,
      ),

      child: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // =====================================
            // HEADER
            // =====================================

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      Text(
                        estacion.nombre,

                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                          fontSize: 22,
                          color:
                          AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Estación operativa',

                        style: TextStyle(
                          color: AppTheme
                              .textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),

                  decoration: BoxDecoration(
                    color: _estadoColor()
                        .withOpacity(.12),

                    borderRadius:
                    BorderRadius.circular(30),
                  ),

                  child: Text(
                    'Activa',

                    style: TextStyle(
                      color: _estadoColor(),
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // =====================================
            // TOTALIZADOR
            // =====================================

            Text(
              'TOTALIZADOR',

              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${formatearNumero(totalizado)} m³',

              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentCyan,
              ),
            ),

            const SizedBox(height: 28),

            // =====================================
            // INFO
            // =====================================

            Row(
              children: [
                _info(
                  'Bombas',
                  '${estacion.bombas.length}',
                ),

                const SizedBox(width: 28),

                _info(
                  'Activos',
                  '${estacion.activos.length}',
                ),
              ],
            ),

            const SizedBox(height: 26),

            // =====================================
            // BOTÓN
            // =====================================

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FormularioScreen(
                            estacion: estacion,
                          ),
                    ),
                  );
                },

                style:
                ElevatedButton.styleFrom(
                  elevation: 0,

                  backgroundColor:
                  AppTheme.primaryBlue,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                icon: const Icon(
                  Icons.add_rounded,
                ),

                label: const Text(
                  'Registrar lectura',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(
      String label,
      String value,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        Text(
          value,

          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,

          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}