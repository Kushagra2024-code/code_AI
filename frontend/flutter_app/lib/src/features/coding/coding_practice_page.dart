import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/providers.dart";

const Map<String, String> languageTemplates = {
  "cpp": "#include <bits/stdc++.h>\nusing namespace std;\n\nint main() {\n  ios::sync_with_stdio(false);\n  cin.tie(nullptr);\n\n  return 0;\n}\n",
  "python": "def solve():\n    pass\n\n\nif __name__ == \"__main__\":\n    solve()\n",
  "java": "import java.util.*;\n\npublic class Main {\n  public static void main(String[] args) {\n\n  }\n}\n",
  "javascript": "function solve(input) {\n  return '';\n}\n\nprocess.stdin.resume();\nprocess.stdin.setEncoding('utf8');\nlet data = '';\nprocess.stdin.on('data', chunk => data += chunk);\nprocess.stdin.on('end', () => console.log(solve(data)));\n",
};

class CodingPracticePage extends ConsumerStatefulWidget {
  const CodingPracticePage({super.key});

  @override
  ConsumerState<CodingPracticePage> createState() => _CodingPracticePageState();
}

class _CodingPracticePageState extends ConsumerState<CodingPracticePage> with WidgetsBindingObserver {
  final codeController = TextEditingController(text: languageTemplates["python"]);
  final stdinController = TextEditingController();
  String language = "python";
  String output = "Run code to see execution output";
  int tabSwitches = 0;
  bool largePaste = false;
  bool loading = false;
  late final DateTime startedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    startedAt = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    codeController.dispose();
    stdinController.dispose();
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
    final currentCode = codeController.text;
    largePaste = currentCode.length > 4000;

    setState(() => loading = true);
    try {
      final run = await api.post("runCode", {
        "code": currentCode,
        "language": language,
        "stdin": stdinController.text,
      });

      setState(() {
        output = [
          "Status: ${run["status"] ?? "Unknown"}",
          "stdout:\n${(run["stdout"] ?? "").toString().isEmpty ? "<empty>" : run["stdout"]}",
          "stderr:\n${(run["stderr"] ?? "").toString().isEmpty ? "<empty>" : run["stderr"]}",
          "compile:\n${(run["compileOutput"] ?? "").toString().isEmpty ? "<empty>" : run["compileOutput"]}",
          "time: ${run["time"] ?? "-"} memory: ${run["memory"] ?? "-"}",
        ].join("\n\n");
      });
    } catch (e) {
      setState(() => output = "Run failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> submitCode() async {
    final api = ref.read(apiClientProvider);
    final sessionId = ref.read(sessionIdProvider);
    final currentCode = codeController.text;
    final solveTimeSec = DateTime.now().difference(startedAt).inSeconds;
    largePaste = currentCode.length > 4000;

    setState(() => loading = true);
    try {
      final resp = await api.post("submitCode", {
        "sessionId": sessionId,
        "code": currentCode,
        "language": language,
        "difficulty": "medium",
        "solveTimeSec": solveTimeSec,
        "sampleTests": [
          {"input": "", "output": ""}
        ],
        "result": {
          "correctness": 70,
          "performance": 60,
          "quality": 70,
          "passedTests": 1,
          "execution": {"stdout": "", "stderr": "", "time": "0.04s"}
        }
      });

      await api.post("detectCheating", {
        "sessionId": sessionId,
        "signals": {
          "tabSwitches": tabSwitches,
          "largePaste": largePaste,
          "tooFast": solveTimeSec < 90,
          "similarityHigh": false
        }
      });

      setState(() {
        output = "Submission accepted.\nscore: ${resp["score"]}\nrating delta: ${resp["ratingDelta"] ?? 0}\nsolve time: ${solveTimeSec}s";
      });
    } catch (e) {
      setState(() => output = "Submit failed: $e");
    } finally {
      setState(() => loading = false);
    }
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
                onChanged: (v) {
                  final next = v ?? "python";
                  setState(() {
                    language = next;
                    codeController.text = languageTemplates[next] ?? "";
                  });
                },
              ),
              FilledButton(onPressed: loading ? null : runCode, child: const Text("Run")),
              OutlinedButton(onPressed: loading ? null : submitCode, child: const Text("Submit")),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: stdinController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "stdin",
              alignLabelWithHint: true,
            ),
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
