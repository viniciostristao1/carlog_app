import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_config.dart';

/// Login com Google nativo (google_sign_in) + Firebase Auth. Só é usado quando
/// `kFirebaseConfigured` é true; enquanto false, a UI de login nem aparece.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  bool _gsiInit = false;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInit() async {
    if (_gsiInit) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: kGoogleServerClientId,
    );
    _gsiInit = true;
  }

  Future<void> signInWithGoogle() async {
    await _ensureInit();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignora se o google_sign_in ainda não foi inicializado
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Estado de login em tempo real (null = deslogado). Quando a nuvem está
/// desligada (`!kFirebaseConfigured`), emite `null` para sempre — sem tocar no
/// Firebase, que nem foi inicializado.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!kFirebaseConfigured) return const Stream<User?>.empty();
  return ref.watch(authServiceProvider).authState;
});
