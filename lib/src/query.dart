import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'binary_codec.dart';
import 'client_messages.dart';
import 'connection.dart';
import 'execution_context.dart';
import 'substituter.dart';
import 'text_codec.dart';
import 'types.dart';

class Query<T> {
  Query(
    this.statement,
    this.substitutionValues,
    this.connection,
    this.transaction, {
    this.onlyReturnAffectedRowCount = false,
  });

  final bool onlyReturnAffectedRowCount;

  String? statementIdentifier;

  Future<QueryResult<T>?> get future => _onComplete.future;

  final String statement;
  final Map<String, dynamic>? substitutionValues;
  final PostgreSQLExecutionContext transaction;
  final PostgreSQLConnection connection;

  late List<PostgreSQLDataType?> _specifiedParameterTypeCodes;
  final rows = <List<dynamic>>[];

  CachedQuery? cache;

  final _onComplete = Completer<QueryResult<T>?>.sync();
  List<FieldDescription>? _fieldDescriptions;

  List<FieldDescription>? get fieldDescriptions => _fieldDescriptions;

  set fieldDescriptions(List<FieldDescription>? fds) {
    _fieldDescriptions = fds;
    cache?.fieldDescriptions = fds;
  }

  void sendSimple(Socket socket) {
    final sqlString =
        PostgreSQLFormat.substitute(statement, substitutionValues);
    final queryMessage = QueryMessage(sqlString);

    socket.add(queryMessage.asBytes());
  }

  void sendExtended(Socket socket, {CachedQuery? cacheQuery}) {
    if (cacheQuery != null) {
      fieldDescriptions = cacheQuery.fieldDescriptions!;
      sendCachedQuery(socket, cacheQuery, substitutionValues);

      return;
    }

    final statementName = statementIdentifier ?? '';
    final formatIdentifiers = <PostgreSQLFormatIdentifier>[];
    final sqlString = PostgreSQLFormat.substitute(statement, substitutionValues,
        replace: (PostgreSQLFormatIdentifier identifier, int index) {
      formatIdentifiers.add(identifier);

      return '\$$index';
    });

    _specifiedParameterTypeCodes =
        formatIdentifiers.map((i) => i.type).toList();

    final parameterList = formatIdentifiers
        .map((id) => ParameterValue(id, substitutionValues))
        .toList();

    final messages = [
      ParseMessage(sqlString, statementName: statementName),
      DescribeMessage(statementName: statementName),
      BindMessage(parameterList, statementName: statementName),
      ExecuteMessage(),
      SyncMessage(),
    ];

    if (statementIdentifier != null) {
      cache = CachedQuery(statementIdentifier!, formatIdentifiers);
    }

    socket.add(ClientMessage.aggregateBytes(messages));
  }

  void sendCachedQuery(Socket socket, CachedQuery cacheQuery,
      Map<String, dynamic>? substitutionValues) {
    final statementName = cacheQuery.preparedStatementName;
    final parameterList = cacheQuery.orderedParameters!
        .map((identifier) => ParameterValue(identifier, substitutionValues))
        .toList();

    final bytes = ClientMessage.aggregateBytes([
      BindMessage(parameterList, statementName: statementName!),
      ExecuteMessage(),
      SyncMessage()
    ]);

    socket.add(bytes);
  }

  PostgreSQLException? validateParameters(List<int> parameterTypeIDs) {
    final actualParameterTypeCodeIterator = parameterTypeIDs.iterator;
    final parametersAreMismatched =
        _specifiedParameterTypeCodes.map((specifiedType) {
      actualParameterTypeCodeIterator.moveNext();

      if (specifiedType == null) {
        return true;
      }

      final actualType = PostgresBinaryDecoder
          .typeMap[actualParameterTypeCodeIterator.current];
      return actualType == specifiedType;
    }).any((v) => v == false);

    if (parametersAreMismatched) {
      return PostgreSQLException(
          'Specified parameter types do not match column parameter types in query $statement');
    }

    return null;
  }

  void addRow(List<Uint8List?> rawRowData) {
    if (onlyReturnAffectedRowCount || fieldDescriptions == null) {
      return;
    }

    final iterator = fieldDescriptions!.iterator;
    final lazyDecodedData = rawRowData.map((bd) {
      iterator.moveNext();
      return iterator.current.converter.convert(bd);
    });

    rows.add(lazyDecodedData.toList());
  }

  void complete(int rowsAffected) {
    if (_onComplete.isCompleted) {
      return;
    }

    if (onlyReturnAffectedRowCount) {
      _onComplete.complete(QueryResult(rowsAffected, null));
      return;
    }

    _onComplete.complete(QueryResult(rowsAffected, rows as T));
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    if (_onComplete.isCompleted) {
      return;
    }

    _onComplete.completeError(error, stackTrace);
  }

  @override
  String toString() => statement;
}

class QueryResult<T> {
  final int affectedRowCount;
  final T? value;

  const QueryResult(this.affectedRowCount, this.value);
}

class CachedQuery {
  CachedQuery(this.preparedStatementName, this.orderedParameters);

  final String? preparedStatementName;
  final List<PostgreSQLFormatIdentifier>? orderedParameters;
  List<FieldDescription>? fieldDescriptions;

  bool get isValid {
    return preparedStatementName != null &&
        orderedParameters != null &&
        fieldDescriptions != null;
  }
}

class ParameterValue {
  factory ParameterValue(PostgreSQLFormatIdentifier identifier,
      Map<String, dynamic>? substitutionValues) {
    if (identifier.type == null) {
      return ParameterValue.text(substitutionValues?[identifier.name]);
    }

    return ParameterValue.binary(
        substitutionValues?[identifier.name], identifier.type!);
  }

  factory ParameterValue.binary(
      dynamic value, PostgreSQLDataType postgresType) {
    final converter = PostgresBinaryEncoder(postgresType);
    final bytes = converter.convert(value);
    final length = bytes?.length ?? 0;
    return ParameterValue._(true, bytes, length);
  }

  factory ParameterValue.text(dynamic value) {
    Uint8List? bytes;
    if (value != null) {
      final converter = PostgresTextEncoder();
      bytes = castBytes(
          utf8.encode(converter.convert(value, escapeStrings: false)));
    }
    final length = bytes?.length ?? 0;
    return ParameterValue._(false, bytes, length);
  }

  ParameterValue._(this.isBinary, this.bytes, this.length);

  final bool isBinary;
  final Uint8List? bytes;
  final int length;
}

class FieldDescription implements ColumnDescription {
  final Converter converter;

  @override
  final String columnName;
  final int tableID;
  final int columnID;
  @override
  final int typeId;
  final int dataTypeSize;
  final int typeModifier;
  final int formatCode;

  @override
  final String tableName;

  FieldDescription._(
    this.converter,
    this.columnName,
    this.tableID,
    this.columnID,
    this.typeId,
    this.dataTypeSize,
    this.typeModifier,
    this.formatCode,
    this.tableName,
  );

  factory FieldDescription.read(ByteDataReader reader) {
    final buf = StringBuffer();
    var byte = 0;
    do {
      byte = reader.readUint8();
      if (byte != 0) {
        buf.writeCharCode(byte);
      }
    } while (byte != 0);

    final fieldName = buf.toString();

    final tableID = reader.readUint32();
    final columnID = reader.readUint16();
    final typeOid = reader.readUint32();
    final dataTypeSize = reader.readUint16();
    final typeModifier = reader.readInt32();
    final formatCode = reader.readUint16();

    final converter = PostgresBinaryDecoder(typeOid);
    return FieldDescription._(
      converter, fieldName, tableID, columnID, typeOid,
      dataTypeSize, typeModifier, formatCode,
      '', // tableName
    );
  }

  FieldDescription change({String? tableName}) {
    return FieldDescription._(converter, columnName, tableID, columnID, typeId,
        dataTypeSize, typeModifier, formatCode, tableName ?? this.tableName);
  }

  @override
  String toString() {
    return '$columnName $tableID $columnID $typeId $dataTypeSize $typeModifier $formatCode';
  }
}

typedef SQLReplaceIdentifierFunction = String Function(
    PostgreSQLFormatIdentifier identifier, int index);

enum PostgreSQLFormatTokenType { text, variable }

class PostgreSQLFormatToken {
  PostgreSQLFormatToken(this.type);

  PostgreSQLFormatTokenType type;
  StringBuffer buffer = StringBuffer();
}

class PostgreSQLFormatIdentifier {
  static Map<String, PostgreSQLDataType> typeStringToCodeMap = {
    'text': PostgreSQLDataType.text,
    'int2': PostgreSQLDataType.smallInteger,
    'int4': PostgreSQLDataType.integer,
    'int8': PostgreSQLDataType.bigInteger,
    'float4': PostgreSQLDataType.real,
    'float8': PostgreSQLDataType.double,
    'boolean': PostgreSQLDataType.boolean,
    'date': PostgreSQLDataType.date,
    'timestamp': PostgreSQLDataType.timestampWithoutTimezone,
    'timestamptz': PostgreSQLDataType.timestampWithTimezone,
    'jsonb': PostgreSQLDataType.jsonb,
    'bytea': PostgreSQLDataType.byteArray,
    'name': PostgreSQLDataType.name,
    'uuid': PostgreSQLDataType.uuid,
    'json': PostgreSQLDataType.json,
    'point': PostgreSQLDataType.point,
    '_int4': PostgreSQLDataType.integerArray,
    '_text': PostgreSQLDataType.textArray,
    '_float8': PostgreSQLDataType.doubleArray,
    'varchar': PostgreSQLDataType.varChar,
    '_jsonb': PostgreSQLDataType.jsonbArray,
  };

  factory PostgreSQLFormatIdentifier(String t) {
    String name;
    PostgreSQLDataType? type;
    String? typeCast;

    final components = t.split('::');
    if (components.length > 1) {
      typeCast = components.sublist(1).join('');
    }

    final variableComponents = components.first.split(':');
    if (variableComponents.length == 1) {
      name = variableComponents.first;
    } else if (variableComponents.length == 2) {
      name = variableComponents.first;

      final dataTypeString = variableComponents.last;
      try {
        type = typeStringToCodeMap[dataTypeString]!;
      } catch (e) {
        throw FormatException(
            "Invalid type code in substitution variable '$t'");
      }
    } else {
      throw FormatException(
          "Invalid format string identifier, must contain identifier name and optionally one data type in format '@identifier:dataType' (offending identifier: $t)");
    }

    // Strip @
    name = name.substring(1, name.length);
    return PostgreSQLFormatIdentifier._(name, type, typeCast);
  }

  PostgreSQLFormatIdentifier._(this.name, this.type, this.typeCast);

  final String name;
  final PostgreSQLDataType? type;
  final String? typeCast;
}
