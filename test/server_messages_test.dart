import 'dart:typed_data';

import 'package:postgres/src/server_messages.dart';
import 'package:test/test.dart';

void main() {
  test('UnknownMessage equality', () {
    final a = UnknownMessage(1, Uint8List.fromList([0]));
    final b = UnknownMessage(1, null);
    final c = UnknownMessage(null, Uint8List.fromList([0]));
    final d = UnknownMessage(1, Uint8List.fromList([0]));
    // == needs to null check the data field
    expect(a != b, isTrue);

    /// == needs to null check the code field
    expect(a != c, isTrue);

    // == needs needs to check the type before comparing.
    // ignore: unrelated_type_equality_checks
    expect(a != 2, isTrue);

    // equal objects should be equal
    expect(a == d, isTrue);
  });
}
