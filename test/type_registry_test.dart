import 'dart:async';

import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _SyncCodec extends Codec {
  @override
  EncodedValue? encode(TypedValue input, CodecContext context) => null;

  @override
  Object? decode(EncodedValue input, CodecContext context) => 'sync-decoded';
}

class _AsyncCodec extends Codec {
  @override
  EncodedValue? encode(TypedValue input, CodecContext context) => null;

  @override
  Future<Object?> decode(EncodedValue input, CodecContext context) async {
    await Future<void>.delayed(Duration.zero);
    return 'async-decoded';
  }
}

void main() {
  group('TypeRegistry.decode', () {
    test('returns a plain value (no Future) for a synchronous codec', () {
      final registry = TypeRegistry(codecs: {1: _SyncCodec()});
      final context = CodecContext.withDefaults(typeRegistry: registry);

      final result = registry.decode(
        EncodedValue.binary(null, typeOid: 1),
        context,
      );

      expect(result, isNot(isA<Future>()));
      expect(result, 'sync-decoded');
    });

    test(
      'returns a Future and resolves correctly for an async codec',
      () async {
        final registry = TypeRegistry(codecs: {1: _AsyncCodec()});
        final context = CodecContext.withDefaults(typeRegistry: registry);

        final result = registry.decode(
          EncodedValue.binary(null, typeOid: 1),
          context,
        );

        expect(result, isA<Future>());
        expect(await result, 'async-decoded');
      },
    );
  });
}
