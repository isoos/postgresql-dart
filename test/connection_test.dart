import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'dart:async';
import 'dart:mirrors';

void main() {
  group("Normal behavior", () {

    test("Connect with md5 auth required", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");
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
    });

    test("Issuing multiple queries without awaiting are returned in order", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();
    });


    test("Closing idle connection succeeds, closes underlying socket", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      await conn.close();

      var socketMirror = reflect(conn).type.declarations.values.firstWhere((DeclarationMirror dm) => dm.simpleName.toString().contains("_socket"));
      Socket underlyingSocket = reflect(conn).getField(socketMirror.simpleName).reflectee;
      expect(await underlyingSocket.done, isNotNull);
    });

    test("Closing connection while busy succeeds, queued queries are all accounted for, closes underlying socket", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      await conn.open();

      var futureValue = conn.execute("select 1");
      await conn.close();

      var value = await futureValue;
      expect(value, 1);

      var socketMirror = reflect(conn).type.declarations.values.firstWhere((DeclarationMirror dm) => dm.simpleName.toString().contains("_socket"));
      Socket underlyingSocket = reflect(conn).getField(socketMirror.simpleName).reflectee;
      expect(await underlyingSocket.done, isNotNull);
    });

  });

  group("Unintended user-error situations", () {
    test("Sending queries to opening connection triggers error", () async {
      var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "darttrust");
      conn.open();

      try {
        conn.execute("select 1");
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
    expect(e.message, contains("connection has already closed"));
  }

  try {
    await conn.open();
    expect(true, false);
  } on PostgreSQLException catch (e) {
    expect(e.message, contains("Attempting to reopen a closed connection"));
  }
}