import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Simples',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? AppRoutes.login
          : AppRoutes.home,
      routes: {AppRoutes.login: (_) => const LoginPage()},
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.home) {
          final currentUser = FirebaseAuth.instance.currentUser;
          final email =
              settings.arguments as String? ?? currentUser?.email ?? '';

          return MaterialPageRoute<void>(
            builder: (_) => HomePage(email: email),
          );
        }

        return null;
      },
    );
  }
}
