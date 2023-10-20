import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import '../../messages.dart';
import '../../postgres.dart';
import 'connection.dart';
import 'execution_context.dart';

mixin _DelegatingContext implements PostgreSQLExecutionContext {
  Session? get _session;

  @override
  void cancelTransaction({String? reason}) {
    if (_session is Connection) {
      return;
    }
    throw _CancelTx();
  }

  @override
  Future<int> execute(String fmtString,
      {Map<String, dynamic>? substitutionValues, int? timeoutInSeconds}) async {
    if (_session case final Session session) {
      final rs = await session.execute(
        Sql.named(fmtString),
        parameters: substitutionValues,
        ignoreRows: true,
      );
      return rs.affectedRows;
    } else {
      throw PgServerException(
          'Attempting to execute query, but connection is not open.');
    }
  }

  @override
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(
      String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds}) async {
    throw UnimplementedError('table name is not resolved in v3');
  }

  @override
  Future<_PostgreSQLResult> query(String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds,
      bool? useSimpleQueryProtocol}) async {
    if (_session case final Session session) {
      final rs = await session.execute(
        Sql.named(fmtString),
        parameters: substitutionValues,
        queryMode: (useSimpleQueryProtocol ?? false) ? QueryMode.simple : null,
        timeout: timeoutInSeconds == null
            ? null
            : Duration(seconds: timeoutInSeconds),
      );
      return _PostgreSQLResult(rs, rs.map((e) => _PostgreSQLResultRow(e, e)));
    } else {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }
  }

  @override
  int get queueSize => throw UnimplementedError();
}

class WrappedPostgreSQLConnection
    with _DelegatingContext
    implements PostgreSQLConnection {
  final Endpoint _endpoint;
  final SessionSettings _sessionSettings;
  Connection? _connection;
  bool _hasConnectedPreviously = false;

  WrappedPostgreSQLConnection(this._endpoint, this._sessionSettings);

  @override
  Session? get _session => _connection;

  @override
  void addMessage(ClientMessage message) {
    throw UnimplementedError();
  }

  @override
  bool get allowClearTextPassword => throw UnimplementedError();

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
  Stream<ServerMessage> get messages => throw UnimplementedError();

  @override
  Stream<Notification> get notifications => _connection!.channels.all;

  @override
  Future open() async {
    if (_hasConnectedPreviously) {
      throw PostgreSQLException(
          'Attempting to reopen a closed connection. Create a instance instead.');
    }

    _hasConnectedPreviously = true;
    _connection = await Connection.open(
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
    Future Function(PostgreSQLExecutionContext connection) queryBlock, {
    int? commitTimeoutInSeconds,
  }) async {
    if (_connection case final Connection conn) {
      try {
        return await conn.runTx((session) async {
          return await queryBlock(_PostgreSQLExecutionContext(session));
        });
      } on _CancelTx catch (_) {
        return PostgreSQLRollback('');
      }
    } else {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }
  }

  @override
  bool get useSSL => throw UnimplementedError();

  @override
  String? get username => throw UnimplementedError();
}

class _CancelTx implements Exception {}

class _PostgreSQLResult extends UnmodifiableListView<PostgreSQLResultRow>
    implements PostgreSQLResult {
  final Result _result;
  _PostgreSQLResult(this._result, super.source);

  @override
  int get affectedRowCount => _result.affectedRows;

  @override
  late final columnDescriptions = _result.schema.columns
      .map((e) => _ColumnDescription(
            typeId: e.type.oid ?? 0,
            columnName: e.columnName ?? '',
          ))
      .toList();
}

class _PostgreSQLResultRow extends UnmodifiableListView
    implements PostgreSQLResultRow {
  final ResultRow _row;
  _PostgreSQLResultRow(this._row, super.source);

  @override
  late final columnDescriptions = _row.schema.columns
      .map((e) => _ColumnDescription(
            typeId: e.type.oid ?? 0,
            columnName: e.columnName ?? '',
          ))
      .toList();

  @override
  Map<String, dynamic> toColumnMap() => _row.toColumnMap();

  @override
  Map<String, Map<String, dynamic>> toTableColumnMap() {
    throw UnimplementedError('table name is not resolved in v3');
  }
}

class _PostgreSQLExecutionContext
    with _DelegatingContext
    implements PostgreSQLExecutionContext {
  @override
  final Session _session;

  _PostgreSQLExecutionContext(this._session);
}

class _ColumnDescription implements ColumnDescription {
  @override
  final String columnName;

  @override
  String get tableName =>
      throw UnimplementedError('table name is not resolved in v3');

  @override
  final int typeId;

  _ColumnDescription({
    required this.columnName,
    required this.typeId,
  });
}
