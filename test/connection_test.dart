import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test("Connect with md5 auth required", () async {
    var conn = new PostgreSQLConnection("localhost", 5432, "dart_test", username: "dart", password: "dart");

    await conn.open();
  });

  test("Connect with no auth required", () async {
    var conn = new PostgreSQLConnection("localhost", 5432, "joeconway", username: "joeconway");
    await conn.open();

    await conn.execute("select 1");
  });
}