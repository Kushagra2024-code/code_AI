import "package:flutter/material.dart";

import "features/auth/auth_gate.dart";

class AiOaPracticeApp extends StatelessWidget {
  const AiOaPracticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "AI OA Practice",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF045D56)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
