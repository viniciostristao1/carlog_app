import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Configuração do Firebase do projeto `carlog-b4ef3` (Android). Valores extraídos
/// do google-services.json — NÃO são segredo (a segurança vem das regras do
/// Firestore + SHA-1 registrado). Só Android por ora (o app é Android-first).
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
    apiKey: 'AIzaSyBjElEXKKIXQGSnLvFrtrYW5xqkR6pV_NQ',
    appId: '1:214781359126:android:0894c9b60b472cd5def137',
    messagingSenderId: '214781359126',
    projectId: 'carlog-b4ef3',
    storageBucket: 'carlog-b4ef3.firebasestorage.app',
  );
}
