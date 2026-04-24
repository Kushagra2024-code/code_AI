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
  String mentorOutput = "Submit code to get AI mentor feedback";
  int tabSwitches = 0;
  bool largePaste = false;
  bool loading = false;
  bool mentorLoading = false;
  String? lastSubmissionId;
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
        lastSubmissionId = resp["submissionId"]?.toString();
        output = "Submission accepted.\nscore: ${resp["score"]}\nrating delta: ${resp["ratingDelta"] ?? 0}\nsolve time: ${solveTimeSec}s";
      });

      await fetchMentorFeedback();
    } catch (e) {
      setState(() => output = "Submit failed: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchMentorFeedback() async {
    final submissionId = lastSubmissionId;
    if (submissionId == null || submissionId.isEmpty) {
      setState(() => mentorOutput = "No submission found yet. Submit code first.");
      return;
    }

    final api = ref.read(apiClientProvider);
    setState(() => mentorLoading = true);
    try {
      final resp = await api.post("generateFeedback", {
        "submissionId": submissionId,
        "code": codeController.text,
        "language": language,
        "problem": "Coding practice session",
      });

      final feedback = (resp["feedback"] as Map<String, dynamic>? ?? {});
      final smells = ((feedback["smells"] as List<dynamic>?) ?? const []).join(", ");
      final edgeCases = ((feedback["edgeCases"] as List<dynamic>?) ?? const []).join(", ");
      final suggestions = ((feedback["suggestions"] as List<dynamic>?) ?? const []).join("\n- ");

      setState(() {
        mentorOutput = [
          "Time Complexity: ${feedback["timeComplexity"] ?? "N/A"}",
          "Optimal/Target: ${feedback["optimalComplexity"] ?? feedback["memoryComplexity"] ?? "N/A"}",
          "Readability: ${feedback["readability"] ?? "N/A"}",
          "Smells: ${smells.isEmpty ? "None" : smells}",
          "Edge Cases: ${edgeCases.isEmpty ? "None" : edgeCases}",
          "Suggestions:\n- ${suggestions.isEmpty ? "No suggestions" : suggestions}",
        ].join("\n\n");
      });
    } catch (e) {
      setState(() => mentorOutput = "Failed to generate feedback: $e");
    } finally {
      setState(() => mentorLoading = false);
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
              OutlinedButton(onPressed: mentorLoading ? null : fetchMentorFeedback, child: const Text("AI Mentor")),
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
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("AI Mentor", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (mentorLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(mentorOutput),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
