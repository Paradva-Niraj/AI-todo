// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/centered_text_field.dart';
import '../widgets/animated_submit_button.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await AuthService.register(_name.text.trim(), _email.text.trim(), _password.text);
    setState(() => _loading = false);

    final msg = res['message'] ?? (res['ok'] == true ? 'Success' : 'Something went wrong');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (res['ok'] == true) {
      // Navigate to Home
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      title: 'Create account',
      subtitle: 'Let\'s get you set up for AI Todo',
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CenteredTextField(
            controller: _name,
            label: 'Full name',
            hint: 'Your display name',
            validator: (s) => (s ?? '').trim().length < 2 ? 'Enter a valid name' : null,
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          CenteredTextField(
            controller: _password,
            label: 'Password',
            hint: 'At least 6 characters',
            obscureText: _obscure,
            suffix: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure)),
            validator: (s) => (s ?? '').length < 6 ? 'Password must be 6+ chars' : null,
          ),
          const SizedBox(height: 10),
          CenteredTextField(
            controller: _confirm,
            label: 'Confirm password',
            hint: 'Repeat password',
            obscureText: _obscure,
            validator: (s) => s != _password.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 14),
          AnimatedSubmitButton(label: 'Create account', loading: _loading, onPressed: _register, icon: Icons.check),
        ]),
      ),
    );
  }
}