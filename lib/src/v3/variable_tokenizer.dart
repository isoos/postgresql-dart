import 'package:charcode/charcode.dart';

import '../types.dart';
import 'query_description.dart';

/// In addition to indexed variables supported by the postgres protocol, most
/// postgres clients (including this package) support a variable mode in which
/// variables are identified by `@` followed by a name and an optional type.
///
/// Since this format is not natively understood by postgres, a translation
/// layer needs to happen in Dart.
/// A flexible [_variableCodeUnit] can be set to start a variable (we'll
/// assume `@`, the default, here). Then, a variable can be used with `@varname`.
/// Variable names can consist of alphanumeric characters and underscores.
/// As part of a variable, the type can also be declared (e.g. `@x:int8`). Valid
/// type names are given by [PgDataType.nameForSubstitution].
///
/// Just like postgres, we ignore variables inside string literals, identifiers
/// or comments.
class VariableTokenizer {
  /// A map from variable names (without the [_variableCodeUnit]) to their
  /// resolved index of the underlying SQL parameter.
  final Map<String, int> _namedVariables = {};

  /// The type of variables (by their index), resolved by looking at type
  /// annotations following a variable name.
  final Map<int, PgDataType> _variableTypes = {};

  /// The transformed SQL, replacing named variables with positional variables.
  final StringBuffer _rewrittenSql = StringBuffer();

  /// The code unit that starts a variable token.
  final int _variableCodeUnit;

  /// The original SQL string as written by the user.
  final String _source;

  /// THe list returned by [String.codeUnits] of [_source].
  final List<int> _codeUnits;

  /// Index of the next character to consider in [_codeUnits]
  int _index = 0;

  bool get _isAtEnd => _index == _codeUnits.length;

  VariableTokenizer({
    int variableCodeUnit = 64, // @
    required String sql,
  })  : _variableCodeUnit = variableCodeUnit,
        _source = sql,
        _codeUnits = sql.codeUnits;

  /// Builds an [InternalQueryDescription] after lexing (see [tokenize]) the
  /// source input.
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

  /// Reads the upcoming character and advances the read index.
  int _consume() => _codeUnits[_index++];

  /// Reads the upcoming character without advancing the read index.
  int _peek() => _codeUnits[_index];

  /// Advance the read index with [amount] character.
  void _advance([int amount = 1]) {
    _index += amount;
  }

  /// Returns true and advances the read index if the next character is
  /// [charCode]. Otherwise, returns false and leaves the current index unchanged.
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

  /// Reads the [_source] and transforms it.
  ///
  /// Comments are removed, and variable declarations are read and transformed
  /// into proper Postgres variables.
  void tokenize() {
    nextToken:
    while (!_isAtEnd) {
      // Invariant: At this point, we're not in a special token sequence (like
      // a string literal). The methods always consume the special token and
      // handle adding the lexeme to the transformed output.
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
            // Note that this also handles identifiers with unicode escape
            // sequences like `u&"\u1234"` because the `u` and the ampersand are
            // not interpreted in any other way and we skip to the next double
            // quote either way.
            _rewrittenSql.writeCharCode($doubleQuote);
            _continueEscapedIdentifier();
            continue nextToken;
          case $singleQuote:
            // Write start of string that has already been consumed
            _rewrittenSql.writeCharCode($singleQuote);
            _continueStringLiteral(enableEscapes: false);
            continue nextToken;
          case $dollar:
            _rewrittenSql.writeCharCode($dollar);
            _potentialDollarQuotedString();
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

  /// After reading the start of a block comment, this methods skips the until
  /// we find its end.
  void _blockComment() {
    // Look for `*/` sequence to end the comment
    while (!_isAtEnd) {
      final char = _consume();
      if (char == $asterisk) {
        if (_consumeIfMatches($slash)) return;
      }
    }
  }

  /// After reading the start of a line comment, this method skips the current
  /// source line.
  void _lineComment() {
    // Consume the rest of the line without adding it.
    while (!_isAtEnd) {
      final char = _consume();
      if (char == $cr || char == $lf) return;
    }
  }

  /// Handles a potential "dollar-quoted string" literal after consuming a
  /// dollar symbol character.
  ///
  /// For more details, see section 4.1.2.4. on https://www.postgresql.org/docs/current/sql-syntax-lexical.html
  void _potentialDollarQuotedString() {
    final escapeSequenceBuilder = StringBuffer(r'$');

    // See if this really is a dollar-quoted string: We assume it is if there
    // are alphanumeric characters until the next dollar sign. This has the
    // benefit of not accidentally consuming anything that could be part of
    // another token.
    while (!_isAtEnd) {
      final char = _consume();
      _rewrittenSql.writeCharCode(char);

      if (char == $dollar) {
        escapeSequenceBuilder.writeCharCode(char);
        break;
      } else if (_canAppearInVariable(char)) {
        escapeSequenceBuilder.writeCharCode(char);
      } else {
        // Not a dollar-quoted string literal.
        return;
      }
    }

    // Now, we interpret everything as a string literal until we see the escape
    // sequence again.
    final endSequence = escapeSequenceBuilder.toString();
    var matchedCharactersOfEndSequence = 0;

    while (!_isAtEnd) {
      final char = _consume();
      _rewrittenSql.writeCharCode(char);

      final nextCharInEndSequence =
          endSequence.codeUnitAt(matchedCharactersOfEndSequence);

      if (char == nextCharInEndSequence) {
        matchedCharactersOfEndSequence++;

        if (matchedCharactersOfEndSequence == endSequence.length) {
          // The entire end sequence has been matched, so the literal is over.
          return;
        }
      } else {
        // Okay, this didn't write the full escape sequence.
        matchedCharactersOfEndSequence = 0;
      }
    }
  }

  /// After reading the start of a string literal, this method reads the
  /// remainder of that literal and adds it to the transformed output.
  ///
  /// Handles "double single-quotes" as an escape sequence. If C-style escapes
  /// are enabled, `\'` is also not considered to end the string.
  void _continueStringLiteral({required bool enableEscapes}) {
    // Whether the next character is escaped by a preceding backslash.
    var characterIsEscaped = false;

    while (!_isAtEnd) {
      final char = _consume();

      if (characterIsEscaped) {
        _rewrittenSql.writeCharCode(char);
        characterIsEscaped = false;
        continue;
      } else if (char == $singleQuote) {
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
        characterIsEscaped = true;
      }
    }
  }

  /// After reading a double-quote, streams source characters into the output
  /// without changing them until we find the end of the identifier.
  void _continueEscapedIdentifier() {
    while (!_isAtEnd) {
      final char = _consume();
      _rewrittenSql.writeCharCode(char);

      if (char == $doubleQuote) return;
    }
  }

  /// Parses a variable after the initial character (most likely an `@`) has
  /// already been consumed.
  ///
  /// Replaces the declaration with a postgres variable (`$n`).
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

    while (!_isAtEnd) {
      final nextChar = _peek();
      if (isReadingName) {
        // part of name
        if (_canAppearInVariable(nextChar)) {
          nameBuffer.writeCharCode(nextChar);
          _advance();
          continue;
        }

        // next non-name character is not a colon
        if (nextChar != $colon) {
          break;
        }

        // we have double colons (server-side CAST)
        if (_index + 1 < _codeUnits.length &&
            _codeUnits[_index + 1] == $colon) {
          break;
        }

        // switching to reading the type
        _advance();
        consumedColonForType = true;
        isReadingName = false;
        continue;
      }

      // reading the type
      if (_canAppearInVariable(nextChar)) {
        typeBuffer.writeCharCode(nextChar);
        _advance();
        continue;
      }
      break;
    }

    if (nameBuffer.isEmpty) {
      // No variable then. The variable declaration syntax conflicts with some
      // postgres operators (e.g `@>`). So in that case, we just write the
      // original syntax.
      _rewrittenSql.writeCharCode(_variableCodeUnit);
      return;
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
      if (type == PgDataType.varCharArray && _peek() == $openParenthesis) {
        // read through `([0-9]+)`
        final closeOffset = _codeUnits.indexOf($closeParenthesis, _index);
        if (closeOffset == -1) {
          error('_varchar opening parenthesis without closing');
        }
        final length = closeOffset + 1 - _index;
        if (length <= 2 ||
            _codeUnits
                .skip(_index + 1)
                .take(length - 2)
                .any((c) => c < $0 || c > $9)) {
          error('expected _varchar([0-9]+)');
        }
        _advance(length);
      }
    }

    _rewrittenSql.write('\$$actualVariableIndex');
  }

  static bool _canAppearInVariable(int charcode) {
    return (charcode >= $0 && charcode <= $9) ||
        (charcode >= $a && charcode <= $z) ||
        (charcode >= $A && charcode <= $Z) ||
        charcode == $underscore;
  }
}
