/// ADR 0050 — the one ＋ a project with no `CHARTER.md` at all gets:
/// creates the file with its four fixed headings (ADR 0025), each empty,
/// so the Strategy tab's own per-section ＋ places have something to
/// fill next. Writing a section's own text, once the file exists, is
/// `area_section_writer.dart`'s `setAreaSection`/`clearAreaSection`
/// reused directly — that pair already reads and replaces any markdown
/// file's `## heading` section, not only an area page's. Same
/// atomic-write and write-log discipline as every other writer here;
/// pure Dart, no Flutter import.
library;

import 'dart:io';

import 'package:asa/core/write_log.dart';

/// Writes `CHARTER.md` inside [projectFolder] with Origin, Who it's for,
/// Pain points and Objectives, each an empty body — scaffolding only,
/// never invented prose. Refuses with a [StateError] if the file already
/// exists: a real `CHARTER.md`, however it reads today, is never silently
/// replaced.
Future<void> createCharterFile(
  String projectFolder, {
  String? writeLogPath,
}) async {
  final path = '$projectFolder${Platform.pathSeparator}CHARTER.md';
  final file = File(path);
  if (file.existsSync()) {
    throw StateError('CHARTER.md already exists — nothing to create.');
  }

  const content =
      '## Origin\n\n'
      "## Who it's for\n\n"
      '## Pain points\n\n'
      '## Objectives\n';

  final tempFile = File('$path.tmp');
  await tempFile.writeAsString(content);
  await tempFile.rename(path);

  await appendWriteLogEntry(
    path: path,
    field: 'charter-created',
    from: '',
    to: "Origin / Who it's for / Pain points / Objectives",
    logPath: writeLogPath,
  );
}
