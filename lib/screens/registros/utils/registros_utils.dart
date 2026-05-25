import 'package:intl/intl.dart';

abstract class RegistrosUtils {
  static const List<String> meses = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  /// Obtiene el nombre del mes en español
  static String getMesNombre(int mes) {
    if (mes < 1 || mes > 12) return '';
    return meses[mes - 1];
  }

  /// Formatea una fecha en formato dd/MM/yyyy
  static String formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  /// Formatea un número con separador de miles
  static String formatNum(double n) {
    final parts = n.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();

    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    return '${buffer.toString()}.$decPart';
  }

  /// Obtiene el plural correcto para una palabra
  static String getPluralSufijo(int cantidad) => cantidad == 1 ? '' : 's';
}
