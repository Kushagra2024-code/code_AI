import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/providers.dart";

class AnalyticsDashboardPage extends ConsumerWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ref.read(apiClientProvider).get("analytics"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Failed to load analytics: ${snapshot.error}"));
        }

        final metrics = (snapshot.data ?? {})["metrics"] as Map<String, dynamic>? ?? {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metric("Accuracy", "${metrics["accuracyRate"] ?? 0}%"),
                _metric("Average Score", "${metrics["averageScore"] ?? 0}"),
                _metric("Submissions", "${metrics["totalSubmissions"] ?? 0}"),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Trend (mock chart bars)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _Bar(value: 40, label: "W1"),
                _Bar(value: 50, label: "W2"),
                _Bar(value: 65, label: "W3"),
                _Bar(value: 78, label: "W4"),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _metric(String title, String value) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.label});
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(height: value * 1.4, color: Colors.teal),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
