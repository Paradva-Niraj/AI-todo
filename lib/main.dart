// lib/main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  runApp(MyApp(startAtDashboard: token != null));
}

class MyApp extends StatelessWidget {
  final bool startAtDashboard;
  const MyApp({super.key, required this.startAtDashboard});

  @override
  Widget build(BuildContext context) {
    return AiTodoApp(startAtDashboard: startAtDashboard);
  }
}