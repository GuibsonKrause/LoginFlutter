import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    // Controllers guardam os textos digitados nos campos. Ao sair da tela,
    // liberamos esses objetos da memoria.
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validacao local: antes de falar com o Firebase, garantimos que os
    // campos fazem sentido para o cadastro.
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // createUserWithEmailAndPassword cria uma nova conta no Firebase Auth.
      // Se der certo, o Firebase tambem deixa esse usuario logado no app.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_getAuthErrorMessage(error.code))));
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    // Depois do cadastro, levamos o usuario para a Home usando o e-mail
    // que acabou de ser criado.
    Navigator.of(
      context,
    ).pushReplacementNamed(AppRoutes.home, arguments: email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ja existe uma conta cadastrada com este e-mail.';
      case 'invalid-email':
        return 'O e-mail informado nao e valido.';
      case 'operation-not-allowed':
        return 'Cadastro por e-mail e senha nao esta habilitado no Firebase.';
      case 'weak-password':
        return 'A senha e fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Falha de conexao. Verifique a internet.';
      default:
        return 'Nao foi possivel criar o usuario. Tente novamente.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar usuario')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Crie uma conta usando e-mail e senha.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'usuario@email.com',
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Informe o e-mail.';
                      }

                      if (!_emailRegex.hasMatch(email)) {
                        return 'Digite um e-mail valido.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Minimo de 6 caracteres',
                      suffixIcon: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';

                      if (password.isEmpty) {
                        return 'Informe a senha.';
                      }

                      if (password.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      suffixIcon: IconButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final confirmPassword = value ?? '';

                      if (confirmPassword.isEmpty) {
                        return 'Confirme a senha.';
                      }

                      if (confirmPassword != _passwordController.text) {
                        return 'As senhas precisam ser iguais.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Criar conta'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Ja tenho uma conta'),
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
