import "package:flutter/material.dart";

class InterviewSimulatorPage extends StatefulWidget {
  const InterviewSimulatorPage({super.key});

  @override
  State<InterviewSimulatorPage> createState() => _InterviewSimulatorPageState();
}

class _InterviewSimulatorPageState extends State<InterviewSimulatorPage> {
  final controller = TextEditingController();
  final List<String> chat = [
    "AI: Welcome. Explain your approach before coding.",
    "AI: What is your expected time complexity?",
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      chat.add("You: $text");
      chat.add("AI: Can this be optimized? Which edge cases did you consider?");
      controller.clear();
    });
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
          child: Row(
            children: [
              Expanded(child: TextField(controller: controller, decoration: const InputDecoration(hintText: "Type your response"))),
              const SizedBox(width: 8),
              FilledButton(onPressed: send, child: const Text("Send")),
            ],
          ),
        ),
      ],
    );
  }
}
