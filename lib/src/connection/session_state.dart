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

// Statements that may leave state behind on the server session. This is
// deliberately broad: a false positive only costs one extra reset. The one
// exception is the `SET` of an `UPDATE` (including `ON CONFLICT DO UPDATE`),
// which is the most common statement there is and never changes the session.
final _statefulSql = RegExp(
  r'\b(?:'
  r'(?<!\bupdate\s+(?:only\s+)?[\w."]+(?:\s+(?:as\s+)?\w+)?\s+)'
  r'(?<!\bdo\s+update\s+)'
  'set'
  r'|listen|prepare|declare|load|set_config|temp|temporary|lo_\w+'
  r'|pg_(?:try_)?advisory_lock\w*'
  r')\b',
  caseSensitive: false,
);

// Session-level advisory locks (the transaction-level `_xact_` variants
// release themselves) keep blocking other sessions until released. Every
// match is also a match of [_statefulSql].
final _sessionLockSql = RegExp(
  r'\bpg_(?:try_)?advisory_lock\w*',
  caseSensitive: false,
);

// A quoted literal or identifier, with doubled quotes as escapes.
final _quoted = RegExp(
  "'(?:[^']|'')*'"
  '|"(?:[^"]|"")*"',
);

/// Classifies [sql] by what it may leave behind on the server session.
///
/// Keywords inside plain string literals and quoted identifiers are ignored
/// (`INSERT ... VALUES ('Load the dishwasher')` changes nothing). That is only
/// done when the text has no comments, backslashes or dollar quotes, which
/// could make a quote start somewhere other than where it seems to; such text
/// is matched as it is, which can only err towards a reset.
@internal
SqlSessionState classifySessionState(String sql) {
  var text = sql;
  if ((text.contains("'") || text.contains('"')) &&
      !text.contains('--') &&
      !text.contains('/*') &&
      !text.contains(r'\') &&
      !text.contains(r'$')) {
    // Keep the quote kind, so `UPDATE "t" SET` is still seen as an update.
    text = text.replaceAllMapped(
      _quoted,
      (m) => m[0]!.startsWith("'") ? "''" : '""',
    );
  }
  if (!_statefulSql.hasMatch(text)) return SqlSessionState.none;
  return _sessionLockSql.hasMatch(text)
      ? SqlSessionState.sessionLock
      : SqlSessionState.stateful;
}
