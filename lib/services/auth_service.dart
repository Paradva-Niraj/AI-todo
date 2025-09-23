class AuthService {
  /// Mock login: returns success after a short delay
  static Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 700));
    // simple validation for demo
    if (email.contains('@') && password.length >= 6) {
      return {'ok': true, 'message': 'Logged in successfully'};
    }
    return {'ok': false, 'message': 'Invalid credentials'};
  }

  /// Mock register
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (name.length >= 2 && email.contains('@') && password.length >= 6) {
      return {'ok': true, 'message': 'Account created'};
    }
    return {'ok': false, 'message': 'Invalid data'};
  }
}