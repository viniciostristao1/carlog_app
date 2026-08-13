import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// PLACEHOLDER — feito à mão. Os valores reais vêm de `flutterfire configure`
/// (ou do console Firebase) ao provisionar o projeto; ver FIREBASE.md. Enquanto
/// `kFirebaseConfigured` (firebase_config.dart) for `false`, estes valores NÃO são
/// usados em runtime (o Firebase nem chega a ser inicializado). Estão aqui só para
/// o app compilar e para o dia do provisionamento ser um simples "substituir arquivo".
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: 'PLACEHOLDER_APP_ID',
    messagingSenderId: 'PLACEHOLDER_SENDER_ID',
    projectId: 'carlog-placeholder',
  );
}
