// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/centered_text_field.dart';
import '../widgets/animated_submit_button.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await AuthService.login(_email.text.trim(), _password.text);
    setState(() => _loading = false);

    final msg = result['message'] ?? (result['ok'] == true ? 'Success' : 'Something went wrong');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (result['ok'] == true) {
      // Navigate to Home and remove previous routes
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to your AI powered todo',
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CenteredTextField(
            controller: _email,
            label: 'Email',
            hint: 'you@domain.com',
            keyboardType: TextInputType.emailAddress,
            validator: (s) {
              final v = (s ?? '').trim();
              if (v.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CenteredTextField(
            controller: _password,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: _obscure,
            suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (s) {
              if ((s ?? '').length < 6) return 'Password must be 6+ chars';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(children: [
            TextButton(onPressed: () {}, child: const Text('Forgot?')),
            const Spacer(),
            AnimatedSubmitButton(
              label: 'Sign in',
              loading: _loading,
              onPressed: _submit,
              icon: Icons.login,
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('New here?', style: TextStyle(color: Colors.black54)),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
              },
              child: const Text('Create account'),
            ),
          ]),
        ]),
      ),
    );
  }
}