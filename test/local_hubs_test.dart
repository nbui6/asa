// Round 7's fork seam — see FOR-YOUR-FORK.md. The whole point of this
// file is that it compiles and stays empty; there is nothing else to
// test until a fork actually adds something to it.

import 'package:asa/local/local_hubs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localHubs is empty in this repository', () {
    expect(localHubs, isEmpty);
  });
}
