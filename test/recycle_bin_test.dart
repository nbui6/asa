// ADR 0051 point 2 — the Recycle Bin send. The permanent suite checks
// only the command string itself: running it for real, every time
// `flutter test` runs, would populate the real Windows Recycle Bin on
// whatever machine runs the tests — the same "never touch real state in
// an automated test" rule Gate 2 already holds everywhere else in this
// repo. The real send was proven once, by hand, against a throwaway
// temp folder, never a real project — HANDOVER.md has that checkpoint.

import 'package:asa/core/recycle_bin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('recycleBinCommand', () {
    test('a folder calls DeleteDirectory', () {
      final command = recycleBinCommand(r'C:\proj\demo', isDirectory: true);
      expect(command, contains('DeleteDirectory'));
      expect(command, contains(r"'C:\proj\demo'"));
      expect(command, contains('SendToRecycleBin'));
      expect(command, contains('OnlyErrorDialogs'));
    });

    test('a file calls DeleteFile', () {
      final command = recycleBinCommand(r'C:\proj\demo.md', isDirectory: false);
      expect(command, contains('DeleteFile'));
      expect(command, isNot(contains('DeleteDirectory')));
    });

    test("a single quote in the path is escaped for PowerShell's own "
        'single-quoted string', () {
      final command = recycleBinCommand(
        r"C:\proj\test's folder",
        isDirectory: true,
      );
      expect(command, contains(r"'C:\proj\test''s folder'"));
    });
  });
}
