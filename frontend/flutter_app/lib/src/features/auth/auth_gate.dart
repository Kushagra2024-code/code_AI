import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../../core/auth_gateway.dart";
import "../shell/app_shell.dart";
import "auth_page.dart";

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<bool> _initFuture;
  bool _demoMode = false;

  @override
  void initState() {
    super.initState();
    _initFuture = AuthGateway.instance
        .initialize()
        .timeout(const Duration(seconds: 2), onTimeout: () => false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final ready = snapshot.data ?? false;
        if (!ready && _demoMode) {
          return const AppShell();
        }

        if (!ready) {
          return AuthPage(
            firebaseReady: false,
            onContinueDemo: () => setState(() => _demoMode = true),
          );
        }

        return StreamBuilder<User?>(
          stream: AuthGateway.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.hasData) {
              return const AppShell();
            }

            return AuthPage(
              firebaseReady: true,
              onContinueDemo: () => setState(() => _demoMode = true),
            );
          },
        );
      },
    );
  }
}
