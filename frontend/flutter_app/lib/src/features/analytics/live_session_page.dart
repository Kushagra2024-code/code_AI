import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/providers.dart";

class LiveSessionPage extends ConsumerWidget {
  const LiveSessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionId = ref.watch(sessionIdProvider);
    final db = FirebaseFirestore.instance;

    final submissions = db
        .collection("submissions")
        .where("sessionId", isEqualTo: sessionId)
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots();

    final cheatFlags = db
        .collection("cheatFlags")
        .where("sessionId", isEqualTo: sessionId)
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots();

    final turns = db
        .collection("interviewTurns")
        .where("sessionId", isEqualTo: sessionId)
        .orderBy("createdAt", descending: true)
        .limit(10)
        .snapshots();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text("Live Session: $sessionId", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _streamCard(
          title: "Recent Submissions",
          stream: submissions,
          builder: (doc) {
            final d = doc.data();
            return "score=${d["score"] ?? 0}, lang=${d["language"] ?? "-"}, passed=${d["passedTests"] ?? 0}";
          },
        ),
        _streamCard(
          title: "Cheating Signals",
          stream: cheatFlags,
          builder: (doc) {
            final d = doc.data();
            return "flagged=${d["flagged"] ?? false}, suspicious=${d["suspiciousScore"] ?? 0}";
          },
        ),
        _streamCard(
          title: "Interview Turns",
          stream: turns,
          builder: (doc) {
            final d = doc.data();
            return "stage=${d["stage"] ?? "-"} -> ${(d["response"] as Map<String, dynamic>? ?? const {})["message"] ?? ""}";
          },
        ),
      ],
    );
  }

  Widget _streamCard({
    required String title,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required String Function(QueryDocumentSnapshot<Map<String, dynamic>>) builder,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading...");
                }
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Text("No events yet");
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: docs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("- ${builder(d)}"),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
