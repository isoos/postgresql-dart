import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'binary_codec.dart';
import 'client_messages.dart';
import 'connection.dart';
import 'execution_context.dart';
import 'placeholder_identifier_enum.dart';
import 'substituter.dart';
import 'substituter2.dart';
import 'text_codec.dart';
import 'types.dart';

class Query<T> {
  Query(
    this.statement,
    this.substitutionValues,
    this.connection,
    this.transaction,
    this.queryStackTrace, {
    required this.placeholderIdentifier,
    this.onlyReturnAffectedRowCount = false,
    this.useSendSimple = false,
  });

  final PlaceholderIdentifier placeholderIdentifier;

  final bool onlyReturnAffectedRowCount;

  final bool useSendSimple;

  String? statementIdentifier;

  Future<QueryResult<T>?> get future => _onComplete.future;

  final String statement;

  /// Map<String, dynamic> | List<dynamic>
  dynamic substitutionValues;
  final PostgreSQLExecutionContext transaction;
  final PostgreSQLConnection connection;

  late List<PostgreSQLDataType?> _specifiedParameterTypeCodes;
  final rows = <List<dynamic>>[];

  CachedQuery? cache;

  final _onComplete = Completer<QueryResult<T>?>.sync();
  List<FieldDescription>? _fieldDescriptions;

  List<FieldDescription>? get fieldDescriptions => _fieldDescriptions;

  final StackTrace queryStackTrace;

  set fieldDescriptions(List<FieldDescription>? fds) {
    _fieldDescriptions = fds;
    cache?.fieldDescriptions = fds;
  }

  void sendSimple(Socket socket) {
    // final sqlString = PostgreSQLFormat.substitute(
    //     statement, substitutionValues as Map<String, dynamic>?);
    final sqlString = _formatSql([], [], isSimple: true);
    final queryMessage = QueryMessage(sqlString, connection.encoding);
    socket.add(queryMessage.asBytes());
  }

  /// prepare replacement values for placeholders only when identifier is question mark
  /// [cb] callback for each prepared parameter
  void _prepareSubstitutionValues(
      {void Function(Map<String, dynamic> params, String key)? cb}) {
    final params = <String, dynamic>{};
    if (substitutionValues is List) {
      for (var i = 0; i < (substitutionValues.length as int); i++) {
        final key = 'param$i';
        params[key] = substitutionValues[i];

        if (cb != null) {
          cb(params, key);
        }
      }
      substitutionValues = params;
    }
  }

  /// format SQL to run
  String _formatSql(List<PostgreSQLFormatIdentifier> formatIdentifiers,
      List<ParameterValue> parameterList,
      {bool isSimple = false}) {
    switch (placeholderIdentifier) {
      case PlaceholderIdentifier.atSign:
        final sqlString = PostgreSQLFormat.substitute(
            statement, substitutionValues as Map<String, dynamic>?,
            replace: isSimple
                ? null
                : (PostgreSQLFormatIdentifier identifier, int index) {
                    formatIdentifiers.add(identifier);
                    return '\$$index';
                  });

        for (var id in formatIdentifiers) {
          parameterList.add(ParameterValue(
              id,
              substitutionValues as Map<String, dynamic>?,
              connection.encoding));
        }

        return sqlString;

      case PlaceholderIdentifier.onlyQuestionMark:
        _prepareSubstitutionValues(cb: (map, key) {
          final identifier = PostgreSQLFormatIdentifier('@$key');
          formatIdentifiers.add(identifier);
          parameterList
              .add(ParameterValue(identifier, map, connection.encoding));
        });
        return toStatement2(statement);

      // case PlaceholderIdentifier.colon:
      //   return toStatement(statement, substitutionValues as Map<String, dynamic>);

      default:
        throw PostgreSQLException(
            'placeholderIdentifier unknown or not implemented');
    }
  }

  void sendExtended(Socket socket, {CachedQuery? cacheQuery}) {
    if (cacheQuery != null) {
      if (placeholderIdentifier == PlaceholderIdentifier.onlyQuestionMark) {
        _prepareSubstitutionValues();
      }

      fieldDescriptions = cacheQuery.fieldDescriptions!;
      sendCachedQuery(
          socket, cacheQuery, substitutionValues as Map<String, dynamic>?);
      return;
    }

    final statementName = statementIdentifier ?? '';

    final formatIdentifiers = <PostgreSQLFormatIdentifier>[];
    final parameterList = <ParameterValue>[];

    final sqlString = _formatSql(formatIdentifiers, parameterList);

    _specifiedParameterTypeCodes =
        formatIdentifiers.map((i) => i.type).toList();

    final messages = [
      ParseMessage(sqlString,
          statementName: statementName, encoding: connection.encoding),
      DescribeMessage(
          statementName: statementName, encoding: connection.encoding),
      BindMessage(parameterList,
          statementName: statementName, encoding: connection.encoding),
      ExecuteMessage(connection.encoding),
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
        .map((identifier) =>
            ParameterValue(identifier, substitutionValues, connection.encoding))
        .toList();

    final bytes = ClientMessage.aggregateBytes([
      BindMessage(parameterList,
          statementName: statementName!, encoding: connection.encoding),
      ExecuteMessage(connection.encoding),
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

    // Simple queries do not follow the same binary codecs. All values will be
    // returned as strings.
    //
    // For instance, a column can be defined as `int4` which is expected to be
    // 4 bytes long (i.e. decoded using bytes.getUint32) but when using simple
    // query (i.e. sendSimple), the value will be returned as a string.
    //
    // See Simple Query section in Protocol Message Flow:
    // "In simple Query mode, the format of retrieved values is always text"
    //  https://www.postgresql.org/docs/current/protocol-flow.html#id-1.10.5.7.4
    if (useSendSimple) {
      final data = rawRowData.map((e) => connection.encoding.decode(e!));
      rows.add(data.toList());
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

    _onComplete.completeError(error, stackTrace ?? queryStackTrace);
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
  /// [substitutionValues] = Map<String,dynamic> | List<Object?>
  factory ParameterValue(PostgreSQLFormatIdentifier identifier,
      Map<String, dynamic>? substitutionValues, Encoding encoding) {
    final value = substitutionValues?[identifier.name];

    if (identifier.type == null) {
      return ParameterValue.text(value, encoding);
    }

    return ParameterValue.binary(value, identifier.type!, encoding);
  }

  factory ParameterValue.binary(
      dynamic value, PostgreSQLDataType postgresType, Encoding encoding) {
    final bytes = postgresType.binaryCodec(encoding).encoder.convert(value);
    return ParameterValue._(true, bytes, bytes?.length ?? 0);
  }

  factory ParameterValue.text(dynamic value, Encoding encoding) {
    Uint8List? bytes;
    if (value != null) {
      const converter = PostgresTextEncoder();
      bytes = castBytes(
          encoding.encode(converter.convert(value, escapeStrings: false)));
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
  final Encoding encoding;

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
    this.encoding,
  );

  factory FieldDescription.read(ByteDataReader reader, Encoding encoding) {
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

    final converter = PostgresBinaryDecoder(typeOid, encoding);
    return FieldDescription._(
      converter, fieldName, tableID, columnID, typeOid,
      dataTypeSize, typeModifier, formatCode,
      '', // tableName
      encoding,
    );
  }

  FieldDescription change({String? tableName}) {
    return FieldDescription._(
        converter,
        columnName,
        tableID,
        columnID,
        typeId,
        dataTypeSize,
        typeModifier,
        formatCode,
        tableName ?? this.tableName,
        encoding);
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
    'interval': PostgreSQLDataType.interval,
    'numeric': PostgreSQLDataType.numeric,
    'jsonb': PostgreSQLDataType.jsonb,
    'bytea': PostgreSQLDataType.byteArray,
    'name': PostgreSQLDataType.name,
    'uuid': PostgreSQLDataType.uuid,
    'json': PostgreSQLDataType.json,
    'point': PostgreSQLDataType.point,
    '_bool': PostgreSQLDataType.booleanArray,
    '_int4': PostgreSQLDataType.integerArray,
    '_int8': PostgreSQLDataType.bigIntegerArray,
    '_text': PostgreSQLDataType.textArray,
    '_float8': PostgreSQLDataType.doubleArray,
    'varchar': PostgreSQLDataType.varChar,
    '_varchar': PostgreSQLDataType.varCharArray,
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
