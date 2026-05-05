import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion_model.dart';

class EstacionService {
  static const String _baseUrl = 'http://172.16.12.127:3000';

  static Future<List<EstacionModel>> getEstaciones(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/estaciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => EstacionModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}