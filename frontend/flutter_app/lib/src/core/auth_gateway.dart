import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";

class AuthGateway {
  AuthGateway._();
  static final AuthGateway instance = AuthGateway._();

  String? _cachedToken;

  Future<String> getToken() async {
    if (_cachedToken != null) return _cachedToken!;

    try {
      try {
        Firebase.app();
      } on Exception {
        await Firebase.initializeApp();
      }

      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      final token = await user?.getIdToken();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        return token;
      }
    } catch (_) {
      // Fallback for local demo mode when Firebase isn't configured yet.
    }

    _cachedToken = "demo-user";
    return _cachedToken!;
  }
}
