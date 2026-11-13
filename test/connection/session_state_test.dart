import 'package:postgres/src/connection/session_state.dart';
import 'package:test/test.dart';

void main() {
  void expectState(String sql, SqlSessionState expected) {
    expect(classifySessionState(sql), expected, reason: sql);
  }

  group('classifySessionState', () {
    test('plain reads and writes leave nothing behind', () {
      for (final sql in [
        'SELECT 1',
        'SELECT * FROM "note" ORDER BY "id" LIMIT 20 OFFSET 0',
        'INSERT INTO "note" ("title", "content") VALUES (\'t\', \'c\') RETURNING *',
        'DELETE FROM "note" WHERE "id" = 3',
        'SELECT "settings", "offset" FROM t',
      ]) {
        expectState(sql, SqlSessionState.none);
      }
    });

    test('the SET of an UPDATE is not a session setting', () {
      for (final sql in [
        'UPDATE t SET a = 1',
        'update t set a = 1 where id = 2',
        'UPDATE ONLY t SET a = 1',
        'UPDATE "public"."note" SET "title" = \'x\' WHERE "id" = 1 RETURNING *',
        'UPDATE t AS x SET a = 1',
        'UPDATE t x SET a = 1',
        'UPDATE\n  t\nSET a = 1',
        'INSERT INTO t (id, a) VALUES (1, 2) ON CONFLICT (id) DO UPDATE SET a = EXCLUDED.a',
      ]) {
        expectState(sql, SqlSessionState.none);
      }
    });

    test('keywords inside quoted literals and identifiers are ignored', () {
      for (final sql in [
        "INSERT INTO t (a) VALUES ('Load the dishwasher, then set the table')",
        "INSERT INTO t (a) VALUES ('it''s temp; SET x = 1')",
        'SELECT "temp", "load" FROM t',
        "UPDATE \"note\" SET \"content\" = 'prepare to listen' WHERE id = 1",
      ]) {
        expectState(sql, SqlSessionState.none);
      }
    });

    test('session settings and other session state are detected', () {
      for (final sql in [
        "SET application_name = 'x'",
        'set search_path to a',
        'SET LOCAL statement_timeout = 0',
        "SELECT set_config('search_path', 'a', false)",
        'LISTEN chan',
        'PREPARE p AS SELECT 1',
        'DECLARE c CURSOR WITH HOLD FOR SELECT 1',
        "LOAD 'auto_explain'",
        'CREATE TEMP TABLE t (a int)',
        'CREATE TEMPORARY TABLE t (a int)',
        'SELECT lo_open(1, 2)',
        // A real SET after an UPDATE in the same text.
        'UPDATE t SET a = 1; SET search_path = a',
        // Keyword after a semicolon inside an UPDATE target that isn't a
        // plain name is still matched.
        'UPDATE t; SET search_path = a',
      ]) {
        expectState(sql, SqlSessionState.stateful);
      }
    });

    test('text where quotes may not mean what they seem is matched as is', () {
      for (final sql in [
        // A quote inside a comment.
        "-- don't\nSET search_path = a",
        "/* it's */ SET search_path = a",
        // Backslash-escaped quote in an escape string.
        r"SELECT E'it\'s'; SET search_path = a",
        // Dollar-quoted body.
        r"DO $$ BEGIN EXECUTE 'SET search_path = a'; END $$",
      ]) {
        expectState(sql, SqlSessionState.stateful);
      }
      // With a comment present, literals are not stripped, so a keyword
      // inside one still counts (a safe false positive).
      expectState(
        "-- note\nINSERT INTO t VALUES ('set')",
        SqlSessionState.stateful,
      );
    });

    test('session advisory locks are detected', () {
      for (final sql in [
        'SELECT pg_advisory_lock(1)',
        'SELECT pg_try_advisory_lock(1)',
        'SELECT pg_advisory_lock_shared(1)',
      ]) {
        expectState(sql, SqlSessionState.sessionLock);
      }
    });
  });
}
