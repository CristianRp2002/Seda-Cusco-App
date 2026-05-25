import 'package:flutter/material.dart';
import '../constants/registros_colors.dart';
import '../utils/registros_utils.dart';

class BottomSheetAvanzado extends StatefulWidget {
  final int anioActual;
  final int anioSeleccionado;
  final int? mesSeleccionado;
  final Function(int mes, int anio) onAplicar;

  const BottomSheetAvanzado({
    super.key,
    required this.anioActual,
    required this.anioSeleccionado,
    required this.mesSeleccionado,
    required this.onAplicar,
  });

  @override
  State<BottomSheetAvanzado> createState() => _BottomSheetAvanzadoState();
}

class _BottomSheetAvanzadoState extends State<BottomSheetAvanzado> {
  late int _anioTemporal;
  late int? _mesTemporal;

  @override
  void initState() {
    super.initState();
    _anioTemporal = widget.anioSeleccionado;
    _mesTemporal = widget.mesSeleccionado;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
        Row(children: [
          const Text('Año:',
              style: TextStyle(color: RegistrosColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: _anioTemporal,
            items: List.generate(5, (i) => widget.anioActual - i)
                .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _anioTemporal = v);
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
            final sel = _mesTemporal == mes;
            return GestureDetector(
              onTap: () {
                setState(() => _mesTemporal = mes);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? RegistrosColors.primary : RegistrosColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? RegistrosColors.primary : RegistrosColors.border,
                  ),
                ),
                child: Text(
                  RegistrosUtils.getMesNombre(mes),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? Colors.white : RegistrosColors.textSecondary,
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
              if (_mesTemporal != null) {
                widget.onAplicar(_mesTemporal!, _anioTemporal);
                Navigator.pop(context);
              }
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}
