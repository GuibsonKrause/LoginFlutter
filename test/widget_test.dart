import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aula6/app.dart';

void main() {
  testWidgets('valida formulario e navega para tela de sucesso', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Login'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Informe o e-mail.'), findsOneWidget);
    expect(find.text('Informe a senha.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'professor@escola.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Login realizado com sucesso!'), findsOneWidget);
    expect(find.text('E-mail logado: professor@escola.com'), findsOneWidget);
  });
}
