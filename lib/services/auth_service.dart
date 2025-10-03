// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
class AuthService {
  static const String baseUrl_local = 'http://localhost:3000';
  static const String baseUrl = AppConfig.backendUrl;

  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    try {
      final resp = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'username': name, 'email': email, 'password': password}))
          .timeout(const Duration(seconds: 10));

      final map = _parseResponse(resp);
      if (map['ok'] == true && map['token'] != null) {
        await _saveTokenAndUser(map['token'], map['user']);
      }
      return map;
    } catch (e) {
      return {'ok': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    try {
      final resp = await http
          .post(url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': password}))
          .timeout(const Duration(seconds: 10));

      final map = _parseResponse(resp);
      if (map['ok'] == true && map['token'] != null) {
        await _saveTokenAndUser(map['token'], map['user']);
      }
      return map;
    } catch (e) {
      return {'ok': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Validate if current token is still valid by making a test API call
  static Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;

    try {
      // Make a lightweight API call to verify token
      final url = Uri.parse('$baseUrl/api/todos/range?start=2025-01-01&end=2025-01-02');
      final resp = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      // If we get 401, token is invalid/expired
      if (resp.statusCode == 401) {
        await logout(); // Clear invalid token
        return false;
      }

      // Any 2xx response means token is valid
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      // Network error - assume token might be valid, let user try
      return true;
    }
  }

  static Map<String, dynamic> _parseResponse(http.Response resp) {
    try {
      final jsonBody = jsonDecode(resp.body);
      if (jsonBody is Map<String, dynamic>) {
        return {
          'ok': jsonBody['ok'] ?? (resp.statusCode >= 200 && resp.statusCode < 300),
          'message': jsonBody['message'] ?? jsonBody['error'] ?? 'Unknown response',
          'token': jsonBody['token'],
          'user': jsonBody['user'],
        };
      } else {
        return {'ok': false, 'message': 'Invalid response from server'};
      }
    } catch (e) {
      return {'ok': false, 'message': 'Invalid JSON response'};
    }
  }

  static Future<void> _saveTokenAndUser(String token, dynamic user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (user != null) {
      await prefs.setString('auth_user', jsonEncode(user));
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }
}