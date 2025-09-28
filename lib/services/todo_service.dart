// lib/services/todo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TodoService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>> fetchRange(String startIso, String endIso, {bool forceRefresh = false}) async {
    final token = await _token();
    // Add cache-busting param when forcing refresh
    final cb = forceRefresh ? '&_cb=${DateTime.now().millisecondsSinceEpoch}' : '';
    final url = Uri.parse('$baseUrl/api/todos/range?start=$startIso&end=$endIso$cb');
    try {
      final resp = await http.get(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> markComplete(String id, {String? date}) async {
    final token = await _token();
    final qs = date != null ? '?date=$date' : '';
    final url = Uri.parse('$baseUrl/api/todos/$id/complete$qs');
    try {
      final resp = await http.patch(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  // New: uncomplete (undo per-date completion)
  static Future<Map<String, dynamic>> uncomplete(String id, String date) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/todos/$id/uncomplete?date=$date');
    try {
      final resp = await http.patch(url, headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteTodo(String id) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/todos/$id');
    try {
      final resp = await http.delete(url, headers: {
        if (token != null) 'Authorization': 'Bearer $token'
      }).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createTodo(Map<String, dynamic> data) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/todos');
    try {
      final resp = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: jsonEncode(data)).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTodo(String id, Map<String, dynamic> data) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/todos/$id');
    try {
      final resp = await http.put(url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: jsonEncode(data)).timeout(const Duration(seconds: 10));
      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      return {'ok': resp.statusCode >= 200 && resp.statusCode < 300, 'status': resp.statusCode, 'body': body};
    } catch (e) {
      return {'ok': false, 'error': e.toString()};
    }
  }
}