import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      _showError(
        e.message.contains('Invalid login credentials')
            ? 'E-mail ou mot de passe incorrect.'
            : e.message,
      );
    } catch (_) {
      _showError('Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.auto_stories, size: 72),
                  const SizedBox(height: 12),
                  Text(
                    'Plumea',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (!text.contains('@') || !text.contains('.')) {
                        return 'Entrez une adresse e-mail valide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Entrez votre mot de passe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/inscription'),
                    child: const Text('Pas encore de compte ? S\'inscrire'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}