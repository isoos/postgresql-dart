import 'package:postgres/legacy.dart';
import 'package:postgres/postgres.dart';
import 'package:postgres/src/types/type_registry.dart';
import 'package:postgres/src/v2/query.dart';
import 'package:test/test.dart';

void main() {
  test('Ensure all types/format type mappings are available and accurate', () {
    final withoutMapping = {
      Type.unspecified, // Can't bind into unspecified type
      Type.voidType, // Can't assign to void
      Type.bigSerial, // Can only be created from a table sequence
      Type.serial,
    };

    for (final type in TypeRegistry().registered) {
      if (withoutMapping.contains(type)) continue;

      expect(
        PostgreSQLFormatIdentifier.typeStringToCodeMap.registered
            .contains(type),
        true,
        reason: 'There should be a type mapping for $type',
      );
      final code = PostgreSQLFormat.dataTypeStringForDataType(type);
      expect(
          PostgreSQLFormatIdentifier.typeStringToCodeMap
              .resolveSubstitution(code!),
          type);
    }
  });

  test('Ensure bigserial gets translated to int8', () {
    expect(PostgreSQLFormat.dataTypeStringForDataType(Type.serial), 'int4');
  });

  test('Ensure serial gets translated to int4', () {
    expect(PostgreSQLFormat.dataTypeStringForDataType(Type.bigSerial), 'int8');
  });
}
