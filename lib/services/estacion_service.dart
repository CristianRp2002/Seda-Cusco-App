import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion_model.dart';
import '../core/api_config.dart';

class EstacionService {

  static Future<List<EstacionModel>> getEstaciones(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.estaciones),
        headers: ApiConfig.headers(token: token),
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