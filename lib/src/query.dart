import 'dart:async';
import 'postgresql_codec.dart';
import 'connection.dart';
import 'dart:io';
import 'substituter.dart';
import 'client_messages.dart';
import 'dart:typed_data';
import 'dart:convert';

class Query<T> {
  Query(this.statement, this.substitutionValues, this.connection,
      this.transaction);

  bool onlyReturnAffectedRowCount = false;
  String statementIdentifier;
  Completer<dynamic> _onComplete = new Completer.sync();

  Future<T> get future => _onComplete.future;

  final String statement;
  final Map<String, dynamic> substitutionValues;
  final PostgreSQLExecutionContext transaction;
  final PostgreSQLConnection connection;

  List<int> specifiedParameterTypeCodes;

  List<FieldDescription> _fieldDescriptions;
  List<FieldDescription> get fieldDescriptions => _fieldDescriptions;

  void set fieldDescriptions(List<FieldDescription> fds) {
    _fieldDescriptions = fds;
    cache?.fieldDescriptions = fds;
  }

  List<Iterable<dynamic>> rows = [];

  QueryCache cache;

  void sendSimple(Socket socket) {
    var sqlString = PostgreSQLFormat.substitute(statement, substitutionValues);
    var queryMessage = new QueryMessage(sqlString);

    socket.add(queryMessage.asBytes());
  }

  void sendExtended(Socket socket, {QueryCache cacheQuery: null}) {
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

    specifiedParameterTypeCodes =
        formatIdentifiers.map((i) => i.typeCode).toList();

    var parameterList = formatIdentifiers
        .map((id) => encodeParameter(id, substitutionValues))
        .toList();

    var messages = [
      new ParseMessage(sqlString, statementName: statementName),
      new DescribeMessage(statementName: statementName),
      new BindMessage(parameterList, statementName: statementName),
      new ExecuteMessage(),
      new SyncMessage()
    ];

    if (statementIdentifier != null) {
      cache = new QueryCache(statementIdentifier, formatIdentifiers);
    }

    socket.add(ClientMessage.aggregateBytes(messages));
  }

  void sendCachedQuery(Socket socket, QueryCache cacheQuery,
      Map<String, dynamic> substitutionValues) {
    var statementName = cacheQuery.preparedStatementName;
    var parameterList = cacheQuery.orderedParameters
        .map((identifier) => encodeParameter(identifier, substitutionValues))
        .toList();

    var bytes = ClientMessage.aggregateBytes([
      new BindMessage(parameterList, statementName: statementName),
      new ExecuteMessage(),
      new SyncMessage()
    ]);

    socket.add(bytes);
  }

  ParameterValue encodeParameter(PostgreSQLFormatIdentifier identifier,
      Map<String, dynamic> substitutionValues) {
    if (identifier.typeCode != null) {
      return new ParameterValue.binary(
          substitutionValues[identifier.name], identifier.typeCode);
    } else {
      return new ParameterValue.text(substitutionValues[identifier.name]);
    }
  }

  PostgreSQLException validateParameters(List<int> parameterTypeIDs) {
    var actualParameterTypeCodeIterator = parameterTypeIDs.iterator;
    var parametersAreMismatched =
        specifiedParameterTypeCodes.map((specifiedTypeCode) {
      actualParameterTypeCodeIterator.moveNext();
      return actualParameterTypeCodeIterator.current ==
          (specifiedTypeCode ?? actualParameterTypeCodeIterator.current);
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

      return PostgreSQLCodec.decodeValue(bd, iterator.current.typeID);
    });

    rows.add(lazyDecodedData);
  }

  void complete(int rowsAffected) {
    if (onlyReturnAffectedRowCount) {
      _onComplete.complete(rowsAffected);
      return;
    }

    _onComplete.complete(rows.map((row) => row.toList()).toList());
  }

  void completeError(dynamic error) {
    _onComplete.completeError(error);
  }

  String toString() => statement;
}

class QueryCache {
  QueryCache(this.preparedStatementName, this.orderedParameters);

  String preparedStatementName;
  List<PostgreSQLFormatIdentifier> orderedParameters;
  List<FieldDescription> fieldDescriptions;

  bool get isValid {
    return preparedStatementName != null &&
        orderedParameters != null &&
        fieldDescriptions != null;
  }
}

class ParameterValue {
  ParameterValue.binary(dynamic value, this.postgresType) {
    isBinary = true;
    bytes = PostgreSQLCodec
        .encodeBinary(value, this.postgresType)
        ?.buffer
        ?.asUint8List();
    length = bytes?.length ?? 0;
  }

  ParameterValue.text(dynamic value) {
    isBinary = false;
    if (value != null) {
      bytes = UTF8.encode(PostgreSQLCodec.encode(value, escapeStrings: false));
    }
    length = bytes?.length;
  }

  bool isBinary;
  int postgresType;
  Uint8List bytes;
  int length;
}

class FieldDescription {
  String fieldName;
  int tableID;
  int columnID;
  int typeID;
  int dataTypeSize;
  int typeModifier;
  int formatCode;

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

    return offset;
  }

  String toString() {
    return "$fieldName $tableID $columnID $typeID $dataTypeSize $typeModifier $formatCode";
  }
}

typedef String SQLReplaceIdentifierFunction(
    PostgreSQLFormatIdentifier identifier, int index);

enum PostgreSQLFormatTokenType { text, marker }

class PostgreSQLFormatToken {
  PostgreSQLFormatToken(this.type);

  PostgreSQLFormatTokenType type;
  StringBuffer buffer = new StringBuffer();
}

class PostgreSQLFormatIdentifier {
  static Map<String, int> typeStringToCodeMap = {
    "text": PostgreSQLCodec.TypeText,
    "int2": PostgreSQLCodec.TypeInt2,
    "int4": PostgreSQLCodec.TypeInt4,
    "int8": PostgreSQLCodec.TypeInt8,
    "float4": PostgreSQLCodec.TypeFloat4,
    "float8": PostgreSQLCodec.TypeFloat8,
    "boolean": PostgreSQLCodec.TypeBool,
    "date": PostgreSQLCodec.TypeDate,
    "timestamp": PostgreSQLCodec.TypeTimestamp,
    "timestamptz": PostgreSQLCodec.TypeTimestampTZ
  };

  static int postgresCodeForDataTypeString(String dt) {
    return typeStringToCodeMap[dt];
  }

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
        typeCode = postgresCodeForDataTypeString(dataTypeString);
      }
    } else {
      throw new FormatException(
          "Invalid format string identifier, must contain identifier name and optionally one data type in format '@identifier:dataType' (offending identifier: ${t})");
    }

    // Strip @
    name = name.substring(1, name.length);
  }

  String name;
  int typeCode;
  String typeCast;
}
