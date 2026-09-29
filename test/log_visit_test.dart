import 'dart:io';

import 'package:asa/core/log_visit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late String path;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('asa-log-visit-test-');
    path = '${tempDir.path}${Platform.pathSeparator}log-visits.json';
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  test('never opened yet is null, not an error', () async {
    expect(await lastLogVisit('demo', path: path), isNull);
  });

  test('records and reads back', () async {
    await recordLogVisit(
      'demo',
      now: DateTime(2026, 9, 20, 14, 30),
      path: path,
    );
    expect(
      await lastLogVisit('demo', path: path),
      DateTime(2026, 9, 20, 14, 30),
    );
  });

  test('recording one project never touches another', () async {
    await recordLogVisit('demo', now: DateTime(2026, 9), path: path);
    await recordLogVisit('other', now: DateTime(2026, 9, 20), path: path);

    expect(await lastLogVisit('demo', path: path), DateTime(2026, 9));
    expect(await lastLogVisit('other', path: path), DateTime(2026, 9, 20));
  });

  test(
    "recording again overwrites only that project's own timestamp",
    () async {
    await recordLogVisit('demo', now: DateTime(2026, 9), path: path);
    await recordLogVisit('demo', now: DateTime(2026, 9, 20), path: path);

    expect(await lastLogVisit('demo', path: path), DateTime(2026, 9, 20));
  });

  test('an unparseable file reads as never opened, not a crash', () async {
    File(path).writeAsStringSync('not json at all');
    expect(await lastLogVisit('demo', path: path), isNull);
  });
}
