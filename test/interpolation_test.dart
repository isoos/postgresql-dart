import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('Substitute 1', () {
    var result = PostgreSQLFormat.substitute('@id', {'id': 20});
    expect(result, equals('20'));
  });

  test('Substitute 2', () {
    var result = PostgreSQLFormat.substitute('@id ', {'id': 20});
    expect(result, equals('20 '));
  });

  test('Substitute 3', () {
    var result = PostgreSQLFormat.substitute(' @id ', {'id': 20});
    expect(result, equals(' 20 '));
  });

  test('Substitute 4', () {
    var result = PostgreSQLFormat.substitute('@id@bob', {'id': 20, 'bob': 13});
    expect(result, equals('2013'));
  });

  test('Substitute 5', () {
    var result = PostgreSQLFormat.substitute('..@id..', {'id': 20});
    expect(result, equals('..20..'));
  });

  test('Substitute 6', () {
    var result = PostgreSQLFormat.substitute('...@id...', {'id': 20});
    expect(result, equals('...20...'));
  });

  test('Substitute 7', () {
    var result = PostgreSQLFormat.substitute('...@id.@bob...', {'id': 20, 'bob': 13});
    expect(result, equals('...20.13...'));
  });

  test('Substitute 8', () {
    var result = PostgreSQLFormat.substitute('...@id@bob', {'id': 20, 'bob': 13});
    expect(result, equals('...2013'));
  });

  test('Substitute 9', () {
    var result = PostgreSQLFormat.substitute('@id@bob...', {'id': 20, 'bob': 13});
    expect(result, equals('2013...'));
  });

  test('Substitute 10', () {
    var result = PostgreSQLFormat.substitute('@id', {'id': "'foo'"});
    expect(result, equals(r"E'\'foo\''"));
  });

  test('Substitute 11', () {
    var result = PostgreSQLFormat.substitute('@blah_blah', {'blah_blah': 20});
    expect(result, equals("20"));
  });

  test('Substitute 12', () {
    var result = PostgreSQLFormat.substitute('@_blah_blah', {'_blah_blah': 20});
    expect(result, equals("20"));
  });
}