// lib/services/ai_service.dart - Enhanced AI Service
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AiService {
  static const String baseUrl_local = 'http://localhost:3000';
  static const String baseUrl = AppConfig.backendUrl;


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

  /// Enhanced AI assist with support for different modes and validation
  static Future<Map<String, dynamic>> assist(Map<String, dynamic> payload) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/ai/assist');
    
    try {
      final resp = await http
          .post(url,
              headers: _headers(token),
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 25)); // Increased timeout for AI processing

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      
      return {
        'ok': resp.statusCode >= 200 && resp.statusCode < 300,
        'status': resp.statusCode,
        'body': body,
        'error': body['error'],
      };
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return {
          'ok': false,
          'error': 'AI request timed out. Please try again.',
        };
      }
      return {'ok': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Commit tasks from AI suggestions
  static Future<Map<String, dynamic>> commitTasks(List<Map<String, dynamic>> tasks) async {
    final token = await _token();
    final url = Uri.parse('$baseUrl/api/ai/commit');
    
    try {
      final resp = await http
          .post(url,
              headers: _headers(token),
              body: jsonEncode({'tasks': tasks}))
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

  /// Get AI summary for a specific date
  static Future<Map<String, dynamic>> getDailySummary({String? date}) async {
    return assist({
      'prompt': 'Give me a comprehensive summary of ${date ?? 'today'}. '
          'Include: completed tasks, pending tasks, priorities, and recommendations.',
      'mode': 'summary',
      if (date != null) 'date': date,
    });
  }

  /// Get task prioritization advice
  static Future<Map<String, dynamic>> getPrioritization() async {
    return assist({
      'prompt': 'Analyze my current tasks and suggest the optimal order to complete them. '
          'Consider urgency, importance, dependencies, and workload balance.',
      'mode': 'prioritize',
    });
  }

  /// Analyze productivity patterns
  static Future<Map<String, dynamic>> analyzeProductivity() async {
    return assist({
      'prompt': 'Analyze my productivity patterns over the past week. '
          'Identify trends, bottlenecks, and areas for improvement.',
      'mode': 'analyze',
    });
  }

  /// Check for scheduling conflicts
  static Future<Map<String, dynamic>> checkConflicts() async {
    return assist({
      'prompt': 'Check my schedule for time conflicts, overloaded days, '
          'and tasks that might overlap. Warn me about potential issues.',
      'mode': 'analyze',
    });
  }
}