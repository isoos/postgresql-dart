import 'dart:collection';
import 'dart:convert';

import 'dart:io';

import 'package:postgres/postgres_v3_experimental.dart';
import 'package:postgres/src/client_messages.dart';
import 'package:postgres/src/connection.dart';
import 'package:postgres/src/execution_context.dart';
import 'package:postgres/src/replication.dart';
import 'package:postgres/src/server_messages.dart';

mixin _DelegatingContext implements PostgreSQLExecutionContext {
  PgSession? get _session;

  @override
  void cancelTransaction({String? reason}) {
    throw UnimplementedError();
  }

  @override
  Future<int> execute(String fmtString,
      {Map<String, dynamic>? substitutionValues, int? timeoutInSeconds}) async {
    if (_session case final PgSession session) {
      final rs = await session.execute(
        PgSql.map(fmtString),
        parameters: substitutionValues,
        ignoreRows: true,
      );
      return rs.affectedRows;
    } else {
      throw PostgreSQLException(
          'Attempting to execute query, but connection is not open.');
    }
  }

  @override
  Future<List<Map<String, Map<String, dynamic>>>> mappedResultsQuery(
      String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds}) async {
    final rs = await query(
      fmtString,
      substitutionValues: substitutionValues,
      allowReuse: allowReuse ?? false,
      timeoutInSeconds: timeoutInSeconds,
    );

    // Load table names which are not returned by Postgres reliably. The v2
    // implementation used to do this with its own cache, the v3 API doesn't do
    // it at all and defers that logic to the user.
    final raw = rs._result;
    final tableOids = raw.schema.columns
        .map((c) => c.tableOid)
        .where((id) => id != null && id > 0)
        .toList()
      ..sort();

    if (tableOids.isEmpty) {
      return rs.map((row) => row.toTableColumnMap()).toList();
    }

    final oidToName = <int, String>{};
    final oidResults = await query(
      "SELECT oid::int8, relname FROM pg_class WHERE relkind='r' AND oid = ANY(@ids:_int8::oid[])",
      substitutionValues: {'ids': tableOids},
    );
    for (final row in oidResults) {
      oidToName[row[0]] = row[1];
    }

    final results = <Map<String, Map<String, dynamic>>>[];
    for (final row in raw) {
      final tables = <String, Map<String, dynamic>>{};

      for (final (i, col) in row.schema.columns.indexed) {
        final tableName = oidToName[col.tableOid];
        final columnName = col.columnName;

        if (tableName != null && columnName != null) {
          tables.putIfAbsent(tableName, () => {})[columnName] = row[i];
        }
      }

      results.add(tables);
    }

    return results;
  }

  @override
  Future<_PostgreSQLResult> query(String fmtString,
      {Map<String, dynamic>? substitutionValues,
      bool? allowReuse,
      int? timeoutInSeconds,
      bool? useSimpleQueryProtocol}) async {
    if (_session case final PgSession session) {
      final rs = await session.execute(
        PgSql.map(fmtString),
        parameters: substitutionValues,
        queryMode: (useSimpleQueryProtocol ?? false) ? QueryMode.simple : null,
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

class V3BackedPostgreSQLConnection
    with _DelegatingContext
    implements PostgreSQLConnection {
  final PgEndpoint _endpoint;
  final PgSessionSettings _sessionSettings;
  PgConnection? _connection;
  bool _hasConnectedPreviously = false;

  V3BackedPostgreSQLConnection(this._endpoint, this._sessionSettings);

  @override
  PgSession? get _session => _connection;

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
  Stream<Notification> get notifications =>
      _connection!.channels.all.map((event) {
        return Notification(event.processId, event.channel, event.payload);
      });

  @override
  Future open() async {
    if (_hasConnectedPreviously) {
      throw PostgreSQLException(
          'Attempting to reopen a closed connection. Create a instance instead.');
    }

    _hasConnectedPreviously = true;
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
    if (_connection case final PgConnection conn) {
      return await conn.runTx((session) async {
        return await queryBlock(_PostgreSQLExecutionContext(session));
      });
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
    final map = <String, dynamic>{};
    for (final (i, col) in _row.schema.columns.indexed) {
      if (col.columnName case final String name) {
        map[name] = _row[i];
      }
    }

    return map;
  }

  @override
  Map<String, Map<String, dynamic>> toTableColumnMap() {
    final tables = <String, Map<String, dynamic>>{};

    for (final (i, col) in _row.schema.columns.indexed) {
      final tableName = col.tableName;
      final columnName = col.columnName;

      if (tableName != null && columnName != null) {
        tables.putIfAbsent(tableName, () => {})[columnName] = _row[i];
      }
    }

    return tables;
  }
}

class _PostgreSQLExecutionContext
    with _DelegatingContext
    implements PostgreSQLExecutionContext {
  @override
  final PgSession _session;

  _PostgreSQLExecutionContext(this._session);
}
