import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula6/core/routes/app_routes.dart';
import 'package:aula6/features/auth/presentation/pages/login_page.dart';
import 'package:aula6/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('valida login e permite ir para cadastro', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        // No teste carregamos as telas diretamente, sem inicializar Firebase.
        // Assim conseguimos testar formulario e navegacao visual sem internet.
        routes: {
          AppRoutes.login: (_) => const LoginPage(),
          AppRoutes.register: (_) => const RegisterPage(),
        },
      ),
    );

    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);

    await tester.tap(find.text('Cadastrar novo usuario'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar usuario'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}
