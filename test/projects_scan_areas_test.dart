// Round 36 §2 f — real disk, real folders: scanProjects now threads a
// project's own areas onto its ProjectSummary, the same readAreas every
// other area reader already uses. projects_scan_test.dart deliberately
// stays disk-free (its own header explains why); this one piece — the
// scan actually reaching into `plan\` — has a real rule now, so it gets
// a real-disk test, same reasoning plan_area_ticking_test.dart already
// follows for the write side.

import 'dart:io';

import 'package:asa/core/projects_scan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    r'a project with a plan\ folder comes back with its areas parsed',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'asa-scan-areas-test-',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final projectDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}demo',
      )..createSync();
      File('${projectDir.path}${Platform.pathSeparator}demo.md')
          .writeAsStringSync('''
---
project: Demo
status: building
updated: 2026-09-26
---

# Demo
''');

      final planDir = Directory(
        '${projectDir.path}${Platform.pathSeparator}plan',
      )..createSync();
      File('${planDir.path}${Platform.pathSeparator}sales.md')
          .writeAsStringSync('''
# Sales

## Tasks
- [x] Done already
- [ ] Still open
''');

      final result = await scanProjects(tempDir.path);

      expect(result.projects, hasLength(1));
      final areas = result.projects.single.areas;
      expect(areas, hasLength(1));
      expect(areas.single.name, 'Sales');
      expect(areas.single.doneCount, 1);
      expect(areas.single.totalCount, 2);
    },
  );

  test(
    r'a project with no plan\ folder scans with an empty area list',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'asa-scan-no-areas-test-',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final projectDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}demo',
      )..createSync();
      File('${projectDir.path}${Platform.pathSeparator}demo.md')
          .writeAsStringSync('''
---
project: Demo
status: building
updated: 2026-09-26
---

# Demo
''');

      final result = await scanProjects(tempDir.path);

      expect(result.projects, hasLength(1));
      expect(result.projects.single.areas, isEmpty);
    },
  );
}
