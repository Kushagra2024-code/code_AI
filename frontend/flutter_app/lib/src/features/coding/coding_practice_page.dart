import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/providers.dart";

class CodingPracticePage extends ConsumerStatefulWidget {
  const CodingPracticePage({super.key});

  @override
  ConsumerState<CodingPracticePage> createState() => _CodingPracticePageState();
}

class _CodingPracticePageState extends ConsumerState<CodingPracticePage> with WidgetsBindingObserver {
  final codeController = TextEditingController(text: "# Write solution\nprint('hello')\n");
  String language = "python";
  String output = "Run code to see output";
  int tabSwitches = 0;
  bool largePaste = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      tabSwitches += 1;
    }
  }

  Future<void> runCode() async {
    final api = ref.read(apiClientProvider);
    final sessionId = ref.read(sessionIdProvider);
    final currentCode = codeController.text;
    largePaste = currentCode.length > 4000;

    final resp = await api.post("submitCode", {
      "sessionId": sessionId,
      "code": currentCode,
      "language": language,
      "result": {
        "correctness": 70,
        "performance": 60,
        "quality": 70,
        "passedTests": 3,
        "execution": {"stdout": "hello", "stderr": "", "time": "0.04s"}
      }
    });

    await api.post("detectCheating", {
      "sessionId": sessionId,
      "signals": {
        "tabSwitches": tabSwitches,
        "largePaste": largePaste,
        "tooFast": false,
        "similarityHigh": false
      }
    });

    setState(() {
      output = "Submission score: ${resp["score"]}\nstdout: hello\nstderr: <empty>\nexecution: 0.04s";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text("Language:"),
              DropdownButton<String>(
                value: language,
                items: const [
                  DropdownMenuItem(value: "cpp", child: Text("C++")),
                  DropdownMenuItem(value: "python", child: Text("Python")),
                  DropdownMenuItem(value: "java", child: Text("Java")),
                  DropdownMenuItem(value: "javascript", child: Text("JavaScript")),
                ],
                onChanged: (v) => setState(() => language = v ?? "python"),
              ),
              FilledButton(onPressed: runCode, child: const Text("Run")),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: codeController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                labelText: "Code Editor",
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(output),
        ],
      ),
    );
  }
}
