// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> assist(String prompt) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/ai/assist');
    try {
      final resp = await http
          .post(url,
              headers: _headers(token),
              body: jsonEncode({'prompt': prompt}))
          .timeout(const Duration(seconds: 20));

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {
        'ok': resp.statusCode >= 200 && resp.statusCode < 300,
        'status': resp.statusCode,
        'body': body,
        'error': body['error'],
      };
    } catch (e) {
      return {'ok': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> commitTasks(List<Map<String, dynamic>> tasks) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/ai/commit');
    try {
      final resp = await http
          .post(url,
              headers: _headers(token),
              body: jsonEncode({'tasks': tasks}))
          .timeout(const Duration(seconds: 15));

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {
        'ok': resp.statusCode >= 200 && resp.statusCode < 300,
        'status': resp.statusCode,
        'body': body,
        'error': body['error'],
      };
    } catch (e) {
      return {'ok': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}