import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:async';
import 'dart:mirrors';

void main() {
  group("Normal behavior", () {
    PostgreSQLConnection conn = null;

    tearDown(() async {
      await conn?.close();
    });

    test("Connect with md5 auth required", () async {
      conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
      await conn.open();

      expect(await conn.execute("select 1"), equals(1));
    });

    test("Connect with no auth required", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      expect(await conn.execute("select 1"), equals(1));
    });

    test("Issuing multiple queries and awaiting between each one successfully returns the right value", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      expect(await conn.query("select 1"), equals([[1]]));
      expect(await conn.query("select 2"), equals([[2]]));
      expect(await conn.query("select 3"), equals([[3]]));
      expect(await conn.query("select 4"), equals([[4]]));
      expect(await conn.query("select 5"), equals([[5]]));
    });

    test("Issuing multiple queries without awaiting are returned with appropriate values", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      var futures = [
        conn.query("select 1"),
        conn.query("select 2"),
        conn.query("select 3"),
        conn.query("select 4"),
        conn.query("select 5")
      ];
      var results = await Future.wait(futures);

      expect(results, [[[1]], [[2]], [[3]], [[4]], [[5]]]);
    });

    test("Closing idle connection succeeds, closes underlying socket", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      await conn.close();

      var socketMirror = reflect(conn).type.declarations.values.firstWhere((DeclarationMirror dm) => dm.simpleName.toString().contains("_socket"));
      Socket underlyingSocket = reflect(conn).getField(socketMirror.simpleName).reflectee;
      expect(await underlyingSocket.done, isNotNull);

      conn = null;
    });

    test("Closing connection while busy succeeds, queued queries are all accounted for (canceled), closes underlying socket", () async {

    });
  });

  group("Unintended user-error situations", () {
    test("Sending queries to opening connection triggers error", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      conn.open();

      try {
        await conn.execute("select 1");
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains("connection is not open"));
      }
    });

    test("Invalid password reports error, conn is closed, disables conn", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "notdart");

      try {
        await conn.open();
        expect(true, false);
      } on PostgreSQLException catch (e) {
        expect(e.message, contains("password authentication failed"));
      }

      await expectConnectionIsInvalid(conn);
    });

    test("A query error maintains connectivity, allows future queries", () async {

    });

    test("A query error maintains connectivity, continues processing pending queries", () async {

    });
  });

  group("Network error situations", () {
    test("Socket fails to connect reports error, disables connection for future use", () async {
      var conn = new PostgreSQLConnection("localhost", 5431, "dart_test");

      try {
        await conn.open();
        expect(true, false);
      } on SocketException {}

      await expectConnectionIsInvalid(conn);
    });

    test("Pending queries during startup get appropriate error response if connection fails", () async {

    });

    test("Connection lost while pending queries exist gracefully errors out pending queries.", () async {

    });
  });
}

Future expectConnectionIsInvalid(PostgreSQLConnection conn) async {
  try {
    await conn.execute("select 1");
    expect(true, false);
  } on PostgreSQLException catch (e) {
    expect(e.message, contains("connection is not open"));
  }

  try {
    await conn.open();
    expect(true, false);
  } on PostgreSQLException catch (e) {
    expect(e.message, contains("Attempting to reopen a closed connection"));
  }
}