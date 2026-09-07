/// Product Hub — one decision, in full.
///
/// Pushed from the Decisions tab on `ProjectScreen` when a row is tapped.
/// v0.1's whole reason to exist: title, date, status, the decision, why,
/// what would change this, and the file it came from.
library;

import 'package:asa/core/decision.dart';
import 'package:flutter/material.dart';

class DecisionDetailScreen extends StatelessWidget {
  const DecisionDetailScreen({required this.decision, super.key});

  final Decision decision;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(decision.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusLine(),
            const SizedBox(height: 24),
            _block('Decision', decision.decision),
            if (decision.why.isNotEmpty) ...[
              const SizedBox(height: 24),
              _block('Why', decision.why),
            ],
            if (decision.whatWouldChangeThis.isNotEmpty) ...[
              const SizedBox(height: 24),
              _block('What would change this', decision.whatWouldChangeThis),
            ],
            const SizedBox(height: 32),
            Text(
              'Read from: ${decision.sourceFile}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusLine() {
    final parts = <String>[
      if (decision.number != null) 'ADR ${decision.number}',
      if (decision.date != null) decision.date!,
      if (decision.status != null) decision.status!,
    ];

    return Wrap(
      spacing: 12,
      children: [
        for (final part in parts)
          Text(part, style: const TextStyle(color: Colors.grey)),
        if (decision.supersededBy != null)
          Text(
            'Superseded by ${decision.supersededBy}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (decision.supersedes != null)
          Text(
            'Supersedes ${decision.supersedes}',
            style: const TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _block(String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(body),
      ],
    );
  }
}
