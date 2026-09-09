/// Opens a URL in the system's default browser without a Flutter plugin.
///
/// Every plugin on this machine needs symlink support, which needs
/// Developer Mode or admin rights — neither available here (see
/// `pubspec.yaml`'s "NO PLUGINS" note; `file_selector` was tried and
/// reverted 2026-09-03 for exactly this). Shelling out to the OS's own
/// `start` command sidesteps that entirely — the same way
/// `git_state.dart` already shells out to `git`, not a plugin.
library;

import 'dart:io';

Future<void> openUrl(String url) async {
  await Process.run('cmd', ['/c', 'start', '', url]);
}
