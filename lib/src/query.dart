import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:postgres/src/binary_codec.dart';
import 'package:postgres/src/execution_context.dart';

import 'package:postgres/src/text_codec.dart';
import 'types.dart';
import 'connection.dart';
import 'substituter.dart';
import 'client_messages.dart';

class Query<T> {
  Query(this.statement, this.substitutionValues, this.connection, this.transaction);

  bool onlyReturnAffectedRowCount = false;

  String statementIdentifier;

  Future<T> get future => _onComplete.future;

  final String statement;
  final Map<String, dynamic> substitutionValues;
  final PostgreSQLExecutionContext transaction;
  final PostgreSQLConnection connection;

  List<PostgreSQLDataType> specifiedParameterTypeCodes;
  List<List<dynamic>> rows = [];

  CachedQuery cache;

  Completer<T> _onComplete = new Completer.sync();
  List<FieldDescription> _fieldDescriptions;

  List<FieldDescription> get fieldDescriptions => _fieldDescriptions;

  void set fieldDescriptions(List<FieldDescription> fds) {
    _fieldDescriptions = fds;
    cache?.fieldDescriptions = fds;
  }

  void sendSimple(Socket socket) {
    var sqlString = PostgreSQLFormat.substitute(statement, substitutionValues);
    var queryMessage = new QueryMessage(sqlString);

    socket.add(queryMessage.asBytes());
  }

  void sendExtended(Socket socket, {CachedQuery cacheQuery: null}) {
    if (cacheQuery != null) {
      fieldDescriptions = cacheQuery.fieldDescriptions;
      sendCachedQuery(socket, cacheQuery, substitutionValues);

      return;
    }

    String statementName = (statementIdentifier ?? "");
    var formatIdentifiers = <PostgreSQLFormatIdentifier>[];
    var sqlString = PostgreSQLFormat.substitute(statement, substitutionValues,
        replace: (PostgreSQLFormatIdentifier identifier, int index) {
      formatIdentifiers.add(identifier);

      return "\$$index";
    });

    specifiedParameterTypeCodes = formatIdentifiers.map((i) => i.type).toList();

    var parameterList = formatIdentifiers.map((id) => new ParameterValue(id, substitutionValues)).toList();

    var messages = [
      new ParseMessage(sqlString, statementName: statementName),
      new DescribeMessage(statementName: statementName),
      new BindMessage(parameterList, statementName: statementName),
      new ExecuteMessage(),
      new SyncMessage()
    ];

    if (statementIdentifier != null) {
      cache = new CachedQuery(statementIdentifier, formatIdentifiers);
    }

    socket.add(ClientMessage.aggregateBytes(messages));
  }

  void sendCachedQuery(Socket socket, CachedQuery cacheQuery, Map<String, dynamic> substitutionValues) {
    var statementName = cacheQuery.preparedStatementName;
    var parameterList =
        cacheQuery.orderedParameters.map((identifier) => new ParameterValue(identifier, substitutionValues)).toList();

    var bytes = ClientMessage.aggregateBytes(
        [new BindMessage(parameterList, statementName: statementName), new ExecuteMessage(), new SyncMessage()]);

    socket.add(bytes);
  }

  PostgreSQLException validateParameters(List<int> parameterTypeIDs) {
    var actualParameterTypeCodeIterator = parameterTypeIDs.iterator;
    var parametersAreMismatched = specifiedParameterTypeCodes.map((specifiedType) {
      actualParameterTypeCodeIterator.moveNext();

      if (specifiedType == null) {
        return true;
      }

      final actualType = PostgresBinaryDecoder.typeMap[actualParameterTypeCodeIterator.current];
      return actualType == specifiedType;
    }).any((v) => v == false);

    if (parametersAreMismatched) {
      return new PostgreSQLException(
          "Specified parameter types do not match column parameter types in query ${statement}");
    }

    return null;
  }

  void addRow(List<ByteData> rawRowData) {
    if (onlyReturnAffectedRowCount) {
      return;
    }

    var iterator = fieldDescriptions.iterator;
    var lazyDecodedData = rawRowData.map((bd) {
      iterator.moveNext();

      return iterator.current.converter.convert(bd?.buffer?.asUint8List(bd.offsetInBytes, bd.lengthInBytes));
    });

    rows.add(lazyDecodedData.toList());
  }

  void complete(int rowsAffected) {
    if (_onComplete.isCompleted) {
      return;
    }

    if (onlyReturnAffectedRowCount) {
      _onComplete.complete(rowsAffected as T);
      return;
    }

    _onComplete.complete(rows as T);
  }

  void completeError(dynamic error, [StackTrace stackTrace]) {
    if (_onComplete.isCompleted) {
      return;
    }

    _onComplete.completeError(error, stackTrace);
  }

  String toString() => statement;
}

class CachedQuery {
  CachedQuery(this.preparedStatementName, this.orderedParameters);

  String preparedStatementName;
  List<PostgreSQLFormatIdentifier> orderedParameters;
  List<FieldDescription> fieldDescriptions;

  bool get isValid {
    return preparedStatementName != null && orderedParameters != null && fieldDescriptions != null;
  }
}

class ParameterValue {
  factory ParameterValue(PostgreSQLFormatIdentifier identifier, Map<String, dynamic> substitutionValues) {
    if (identifier.type == null) {
      return new ParameterValue.text(substitutionValues[identifier.name]);
    }

    return new ParameterValue.binary(substitutionValues[identifier.name], identifier.type);
  }

  ParameterValue.binary(dynamic value, PostgreSQLDataType postgresType) : isBinary = true {
    final converter = new PostgresBinaryEncoder(postgresType);
    bytes = converter.convert(value);
    length = bytes?.length ?? 0;
  }

  ParameterValue.text(dynamic value) : isBinary = false {
    if (value != null) {
      final converter = new PostgresTextEncoder(false);
      bytes = utf8.encode(converter.convert(value));
    }
    length = bytes?.length;
  }

  final bool isBinary;
  Uint8List bytes;
  int length;
}

class FieldDescription {
  Converter converter;

  String fieldName;
  int tableID;
  int columnID;
  int typeID;
  int dataTypeSize;
  int typeModifier;
  int formatCode;

  String resolvedTableName;

  int parse(ByteData byteData, int initialOffset) {
    var offset = initialOffset;
    var buf = new StringBuffer();
    var byte = 0;
    do {
      byte = byteData.getUint8(offset);
      offset += 1;
      if (byte != 0) {
        buf.writeCharCode(byte);
      }
    } while (byte != 0);

    fieldName = buf.toString();

    tableID = byteData.getUint32(offset);
    offset += 4;
    columnID = byteData.getUint16(offset);
    offset += 2;
    typeID = byteData.getUint32(offset);
    offset += 4;
    dataTypeSize = byteData.getUint16(offset);
    offset += 2;
    typeModifier = byteData.getInt32(offset);
    offset += 4;
    formatCode = byteData.getUint16(offset);
    offset += 2;

    converter = new PostgresBinaryDecoder(typeID);

    return offset;
  }

  String toString() {
    return "$fieldName $tableID $columnID $typeID $dataTypeSize $typeModifier $formatCode";
  }
}

typedef String SQLReplaceIdentifierFunction(PostgreSQLFormatIdentifier identifier, int index);

enum PostgreSQLFormatTokenType { text, variable }

class PostgreSQLFormatToken {
  PostgreSQLFormatToken(this.type);

  PostgreSQLFormatTokenType type;
  StringBuffer buffer = new StringBuffer();
}

class PostgreSQLFormatIdentifier {

  static Map<String, PostgreSQLDataType> typeStringToCodeMap = {
    "text": PostgreSQLDataType.text,
    "int2": PostgreSQLDataType.smallInteger,
    "int4": PostgreSQLDataType.integer,
    "int8": PostgreSQLDataType.bigInteger,
    "float4": PostgreSQLDataType.real,
    "float8": PostgreSQLDataType.double,
    "boolean": PostgreSQLDataType.boolean,
    "date": PostgreSQLDataType.date,
    "timestamp": PostgreSQLDataType.timestampWithoutTimezone,
    "timestamptz": PostgreSQLDataType.timestampWithTimezone,
    "jsonb": PostgreSQLDataType.json,
    "bytea": PostgreSQLDataType.byteArray,
    "name": PostgreSQLDataType.name,
    "uuid": PostgreSQLDataType.uuid
  };

  PostgreSQLFormatIdentifier(String t) {
    var components = t.split("::");
    if (components.length > 1) {
      typeCast = components.sublist(1).join("");
    }

    var variableComponents = components.first.split(":");
    if (variableComponents.length == 1) {
      name = variableComponents.first;
    } else if (variableComponents.length == 2) {
      name = variableComponents.first;

      var dataTypeString = variableComponents.last;
      if (dataTypeString != null) {
        type = typeStringToCodeMap[dataTypeString];
        if (type == null) {
          throw new FormatException("Invalid type code in substitution variable '$t'");
        }
      }
    } else {
      throw new FormatException(
          "Invalid format string identifier, must contain identifier name and optionally one data type in format '@identifier:dataType' (offending identifier: ${t})");
    }

    // Strip @
    name = name.substring(1, name.length);
  }

  String name;
  PostgreSQLDataType type;
  String typeCast;
}
