import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import 'package:postgres/postgres_v3_experimental.dart';
import 'package:postgres/src/client_messages.dart';
import 'package:postgres/src/connection.dart';
import 'package:postgres/src/execution_context.dart';
import 'package:postgres/src/replication.dart';
import 'package:postgres/src/server_messages.dart';

class V3BackedPostgreSQLConnection implements PostgreSQLConnection {
  final PgEndpoint _endpoint;
  final PgSessionSettings _sessionSettings;
  PgConnection? _connection;

  V3BackedPostgreSQLConnection(this._endpoint, this._sessionSettings);

  @override
  void addMessage(ClientMessage message) {
    throw UnimplementedError();
  }

  @override
  bool get allowClearTextPassword => throw UnimplementedError();

  @override
  void cancelTransaction({String? reason}) {
    throw UnimplementedError();
  }

  @override
  Future close() async {
    await _connection?.close();
    _connection = null;
  }

  @override
  String get databaseName => throw UnimplementedError();

  @override
  Encoding get encoding => throw UnimplementedError();

  @override
  String get host => throw UnimplementedError();

  @override
  bool get isClosed => throw UnimplementedError();

  @override
  bool get isUnixSocket => throw UnimplementedError();

  @override
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(
      String fmtString,
      {Map<String, dynamic>? substitutionValues = const {},
      bool? allowReuse,
      int? timeoutInSeconds}) {
    throw UnimplementedError();
  }

  @override
  Stream<ServerMessage> get messages => throw UnimplementedError();

  @override
  Stream<Notification> get notifications => throw UnimplementedError();

  @override
  Future open() async {
    _connection = await PgConnection.open(
      _endpoint,
      sessionSettings: _sessionSettings,
    );
  }

  @override
  String? get password => throw UnimplementedError();

  @override
  int get port => throw UnimplementedError();

  @override
  int get processID => throw UnimplementedError();

  @override
  Future<int> execute(
    String fmtString, {
    Map<String, dynamic>? substitutionValues = const {},
    int? timeoutInSeconds,
  }) async {
    final rs = await _connection!.execute(
      PgSql.map(fmtString),
      parameters: substitutionValues,
      ignoreRows: true,
    );
    return rs.affectedRows;
  }

  @override
  Future<PostgreSQLResult> query(
    String fmtString, {
    Map<String, dynamic>? substitutionValues,
    bool? allowReuse,
    int? timeoutInSeconds,
    bool? useSimpleQueryProtocol,
  }) async {
    final rs = await _connection!.execute(
      PgSql.map(fmtString),
      parameters: substitutionValues,
      queryMode: (useSimpleQueryProtocol ?? false) ? QueryMode.simple : null,
    );
    return _PostgreSQLResult(rs, rs.map((e) => _PostgreSQLResultRow(e, e)));
  }

  @override
  int get queryTimeoutInSeconds => throw UnimplementedError();

  @override
  int get queueSize => throw UnimplementedError();

  @override
  ReplicationMode get replicationMode => throw UnimplementedError();

  @override
  Map<String, String> get settings => throw UnimplementedError();

  @override
  Socket? get socket => throw UnimplementedError();

  @override
  String get timeZone => throw UnimplementedError();

  @override
  int get timeoutInSeconds => throw UnimplementedError();

  @override
  Future transaction(
      Future Function(PostgreSQLExecutionContext connection) queryBlock,
      {int? commitTimeoutInSeconds}) {
    throw UnimplementedError();
  }

  @override
  bool get useSSL => throw UnimplementedError();

  @override
  String? get username => throw UnimplementedError();
}

class _PostgreSQLResult extends UnmodifiableListView<PostgreSQLResultRow>
    implements PostgreSQLResult {
  final PgResult _result;
  _PostgreSQLResult(this._result, super.source);

  @override
  int get affectedRowCount => _result.affectedRows;

  @override
  late final columnDescriptions = _result.schema.columns
      .map((e) => _ColumnDescription(
            e.type.oid ?? 0,
            e.tableName ?? '',
            e.columnName ?? '',
          ))
      .toList();
}

class _ColumnDescription implements ColumnDescription {
  @override
  final int typeId;
  @override
  final String tableName;
  @override
  final String columnName;

  _ColumnDescription(
    this.typeId,
    this.tableName,
    this.columnName,
  );
}

class _PostgreSQLResultRow extends UnmodifiableListView
    implements PostgreSQLResultRow {
  final PgResultRow _row;
  _PostgreSQLResultRow(this._row, super.source);

  @override
  late final columnDescriptions = _row.schema.columns
      .map((e) => _ColumnDescription(
            e.type.oid ?? 0,
            e.tableName ?? '',
            e.columnName ?? '',
          ))
      .toList();

  @override
  Map<String, dynamic> toColumnMap() {
    throw UnimplementedError();
  }

  @override
  Map<String, Map<String, dynamic>> toTableColumnMap() {
    throw UnimplementedError();
  }
}
