/// ADR 0051 point 2 — one confirmation, in plain words, for either place
/// Delete shows up (the bottom of a project's own Details, and a row in
/// the overview's own folded list) — built once here so both share the
/// exact same wording rather than drifting apart.
library;

import 'package:asa/hubs/product/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Shows the dialog and returns `true` only on a real "Move to Recycle
/// Bin" tap — `false`/`null` on Cancel or dismissal, same as any other
/// confirm dialog in this app. Shows nothing itself; the caller still
/// does the actual send once this returns `true`.
Future<bool?> showDeleteProjectDialog(
  BuildContext context, {
  required String name,
  required int fileCount,
  required List<String> subNames,
  required String repoPath,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Move "$name" to the Recycle Bin?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The folder and its $fileCount file(s)'),
          if (subNames.isNotEmpty)
            Text(
              'With its sub-project${subNames.length > 1 ? 's' : ''} '
              '${subNames.join(', ')}',
            ),
          if (repoPath.isNotEmpty) Text('The repo at $repoPath is not touched'),
          const SizedBox(height: AsaSpace.sm),
          const Text(
            'You can restore it from the Windows Recycle Bin. Your '
            'automatic backup also keeps a copy for 30 days.',
            style: TextStyle(color: AsaColors.ink3),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Move to Recycle Bin'),
        ),
      ],
    ),
  );
}
