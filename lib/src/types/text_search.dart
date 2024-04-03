import 'package:postgres/src/exceptions.dart';

import '../buffer.dart';
import '../types.dart';
import 'generic_type.dart';
import 'type_registry.dart';

/// The `tsvector` data type stores a list of [Lexeme]s, optionally with
/// integer positions and weights.
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

/// A lexeme is a word that have been normalized, alongside with the
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
  }) {
    assert(position >= 1);
    assert(position <= 16383);
  }

  factory LexemePos._parse(int value) {
    final pos = value & 0x3fff;
    final weight = (value >> 14) & 0x03;
    return LexemePos(pos, weight: LexemeWeight.values[3 - weight]);
  }

  @override
  String toString() => [
        position,
        if (weight != LexemeWeight.d) weight.name.toUpperCase(),
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

/// The `tsquery` type represents a search query for text search.
///
/// https://www.postgresql.org/docs/current/datatype-textsearch.html
/// https://www.postgresql.org/docs/current/textsearch.html
abstract class TsQuery {
  int get _itemCount;
  void _write(PgByteDataWriter writer);

  static TsQuery lexeme(String text) => _LexemeTsQuery._(text, 0, 0);
  static TsQuery not(TsQuery query) => _NotTsQuery(query);

  TsQuery or(TsQuery other) => _OrTsQuery._()
    .._add(this)
    .._add(other);

  TsQuery and(TsQuery other) => _AndTsQuery._()
    .._add(this)
    .._add(other);

  TsQuery followedBy(TsQuery other, {int? distance}) =>
      _PhraseTsQuery(this, other, distance ?? 1);
}

class TsQueryType extends Type<TsQuery> {
  const TsQueryType() : super(TypeOid.tsquery);

  EncodeOutput encode(EncodeInput input) {
    final v = input.value as TsQuery;
    final writer = PgByteDataWriter(encoding: input.encoding);
    writer.writeUint32(v._itemCount);
    v._write(writer);

    final bytes = writer.toBytes();
    return EncodeOutput.bytes(bytes);
  }

  TsQuery? decode(DecodeInput input) {
    if (input.isBinary) {
      final reader = PgByteDataReader(encoding: input.encoding)
        ..add(input.bytes);
      final count = reader.readUint32();
      final items = [];
      for (var i = 0; i < count; i++) {
        final kind = reader.readUint8();
        switch (kind) {
          case 1: // value
            final weight = reader.readUint8();
            final prefix = reader.readUint8();
            final text = reader.readNullTerminatedString();
            items.add(_LexemeTsQuery._(text, weight, prefix));
            break;
          case 2: // operation
            final opKind = reader.readUint8();
            switch (opKind) {
              case 1: // not
              case 2: // and
              case 3: // or
                items.add(_Op(opKind));
                break;
              case 4: // phrase
                final distance = reader.readUint16();
                items.add(_Op(opKind, distance: distance));
                break;
              default:
                throw UnimplementedError('Unknown op kind: $opKind');
            }
          default:
            throw UnimplementedError('Unknown kind: $kind');
        }
        bool pushItems() {
          if (items.length < 2) return false;
          final last = items.last;
          if (last is! TsQuery) return false;
          final prev = items[items.length - 2];
          if (prev is _Op && prev.kind == 1) {
            items.removeLastN(2);
            items.add(_NotTsQuery(last));
            return true;
          }
          if (prev is! TsQuery) return false;
          if (items.length < 3) return false;
          final maybeOp = items[items.length - 3];
          if (maybeOp is! _Op) return false;
          if (maybeOp.kind == 2) {
            items.removeLastN(3);
            items.add(last.and(prev));
            return true;
          }
          if (maybeOp.kind == 3) {
            items.removeLastN(3);
            items.add(last.or(prev));
            return true;
          }
          if (maybeOp.kind == 4) {
            items.removeLastN(3);
            items.add(_PhraseTsQuery(last, prev, maybeOp.distance!));
            return true;
          }
          return false;
        }

        while (pushItems()) {}
      }
      if (items.length == 1 && items.single is TsQuery) {
        return items.single as TsQuery;
      }
      throw PgException(
          'Unable to parse TsQuery: ${items.join(', ')} ${input.bytes}');
    } else {
      throw UnimplementedError();
    }
  }
}

extension _ListExt<T> on List<T> {
  void removeLastN(int n) {
    removeRange(length - n, length);
  }
}

class _LexemeTsQuery extends TsQuery {
  final String _text;
  final int _weights;
  final int _prefix;

  _LexemeTsQuery._(this._text, this._weights, this._prefix);

  @override
  int get _itemCount => 1;

  @override
  void _write(PgByteDataWriter writer) {
    writer.writeUint8(1);
    writer.writeInt8(_weights);
    writer.writeInt8(_prefix);
    writer.writeEncodedString(writer.encodeString(_text));
  }

  @override
  String toString() => _text;
}

class _AndTsQuery extends TsQuery {
  final _items = <TsQuery>[];
  _AndTsQuery._();

  void _add(TsQuery q) {
    if (q is _AndTsQuery) {
      _items.addAll(q._items);
    } else {
      _items.add(q);
    }
  }

  @override
  int get _itemCount =>
      _items.fold(_items.length - 1, (p, e) => p + e._itemCount);

  @override
  void _write(PgByteDataWriter writer) {
    for (var i = _items.length - 1; i >= 0; i--) {
      if (i > 0) {
        writer.writeUint8(2);
        writer.writeInt8(2);
      }
      _items[i]._write(writer);
    }
  }

  @override
  String toString() => '(${_items.join(' & ')})';
}

class _OrTsQuery extends TsQuery {
  final _items = <TsQuery>[];
  _OrTsQuery._();

  void _add(TsQuery q) {
    if (q is _OrTsQuery) {
      _items.addAll(q._items);
    } else {
      _items.add(q);
    }
  }

  @override
  int get _itemCount =>
      _items.fold(_items.length - 1, (p, e) => p + e._itemCount);

  @override
  void _write(PgByteDataWriter writer) {
    for (var i = _items.length - 1; i >= 0; i--) {
      if (i > 0) {
        writer.writeUint8(2);
        writer.writeInt8(3);
      }
      _items[i]._write(writer);
    }
  }

  @override
  String toString() => '(${_items.join(' | ')})';
}

class _NotTsQuery extends TsQuery {
  final TsQuery _inner;

  _NotTsQuery(this._inner);

  @override
  int get _itemCount => 1 + _inner._itemCount;

  @override
  void _write(PgByteDataWriter writer) {
    writer.writeUint8(2);
    writer.writeInt8(1);
    _inner._write(writer);
  }

  @override
  String toString() => '!$_inner';
}

class _PhraseTsQuery extends TsQuery {
  final TsQuery _left;
  final TsQuery _right;
  final int _distance;

  _PhraseTsQuery(this._left, this._right, this._distance);

  @override
  int get _itemCount => 1 + _left._itemCount + _right._itemCount;

  @override
  void _write(PgByteDataWriter writer) {
    writer.writeUint8(2);
    writer.writeInt8(4);
    writer.writeUint16(_distance);
    _right._write(writer);
    _left._write(writer);
  }

  @override
  String toString() => '$_left <$_distance> $_right';
}

class _Op {
  final int kind;
  final int? distance;

  _Op(this.kind, {this.distance});
}
