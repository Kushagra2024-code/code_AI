import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";

class AuthGateway {
  AuthGateway._();
  static final AuthGateway instance = AuthGateway._();

  String? _cachedToken;
  bool _firebaseReady = false;

  bool get isFirebaseReady => _firebaseReady;

  Future<bool> initialize() async {
    if (_firebaseReady) return true;
    try {
      try {
        Firebase.app();
      } on Exception {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      return true;
    } catch (_) {
      _firebaseReady = false;
      return false;
    }
  }

  Stream<User?> authStateChanges() {
    if (!_firebaseReady) return const Stream<User?>.empty();
    return FirebaseAuth.instance.authStateChanges();
  }

  User? get currentUser => _firebaseReady ? FirebaseAuth.instance.currentUser : null;

  Future<UserCredential> signIn(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInAnonymously() {
    return FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signOut() async {
    if (!_firebaseReady) return;
    await FirebaseAuth.instance.signOut();
    _cachedToken = null;
  }

  Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;

    final ready = await initialize();
    if (ready) {
      final user = currentUser;
      final token = await user?.getIdToken();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return token;
      }
    }

    _cachedToken = "demo-user";
    return _cachedToken!;
  }
}
