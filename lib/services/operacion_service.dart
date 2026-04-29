import 'dart:convert';
import 'package:http/http.dart' as http;

class OperacionService {
  static const String _baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> registrar({
    required String token,
    required String estacionId,
    required List<Map<String, dynamic>> valores,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/operaciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'estacion_id': estacionId,
          'valores': valores,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registro guardado correctamente',
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          String mensaje = data['message'] ?? 'Error al guardar';
          
          if (data['message'] is List) {
            mensaje = (data['message'] as List).join(', ');
          }
          
          return {
            'success': false,
            'message': mensaje,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión',
      };
    }
  }
}