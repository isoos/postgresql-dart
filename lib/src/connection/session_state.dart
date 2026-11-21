import 'package:meta/meta.dart';

/// What a statement may leave behind on the server session.
@internal
enum SqlSessionState {
  /// Nothing that outlives the statement's transaction.
  none,

  /// Settings, listeners, prepared statements, cursors, temp objects...
  stateful,

  /// A session-level advisory lock (also [stateful]).
  sessionLock,
}

/// Classifies [sql] by what it may leave behind on the server session.
///
/// This runs for every statement, so it is a single pass over the text with
/// no regular expressions (which run in an interpreter in AOT builds).
///
/// A statement counts as stateful when it contains one of these words:
/// `set`, `listen`, `prepare`, `declare`, `load`, `set_config`, `temp`,
/// `temporary`, a `lo_*` function, or `pg_advisory_lock*` /
/// `pg_try_advisory_lock*` (which are also session locks). This is
/// deliberately broad: a false positive only costs one extra reset. Two cases
/// are not counted, as they never change the session and are very common:
///
/// - the `SET` of an `UPDATE [ONLY] <target> [[AS] alias] SET` or a
///   `DO UPDATE SET`,
/// - words inside quoted literals (`'...'`) and identifiers (`"..."`). Only
///   when the text has no comments, backslashes or dollar quotes, which could
///   make a quote start somewhere other than where it seems to; such text is
///   scanned as it is, which can only err towards a reset.
@internal
SqlSessionState classifySessionState(String sql) {
  return _Scanner(sql, _canSkipQuoted(sql)).run();
}

/// Whether [sql] has quotes, and none of comments, backslashes or dollar
/// quotes. One pass over the code units: a `String.contains` per marker cost
/// more than the scan itself.
bool _canSkipQuoted(String sql) {
  var quotes = false;
  final n = sql.length;
  for (var k = 0; k < n; k++) {
    switch (sql.codeUnitAt(k)) {
      case _singleQuote || _doubleQuote:
        quotes = true;
      case _backslash || _dollar:
        return false;
      case _dash when k + 1 < n && sql.codeUnitAt(k + 1) == _dash:
        return false;
      case _slash when k + 1 < n && sql.codeUnitAt(k + 1) == _star:
        return false;
    }
  }
  return quotes;
}

const _a = 0x61, _z = 0x7a, _upperA = 0x41, _upperZ = 0x5a;
const _zero = 0x30, _nine = 0x39, _underscore = 0x5f, _dot = 0x2e;
const _singleQuote = 0x27, _doubleQuote = 0x22;
const _backslash = 0x5c, _dollar = 0x24, _dash = 0x2d, _slash = 0x2f;
const _star = 0x2a;

bool _isWordChar(int c) =>
    (c >= _a && c <= _z) ||
    (c >= _upperA && c <= _upperZ) ||
    (c >= _zero && c <= _nine) ||
    c == _underscore;

bool _isSpace(int c) => c == 0x20 || (c >= 0x09 && c <= 0x0d);

int _lower(int c) => c >= _upperA && c <= _upperZ ? c + 0x20 : c;

/// Where the scanner is within `UPDATE [ONLY] <target> [[AS] alias] SET`.
enum _Update { none, afterUpdate, afterOnly, afterTarget, afterAs, afterAlias }

class _Scanner {
  _Scanner(this.sql, this.skipQuoted);

  final String sql;
  final bool skipQuoted;
  int i = 0;
  bool stateful = false;

  /// The previous word was `do`.
  bool afterDo = false;

  /// The previous words were `do update`.
  bool afterDoUpdate = false;
  _Update update = _Update.none;

  SqlSessionState run() {
    final n = sql.length;
    while (i < n) {
      final c = sql.codeUnitAt(i);
      if (_isSpace(c)) {
        i++;
        continue;
      }
      if ((update == _Update.afterUpdate || update == _Update.afterOnly) &&
          (_isWordChar(c) || c == _dot || c == _doubleQuote)) {
        // The target: a run of word characters, dots and quoted identifiers.
        final start = i;
        _skipTarget();
        if (_wordEquals(start, i, 'set')) {
          // `DO UPDATE SET` is an upsert; `UPDATE SET` has no target, so the
          // `set` is matched as a word.
          if (!afterDoUpdate) {
            i = start;
          }
          update = _Update.none;
          afterDoUpdate = false;
          continue;
        }
        afterDoUpdate = false;
        update = update == _Update.afterUpdate && _wordEquals(start, i, 'only')
            ? _Update.afterOnly
            : _Update.afterTarget;
        continue;
      }
      if (_isWordChar(c)) {
        final start = i;
        while (i < n && _isWordChar(sql.codeUnitAt(i))) {
          i++;
        }
        if (_word(start, i)) return SqlSessionState.sessionLock;
        continue;
      }
      if (skipQuoted && (c == _singleQuote || c == _doubleQuote)) {
        _skipQuoted(c);
        // A quoted identifier can be an alias, like a word.
        update =
            c == _doubleQuote &&
                (update == _Update.afterTarget || update == _Update.afterAs)
            ? _Update.afterAlias
            : _Update.none;
        afterDo = false;
        afterDoUpdate = false;
        continue;
      }
      // Any other character ends an UPDATE clause.
      update = _Update.none;
      afterDo = false;
      afterDoUpdate = false;
      i++;
    }
    return stateful ? SqlSessionState.stateful : SqlSessionState.none;
  }

  /// Handles the word in [start, end). Returns true for a session lock.
  bool _word(int start, int end) {
    final len = end - start;
    final wasAfterDo = afterDo;
    afterDo = false;
    afterDoUpdate = false;
    if (_wordEquals(start, end, 'set')) {
      final inUpdate =
          update == _Update.afterTarget || update == _Update.afterAlias;
      update = _Update.none;
      if (!inUpdate) stateful = true;
      return false;
    }
    if (update == _Update.afterTarget) {
      update = _wordEquals(start, end, 'as')
          ? _Update.afterAs
          : _Update.afterAlias;
      return false;
    }
    if (update == _Update.afterAs) {
      update = _Update.afterAlias;
      return false;
    }
    update = _Update.none;
    switch (len) {
      case 2:
        if (_wordEquals(start, end, 'do')) afterDo = true;
      case 4:
        if (_wordEquals(start, end, 'load') ||
            _wordEquals(start, end, 'temp')) {
          stateful = true;
        }
      case 6:
        if (_wordEquals(start, end, 'listen')) {
          stateful = true;
        } else if (_wordEquals(start, end, 'update')) {
          update = _Update.afterUpdate;
          afterDoUpdate = wasAfterDo;
        }
      case 7:
        if (_wordEquals(start, end, 'prepare') ||
            _wordEquals(start, end, 'declare')) {
          stateful = true;
        }
      case 9:
        if (_wordEquals(start, end, 'temporary')) stateful = true;
      case 10:
        if (_wordEquals(start, end, 'set_config')) stateful = true;
    }
    if (len > 3 && _startsWith(start, end, 'lo_')) stateful = true;
    if (_startsWith(start, end, 'pg_advisory_lock') ||
        _startsWith(start, end, 'pg_try_advisory_lock')) {
      stateful = true;
      return true;
    }
    return false;
  }

  void _skipTarget() {
    final n = sql.length;
    while (i < n) {
      final c = sql.codeUnitAt(i);
      if (c == _doubleQuote && skipQuoted) {
        _skipQuoted(_doubleQuote);
      } else if (_isWordChar(c) || c == _dot || c == _doubleQuote) {
        i++;
      } else {
        return;
      }
    }
  }

  /// Skips a quoted literal or identifier starting at [i], with doubled quotes
  /// as escapes. An unterminated one runs to the end of the text (the server
  /// rejects such a statement).
  void _skipQuoted(int quote) {
    final n = sql.length;
    i++;
    while (i < n) {
      if (sql.codeUnitAt(i) == quote) {
        if (i + 1 < n && sql.codeUnitAt(i + 1) == quote) {
          i += 2;
          continue;
        }
        i++;
        return;
      }
      i++;
    }
  }

  /// Whether [start, end) is [lower] (ASCII, case-insensitive).
  bool _wordEquals(int start, int end, String lower) =>
      end - start == lower.length && _startsWith(start, end, lower);

  /// Whether [start, end) starts with [lower] (ASCII, case-insensitive).
  bool _startsWith(int start, int end, String lower) {
    if (end - start < lower.length) return false;
    for (var k = 0; k < lower.length; k++) {
      if (_lower(sql.codeUnitAt(start + k)) != lower.codeUnitAt(k)) {
        return false;
      }
    }
    return true;
  }
}
