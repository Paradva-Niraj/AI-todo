// lib/app.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

class AiTodoApp extends StatelessWidget {
  final bool startAtDashboard;
  const AiTodoApp({super.key, this.startAtDashboard = false});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.deepPurple;
    return MaterialApp(
      title: 'AI Todo — Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: startAtDashboard ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}