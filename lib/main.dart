// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if token exists and is valid
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  bool startAtDashboard = false;
  
  if (token != null && token.isNotEmpty) {
    // Validate the token by making a test API call
    final isValid = await AuthService.isTokenValid();
    startAtDashboard = isValid;
    
    if (!isValid) {
      // Token is invalid/expired, clear it
      await AuthService.logout();
    }
  }
  
  runApp(MyApp(startAtDashboard: startAtDashboard));
}

class MyApp extends StatelessWidget {
  final bool startAtDashboard;
  const MyApp({super.key, required this.startAtDashboard});

  @override
  Widget build(BuildContext context) {
    return AiTodoApp(startAtDashboard: startAtDashboard);
  }
}