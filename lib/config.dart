// lib/config.dart
class AppConfig {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://ai-todo-backend-w56t.onrender.com', // fallback
  );
}
