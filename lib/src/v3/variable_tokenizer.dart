import 'package:charcode/charcode.dart';

import 'query_description.dart';
import 'types.dart';

/// In addition to indexed variables supported by the postgres protocol, most
/// postgres clients (including this package) support a variable mode in which
/// variables are identified by `@` followed by a name and an optional type.a
class VariableTokenizer {
  final Map<String, int> _namedVariables = {};
  final Map<int, PgDataType> _variableTypes = {};
  final StringBuffer _rewrittenSql = StringBuffer();

  final int _variableCodeUnit;
  final String _source;
  final List<int> _codeUnits;

  int _index = 0;

  bool get _isAtEnd => _index == _codeUnits.length;

  VariableTokenizer({
    int variableCodeUnit = 64, // @
    required String sql,
  })  : _variableCodeUnit = variableCodeUnit,
        _source = sql,
        _codeUnits = sql.codeUnits;

  InternalQueryDescription get result {
    return InternalQueryDescription.transformed(
      _source,
      _rewrittenSql.toString(),
      [
        for (final entry in _namedVariables.entries)
          _variableTypes[entry.value],
      ],
      _namedVariables,
    );
  }

  int _consume() => _codeUnits[_index++];

  bool _consumeIfMatches(int charCode) {
    if (_isAtEnd) return false;

    final next = _codeUnits[_index];
    if (next == charCode) {
      _index++;
      return true;
    } else {
      return false;
    }
  }

  void tokenize() {
    nextToken:
    while (!_isAtEnd) {
      final startIndex = _index;
      final charCode = _consume();

      if (charCode == _variableCodeUnit) {
        _startVariable(startIndex);
        continue nextToken;
      } else {
        switch (charCode) {
          case $slash:
            // `/*`, block comment
            if (_consumeIfMatches($asterisk)) {
              _blockComment();
              continue nextToken;
            }
            break;
          case $minus:
            // `--`, line comment
            if (_consumeIfMatches($minus)) {
              _lineComment();
              continue nextToken;
            }
            break;
          case $doubleQuote:
            // Double quote has already been consumed, but is part of the identifier
            _rewrittenSql.writeCharCode($doubleQuote);
            _continueEscapedIdentifier();
            continue nextToken;
          case $singleQuote:
            // Write start of string that has already been consumed
            _rewrittenSql.writeCharCode($singleQuote);
            _continueStringLiteral(enableEscapes: false);
            continue nextToken;
          case $e:
          case $E:
            if (_consumeIfMatches($singleQuote)) {
              // https://cloud.google.com/spanner/docs/reference/postgresql/lexical#string_constants_with_c-style_escapes
              _rewrittenSql
                ..writeCharCode(charCode) // e or E
                ..writeCharCode($singleQuote);

              _continueStringLiteral(enableEscapes: true);
              continue nextToken;
            }
        }
      }

      // This char has no special meaning, add it to the SQL string.
      _rewrittenSql.writeCharCode(charCode);
    }
  }

  void _blockComment() {
    // Look for `*/` sequence to end the comment
    while (!_isAtEnd) {
      final char = _consume();
      if (char == $asterisk) {
        if (_consumeIfMatches($slash)) return;
      }
    }
  }

  void _lineComment() {
    // Consume the rest of the line without adding it.
    while (!_isAtEnd) {
      final char = _consume();
      if (char == $cr || char == $lf) return;
    }
  }

  void _continueStringLiteral({required bool enableEscapes}) {
    while (!_isAtEnd) {
      final char = _consume();

      if (char == $singleQuote) {
        // Two adjacent single quotes are a escape sequence and don't end the
        // string
        if (_consumeIfMatches($singleQuote)) {
          _rewrittenSql
            ..writeCharCode($singleQuote)
            ..writeCharCode($singleQuote);
          continue;
        } else {
          // End of string
          _rewrittenSql.writeCharCode(char);
          return;
        }
      }

      _rewrittenSql.writeCharCode(char);

      if (enableEscapes && char == $backslash) {
        // If this is followed by a single quote, it is escaped and doesn't end
        // the string.
        if (_consumeIfMatches($singleQuote)) {
          _rewrittenSql.writeCharCode($singleQuote);
        }
      }
    }
  }

  void _continueEscapedIdentifier() {
    while (!_isAtEnd) {
      final char = _consume();
      _rewrittenSql.writeCharCode(char);

      if (char == $doubleQuote) return;
    }
  }

  void _startVariable(int startPosition) {
    // The syntax for a variable is `@<variableName>(:<typeName>)?`. When this
    // method gets called, the at character has already been consumed.
    final nameBuffer = StringBuffer();
    final typeBuffer = StringBuffer();

    Never error(String message) {
      final lexeme = _source.substring(startPosition, _index);

      throw FormatException(
          'Error at offset $startPosition ($lexeme): $message');
    }

    var isReadingName = true;
    var consumedColonForType = false;
    int? charAfterVariable;

    while (!_isAtEnd) {
      final nextChar = _consume();
      if (_canAppearInVariable(nextChar)) {
        if (isReadingName) {
          nameBuffer.writeCharCode(nextChar);
        } else {
          typeBuffer.writeCharCode(nextChar);
        }
      } else if (!consumedColonForType && nextChar == $colon) {
        consumedColonForType = true;
        isReadingName = false;
      } else {
        charAfterVariable = nextChar;
        break;
      }
    }

    if (nameBuffer.isEmpty) {
      error('Empty variable name');
    }
    if (consumedColonForType && typeBuffer.isEmpty) {
      error('Expected type name after colon');
    }

    final actualVariableIndex = _namedVariables.putIfAbsent(
        nameBuffer.toString(), () => _namedVariables.length + 1);

    if (consumedColonForType) {
      final typeName = typeBuffer.toString();
      final type = PgDataType.bySubstitutionName[typeName];
      if (type == null) {
        error('Unknown type: $typeName');
      }

      _variableTypes[actualVariableIndex] = type;
    }

    _rewrittenSql.write('\$$actualVariableIndex');
    if (charAfterVariable != null) {
      _rewrittenSql.writeCharCode(charAfterVariable);
    }
  }

  static bool _canAppearInVariable(int charcode) {
    return (charcode >= $0 && charcode <= $9) ||
        (charcode >= $a && charcode <= $z) ||
        (charcode >= $A && charcode <= $Z) ||
        charcode == $underscore;
  }
}
