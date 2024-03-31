import 'package:postgres/src/buffer.dart';
import 'package:postgres/src/types.dart';
import 'package:postgres/src/types/generic_type.dart';
import 'package:postgres/src/types/type_registry.dart';

/// The `tsvector` type represents a document in a form optimized for text search.
/// A [TsVector] is a sorted list of distinct [Lexeme]s.
///
/// https://www.postgresql.org/docs/current/datatype-textsearch.html
/// https://www.postgresql.org/docs/current/textsearch.html
class TsVector {
  final List<Lexeme> lexemes;

  TsVector({
    required this.lexemes,
  });

  @override
  String toString() => lexemes.join(' ');
}

/// A lexeme is a words that have been normalized, alongside with the
/// positional information.
class Lexeme {
  final String text;
  final List<LexemePos>? positions;

  Lexeme(this.text, {this.positions});

  @override
  String toString() => [
        text,
        if (positions != null && positions!.isNotEmpty) positions!.join(','),
      ].join(':');
}

/// The weight of the [Lexeme].
enum LexemeWeight { a, b, c, d }

/// A position normally indicates the source word's location in the document.
/// Positional information can be used for proximity ranking. Position values
/// can range from 1 to 16383; larger numbers are silently set to 16383.
/// Duplicate positions for the same lexeme are discarded.
///
/// Lexemes that have positions can further be labeled with a weight, which
/// can be A, B, C, or D. D is the default.
class LexemePos {
  final int position;
  final LexemeWeight weight;

  LexemePos(
    this.position, {
    this.weight = LexemeWeight.d,
  });

  factory LexemePos._parse(int value) {
    final pos = value & 0x3fff;
    final weight = (value >> 14) & 0x03;
    return LexemePos(pos, weight: LexemeWeight.values[3 - weight]);
  }

  @override
  String toString() => [
        position,
        weight.name.toUpperCase(),
      ].join();
}

class TsVectorType extends Type<TsVector> {
  const TsVectorType() : super(TypeOid.tsvector);

  EncodeOutput encode(EncodeInput input) {
    final v = input.value as TsVector;
    final writer = PgByteDataWriter(encoding: input.encoding);
    writer.writeUint32(v.lexemes.length);
    for (final lexeme in v.lexemes) {
      writer.writeEncodedString(writer.encodeString(lexeme.text));
      final positions = lexeme.positions;
      if (positions == null || positions.isEmpty) {
        writer.writeUint16(0);
      } else {
        writer.writeUint16(positions.length);
        for (final pos in positions) {
          final w = 3 - pos.weight.index;
          writer.writeUint16((w << 14) + pos.position);
        }
      }
    }
    final bytes = writer.toBytes();
    return EncodeOutput.bytes(bytes);
  }

  TsVector? decode(DecodeInput input) {
    if (input.isBinary) {
      final reader = PgByteDataReader(encoding: input.encoding)
        ..add(input.bytes);
      final count = reader.readUint32();
      final lexemes = <Lexeme>[];
      for (var i = 0; i < count; i++) {
        final text = reader.readNullTerminatedString();
        final positionCount = reader.readUint16();
        final positions = positionCount == 0
            ? null
            : List.generate(
                positionCount, (_) => LexemePos._parse(reader.readUint16()));
        final lexeme = Lexeme(text, positions: positions);
        lexemes.add(lexeme);
      }
      return TsVector(lexemes: lexemes);
    } else {
      throw UnimplementedError();
    }
  }
}

class TsQuery {}
