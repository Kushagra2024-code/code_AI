import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/providers.dart";

class InterviewSimulatorPage extends ConsumerStatefulWidget {
  const InterviewSimulatorPage({super.key});

  @override
  ConsumerState<InterviewSimulatorPage> createState() => _InterviewSimulatorPageState();
}

class _InterviewSimulatorPageState extends ConsumerState<InterviewSimulatorPage> {
  final controller = TextEditingController();
  final List<String> chat = [];
  bool loading = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> startInterview() async {
    setState(() => loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final q = await api.post("generateQuestion", {
        "difficulty": "medium",
        "tags": ["arrays", "two-pointers"]
      });
      final question = q["question"] as Map<String, dynamic>;

      final intro = await api.post("interviewTurn", {
        "stage": "intro",
        "context": "Problem: ${question["title"]}. ${question["statement"]}",
      });

      setState(() {
        chat
          ..clear()
          ..add("AI: Today's problem is ${question["title"]}")
          ..add("AI: ${question["statement"]}")
          ..add("AI: ${intro["message"]}");
      });
    } catch (e) {
      setState(() => chat.add("AI: Failed to start interview: $e"));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      chat.add("You: $text");
      controller.clear();
      loading = true;
    });

    try {
      final api = ref.read(apiClientProvider);
      final turn = await api.post("interviewTurn", {
        "stage": "clarify",
        "context": text,
      });
      final followUps = (turn["followUps"] as List<dynamic>? ?? []).cast<dynamic>();
      setState(() {
        chat.add("AI: ${turn["message"]}");
        for (final q in followUps.take(2)) {
          chat.add("AI: $q");
        }
      });
    } catch (e) {
      setState(() => chat.add("AI: Error getting next question: $e"));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: chat.length,
            itemBuilder: (context, i) => ListTile(title: Text(chat[i])),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: "Type your response"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: loading ? null : send, child: const Text("Send")),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: loading ? null : startInterview,
                    child: const Text("Start Interview"),
                  ),
                  const SizedBox(width: 12),
                  if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
