import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase nao configurado. Execute: dart pub global activate '
      'flutterfire_cli && flutterfire configure',
    );
  }
}
