import "package:flutter/material.dart";

import "../analytics/analytics_dashboard_page.dart";
import "../coding/coding_practice_page.dart";
import "../interview/interview_simulator_page.dart";
import "../system_design/system_design_page.dart";

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = [
    CodingPracticePage(),
    InterviewSimulatorPage(),
    SystemDesignPage(),
    AnalyticsDashboardPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI OA Practice")),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.code), label: "Coding"),
          NavigationDestination(icon: Icon(Icons.record_voice_over), label: "Interview"),
          NavigationDestination(icon: Icon(Icons.draw), label: "Design"),
          NavigationDestination(icon: Icon(Icons.analytics), label: "Analytics"),
        ],
      ),
    );
  }
}
