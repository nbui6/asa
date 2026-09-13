// No disk touched — a fake FileAccess stands in, same style as
// tasks_reader_test.dart and decisions_reader_test.dart.

import 'package:asa/core/decisions_reader.dart';
import 'package:asa/core/inbox.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFileAccess implements FileAccess {
  FakeFileAccess(this.files);

  final Map<String, String> files;

  @override
  Future<List<String>> listFiles(String folder) async => [];

  @override
  Future<String> readFile(String path) async {
    final contents = files[path];
    if (contents == null) throw StateError('No fake file at $path');
    return contents;
  }
}

void main() {
  group('readInbox', () {
    test('reads the ## Tasks section of the home file, same shape as any '
        'project note', () async {
      final files = FakeFileAccess({
        r'C:\workspace\HOME.md':
            '# Home\n\n## Tasks\n\n- [ ] Call the dentist\n- [x] Renew '
            'passport\n',
      });

      final tasks = await readInbox(r'C:\workspace\HOME.md', files);

      expect(tasks, hasLength(2));
      expect(tasks[0].text, 'Call the dentist');
      expect(tasks[0].done, isFalse);
      expect(tasks[1].done, isTrue);
    });

    test(
      'no ## Tasks section yet reads as an empty inbox, not an error',
      () async {
        final files = FakeFileAccess({
          r'C:\workspace\HOME.md':
              '# Home\n\nJust the door, nothing typed yet.\n',
        });

        expect(await readInbox(r'C:\workspace\HOME.md', files), isEmpty);
      },
    );

    test('the file not existing at all also reads as an empty inbox — the '
        'first capture is what creates it', () async {
      expect(
        await readInbox(r'C:\workspace\HOME.md', FakeFileAccess({})),
        isEmpty,
      );
    });
  });
}
