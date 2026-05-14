import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/operacion_model.dart';

class OperacionService {
  // ── REGISTRAR (ya existente) ──────────────────────────────────────────────
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
          return {
            'success': false,
            'message': 'Error ${response.statusCode}: ${response.body}',
          };
        }
      }
    } catch (e) {
      debugPrint('❌ Excepción en registrar: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // ── LISTAR OPERACIONES ────────────────────────────────────────────────────
  /// Obtiene los partes diarios con filtros opcionales.
  /// [mes]       → número de mes como string, ej: '5'
  /// [anio]      → año como string, ej: '2025'
  /// [estacionId] → UUID de la estación (opcional)
  static Future<List<OperacionModel>> getOperaciones({
    required String token,
    String? mes,
    String? anio,
    String? estacionId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (mes != null && mes.isNotEmpty) queryParams['mes'] = mes;
      if (anio != null && anio.isNotEmpty) queryParams['anio'] = anio;
      if (estacionId != null && estacionId.isNotEmpty) {
        queryParams['estacion_id'] = estacionId;
      }

      final uri = Uri.parse(ApiConfig.operaciones).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => OperacionModel.fromJson(json)).toList();
      } else {
        debugPrint('❌ Error al listar operaciones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Excepción en getOperaciones: $e');
      return [];
    }
  }
}