import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:uuid/uuid.dart";

import "../../core/providers.dart";

class DesignNode {
  DesignNode({required this.id, required this.offset, required this.label});
  final String id;
  Offset offset;
  String label;

  Map<String, dynamic> toJson() => {
    "id": id,
    "x": offset.dx,
    "y": offset.dy,
    "label": label,
  };
}

class SystemDesignPage extends ConsumerStatefulWidget {
  const SystemDesignPage({super.key});

  @override
  ConsumerState<SystemDesignPage> createState() => _SystemDesignPageState();
}

class _SystemDesignPageState extends ConsumerState<SystemDesignPage> {
  final uuid = const Uuid();
  final List<DesignNode> nodes = [];
  String evaluation = "No evaluation yet";

  Future<void> evaluate() async {
    final api = ref.read(apiClientProvider);
    final sessionId = ref.read(sessionIdProvider);
    final diagram = {"nodes": nodes.map((n) => n.toJson()).toList()};
    final resp = await api.post("evaluateDesign", {"sessionId": sessionId, "diagram": diagram});
    final ev = resp["evaluation"] as Map<String, dynamic>;
    setState(() {
      evaluation = "Score: ${ev["score"]}\nMissing: ${(ev["missingComponents"] as List).join(", ")}\nImprove: ${(ev["improvements"] as List).join(", ")}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Problem: Design Twitter with high availability and feed fanout strategy."),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          nodes.add(DesignNode(
                            id: uuid.v4(),
                            offset: Offset(60 + nodes.length * 30, 60 + nodes.length * 20),
                            label: "Service ${nodes.length + 1}",
                          ));
                        });
                      },
                      child: const Text("Add Box"),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: evaluate, child: const Text("AI Evaluate")),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        final raw = jsonEncode({"nodes": nodes.map((e) => e.toJson()).toList()});
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(content: SingleChildScrollView(child: Text(raw))),
                        );
                      },
                      child: const Text("Export JSON"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(evaluation),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: InteractiveViewer(
            maxScale: 5,
            minScale: 0.5,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ArrowPainter(nodes),
                  ),
                ),
                ...nodes.map(
                  (node) => Positioned(
                    left: node.offset.dx,
                    top: node.offset.dy,
                    child: Draggable<DesignNode>(
                      data: node,
                      feedback: NodeCard(label: node.label),
                      childWhenDragging: const SizedBox.shrink(),
                      onDragEnd: (d) {
                        setState(() => node.offset = d.offset);
                      },
                      child: NodeCard(label: node.label),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ArrowPainter extends CustomPainter {
  ArrowPainter(this.nodes);
  final List<DesignNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 2;
    for (var i = 1; i < nodes.length; i++) {
      final a = nodes[i - 1].offset + const Offset(60, 20);
      final b = nodes[i].offset + const Offset(60, 20);
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowPainter oldDelegate) => oldDelegate.nodes != nodes;
}

class NodeCard extends StatelessWidget {
  const NodeCard({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.dns),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
