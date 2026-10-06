/// ADR 0051 point 2 — sends a file or folder to the **Windows Recycle
/// Bin**, with full native Explorer undo, never a permanent delete.
///
/// No Flutter plugin, and no new pub dependency either — shelling out to
/// PowerShell's own `Microsoft.VisualBasic.FileIO.FileSystem` assembly is
/// the same move `open_url.dart` already makes for OS integration
/// (`cmd /c start`), and for the same reason: every plugin on this
/// machine needs symlink support this machine doesn't have
/// (`pubspec.yaml`'s "NO PLUGINS" note). Pure Dart, no Flutter import.
library;

import 'dart:io';

/// The PowerShell command [sendToRecycleBin] runs — split out so a test
/// can check the string itself (escaping, the right `.FileIO` member for
/// a file versus a folder) without ever actually touching the real
/// Recycle Bin, the same way `git_state.dart` keeps "the command" and
/// "running it" separate enough to show the one without doing the other.
String recycleBinCommand(String path, {required bool isDirectory}) {
  final member = isDirectory ? 'DeleteDirectory' : 'DeleteFile';
  final escaped = path.replaceAll("'", "''");
  return 'Add-Type -AssemblyName Microsoft.VisualBasic; '
      '[Microsoft.VisualBasic.FileIO.FileSystem]::$member('
      "'$escaped', "
      '[Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs, '
      '[Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin)';
}

/// Moves [path] to the Recycle Bin. Throws a [StateError] naming
/// PowerShell's own stderr on failure — never silently does nothing.
Future<void> sendToRecycleBin(String path) async {
  final isDirectory = Directory(path).existsSync();
  if (!isDirectory && !File(path).existsSync()) {
    throw StateError('Nothing at $path to send to the Recycle Bin.');
  }

  final result = await Process.run('powershell', [
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    recycleBinCommand(path, isDirectory: isDirectory),
  ]);

  if (result.exitCode != 0) {
    final errorOutput = (result.stderr as String).trim();
    throw StateError(
      'Could not send $path to the Recycle Bin'
      '${errorOutput.isEmpty ? '' : ': $errorOutput'}',
    );
  }
}
