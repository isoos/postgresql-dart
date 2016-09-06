import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test("Simple replacement", () {
    var result = PostgreSQLFormat.substitute("@id", {"id" : 20});
    expect(result, equals("20"));
  });

  test("Trailing/leading space", () {
    var result = PostgreSQLFormat.substitute(" @id ", {"id" : 20});
    expect(result, equals(" 20 "));
  });

  test("Two identifiers next to eachother", () {
    var result = PostgreSQLFormat.substitute("@id@bob", {"id" : 20, "bob" : 13});
    expect(result, equals("2013"));
  });

  test("Identifier with underscores", () {
    var result = PostgreSQLFormat.substitute("@_one_two", {"_one_two" : 12});
    expect(result, equals("12"));
  });

  test("Identifier with type info", () {
    var result = PostgreSQLFormat.substitute("@id:int2", {"id" : 12});
    expect(result, equals("12"));
  });

  test("Identifiers next to eachother with type info", () {
    var result = PostgreSQLFormat.substitute("@id:int2@foo:float4", {"id" : 12, "foo" : 2.0});
    expect(result, equals("122.0"));
  });

  test("String identifiers get escaped", () {
    var result = PostgreSQLFormat.substitute("@id:text @foo", {"id" : "1';2", "foo" : r"3\4"});
    expect(result, r"E'1\';2' E'3\\4'");
  });

  test("String identifiers get escaped, 2", () {
    var result = PostgreSQLFormat.substitute("@id:text @foo", {"id" : "\\'", "foo" : r"3\4"});
    expect(result, r" E'\\'''  E'3\\4'");
  });
}