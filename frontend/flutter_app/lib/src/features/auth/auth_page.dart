import "package:flutter/material.dart";

import "../../core/auth_gateway.dart";

class AuthPage extends StatefulWidget {
  const AuthPage({
    super.key,
    required this.firebaseReady,
    required this.onContinueDemo,
  });

  final bool firebaseReady;
  final VoidCallback onContinueDemo;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!widget.firebaseReady) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await AuthGateway.instance.signIn(emailController.text.trim(), passwordController.text);
    } catch (e) {
      setState(() => error = "Sign in failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> register() async {
    if (!widget.firebaseReady) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await AuthGateway.instance.register(emailController.text.trim(), passwordController.text);
    } catch (e) {
      setState(() => error = "Register failed: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> continueAsGuest() async {
    if (widget.firebaseReady) {
      try {
        await AuthGateway.instance.signInAnonymously();
        return;
      } catch (_) {
        // If anonymous auth is disabled, fall back to demo mode.
      }
    }
    widget.onContinueDemo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI OA Practice")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sign in to continue", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (!widget.firebaseReady)
                    const Text(
                      "Firebase is not configured in this environment. You can continue in demo mode.",
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: (!widget.firebaseReady || loading) ? null : signIn,
                          child: const Text("Sign In"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: (!widget.firebaseReady || loading) ? null : register,
                          child: const Text("Register"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: loading ? null : continueAsGuest,
                      child: const Text("Continue as Guest"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
