/// Product Hub — the "Start" menu. Round 32/D, Round 3's handoff, unbuilt
/// since 2026-08-24. One small icon button, a menu rather than a row of
/// buttons (`PERSONA.md`: overwhelm) — shown on every project row and on
/// the project screen's own header.
///
/// **Why opener text rather than a `cd … && claude` terminal command:** it
/// works in any Claude surface Nico uses, desktop included, not only a
/// terminal — `RESEARCH-SIMILAR-TOOLS-2026-09-25.md`, lesson 3.
library;

import 'dart:async';
import 'dart:io';

import 'package:asa/core/opener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartMenu extends StatelessWidget {
  const StartMenu({
    required this.projectName,
    required this.projectFolder,
    required this.repoPath,
    super.key,
  });

  final String projectName;
  final String projectFolder;

  /// Empty when the project has none set — `Project.repoPath`'s own
  /// convention, never null.
  final String repoPath;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_StartAction>(
      icon: const Icon(Icons.rocket_launch_outlined, size: 18),
      tooltip: 'Start working on this project',
      onSelected: (action) => _run(context, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _StartAction.copyOpener,
          child: Text('Copy opener'),
        ),
        const PopupMenuItem(
          value: _StartAction.openFolder,
          child: Text('Open folder'),
        ),
        PopupMenuItem(
          value: _StartAction.openCode,
          enabled: repoPath.isNotEmpty,
          child: const Text('Open code in VS Code'),
        ),
      ],
    );
  }

  Future<void> _run(BuildContext context, _StartAction action) async {
    switch (action) {
      case _StartAction.copyOpener:
        await Clipboard.setData(
          ClipboardData(
            text: openerText(
              projectName: projectName,
              projectFolder: projectFolder,
            ),
          ),
        );
        if (context.mounted) _say(context, 'Copied');
      case _StartAction.openFolder:
        // Fire-and-forget, same pattern as open_url.dart — explorer.exe's
        // own exit code is not a reliable success signal.
        unawaited(Process.run('explorer', [projectFolder]));
      case _StartAction.openCode:
        try {
          await Process.run('code', [repoPath]);
        } on ProcessException {
          if (context.mounted) {
            _say(context, "VS Code's `code` command isn't on PATH.");
          }
        }
    }
  }

  void _say(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

enum _StartAction { copyOpener, openFolder, openCode }
