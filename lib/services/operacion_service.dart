import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class OperacionService {
  static Future<Map<String, dynamic>> registrar({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.operaciones),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registro guardado correctamente',
        };
      } else {
        debugPrint('❌ Error ${response.statusCode}: ${response.body}');
        try {
          final data = jsonDecode(response.body);
          final rawMessage = data['message'];
          final mensaje = rawMessage is List
              ? (rawMessage as List).join(', ')
              : rawMessage?.toString() ?? 'Error al guardar';
          return {'success': false, 'message': mensaje};
        } catch (_) {
          return {'success': false, 'message': 'Error ${response.statusCode}: ${response.body}'};
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción en registrar: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}