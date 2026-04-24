import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/auth_gateway.dart";
import "../../core/providers.dart";

class LiveSessionPage extends ConsumerStatefulWidget {
  const LiveSessionPage({super.key});

  @override
  ConsumerState<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends ConsumerState<LiveSessionPage> {
  bool loading = false;
  String info = "";

  Future<void> startSession() async {
    final api = ref.read(apiClientProvider);
    final sessionId = nextSessionId();
    setState(() => loading = true);
    try {
      await api.post("startSession", {"sessionId": sessionId, "type": "mixed"});
      ref.read(sessionIdProvider.notifier).state = sessionId;
      setState(() => info = "Started $sessionId");
    } catch (e) {
      setState(() => info = "Failed to start session: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> endSession() async {
    final api = ref.read(apiClientProvider);
    final sessionId = ref.read(sessionIdProvider);
    setState(() => loading = true);
    try {
      final resp = await api.post("endSession", {"sessionId": sessionId});
      setState(() => info = "Ended $sessionId, finalScore=${resp["finalScore"] ?? 0}");
    } catch (e) {
      setState(() => info = "Failed to end session: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthGateway.instance.isFirebaseReady) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Live realtime stream requires Firebase configuration and authentication."),
        ),
      );
    }

    final sessionId = ref.watch(sessionIdProvider);
    final db = FirebaseFirestore.instance;
    final sessionDoc = db.collection("sessions").doc(sessionId).snapshots();

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
        Row(
          children: [
            FilledButton(onPressed: loading ? null : startSession, child: const Text("Start Session")),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: loading ? null : endSession, child: const Text("End Session")),
            const SizedBox(width: 12),
            if (loading) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        if (info.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(info)),
        const SizedBox(height: 8),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: sessionDoc,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Session summary loading...");
                }
                final d = snapshot.data?.data();
                if (d == null) {
                  return const Text("No session summary yet");
                }
                return Text(
                  "status=${d["status"] ?? "-"}, liveFinalScore=${d["liveFinalScore"] ?? 0}, "
                  "latestSubmission=${d["latestSubmissionScore"] ?? 0}, latestDesign=${d["latestDesignScore"] ?? 0}",
                );
              },
            ),
          ),
        ),
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
