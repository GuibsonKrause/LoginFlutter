import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Garante que o Flutter terminou de preparar os recursos nativos
  // antes de inicializar plugins como o Firebase.
  WidgetsFlutterBinding.ensureInitialized();

  // Liga o app ao projeto criado no console do Firebase usando as chaves
  // geradas pelo FlutterFire CLI em firebase_options.dart.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
