import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../core/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.auth}/login'),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'token': data['access_token'],
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales inválidas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión con el servidor',
      };
    }
  }
}