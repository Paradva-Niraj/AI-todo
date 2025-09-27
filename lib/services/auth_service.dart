// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Adjust baseUrl depending on platform:
  // - Android emulator: http://10.0.2.2:3000
  // - iOS simulator: http://localhost:3000
  // - Web / desktop: http://localhost:3000 (if backend reachable)
  // - Physical device: use machine LAN IP e.g. http://192.168.x.y:3000
  static const String baseUrl = 'http://localhost:3000';

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
      return {'ok': false, 'message': 'Network error: ${e.toString()}'} ;
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
      return {'ok': false, 'message': 'Network error: ${e.toString()}'} ;
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