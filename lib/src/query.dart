part of postgres;

class _Query<T> {
  _Query(this.statement, this.substitutionValues, this.connection,
      this.transaction);

  bool onlyReturnAffectedRowCount = false;
  String statementIdentifier;
  Completer<T> onComplete = new Completer.sync();

  Future<T> get future => onComplete.future;

  final String statement;
  final Map<String, dynamic> substitutionValues;
  final _TransactionProxy transaction;
  final PostgreSQLConnection connection;

  List<int> specifiedParameterTypeCodes;

  List<_FieldDescription> _fieldDescriptions;

  List<_FieldDescription> get fieldDescriptions => _fieldDescriptions;

  void set fieldDescriptions(List<_FieldDescription> fds) {
    _fieldDescriptions = fds;
    cache?.fieldDescriptions = fds;
  }

  List<Iterable<dynamic>> rows = [];

  _QueryCache cache;

  void sendSimple(Socket socket) {
    var sqlString = PostgreSQLFormat.substitute(statement, substitutionValues);
    var queryMessage = new _QueryMessage(sqlString);

    socket.add(queryMessage.asBytes());
  }

  void sendExtended(Socket socket, {_QueryCache cacheQuery: null}) {
    if (cacheQuery != null) {
      fieldDescriptions = cacheQuery.fieldDescriptions;
      sendCachedQuery(socket, cacheQuery, substitutionValues);

      return;
    }

    String statementName = (statementIdentifier ?? "");
    var formatIdentifiers = <_PostgreSQLFormatIdentifier>[];
    var sqlString = PostgreSQLFormat.substitute(statement, substitutionValues,
        replace: (_PostgreSQLFormatIdentifier identifier, int index) {
      formatIdentifiers.add(identifier);

      return "\$$index";
    });

    specifiedParameterTypeCodes =
        formatIdentifiers.map((i) => i.typeCode).toList();

    var parameterList = formatIdentifiers
        .map((id) => encodeParameter(id, substitutionValues))
        .toList();

    var messages = [
      new _ParseMessage(sqlString, statementName: statementName),
      new _DescribeMessage(statementName: statementName),
      new _BindMessage(parameterList, statementName: statementName),
      new _ExecuteMessage(),
      new _SyncMessage()
    ];

    if (statementIdentifier != null) {
      cache = new _QueryCache(statementIdentifier, formatIdentifiers);
    }

    socket.add(_ClientMessage.aggregateBytes(messages));
  }

  void sendCachedQuery(Socket socket, _QueryCache cacheQuery,
      Map<String, dynamic> substitutionValues) {
    var statementName = cacheQuery.preparedStatementName;
    var parameterList = cacheQuery.orderedParameters
        .map((identifier) => encodeParameter(identifier, substitutionValues))
        .toList();

    var bytes = _ClientMessage.aggregateBytes([
      new _BindMessage(parameterList, statementName: statementName),
      new _ExecuteMessage(),
      new _SyncMessage()
    ]);

    socket.add(bytes);
  }

  _ParameterValue encodeParameter(_PostgreSQLFormatIdentifier identifier,
      Map<String, dynamic> substitutionValues) {
    if (identifier.typeCode != null) {
      return new _ParameterValue.binary(
          substitutionValues[identifier.name], identifier.typeCode);
    } else {
      return new _ParameterValue.text(substitutionValues[identifier.name]);
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
      onComplete.complete(rowsAffected);
      return;
    }

    onComplete.complete(rows.map((row) => row.toList()).toList());
  }

  void completeError(dynamic error) {
    onComplete.completeError(error);
  }

  String toString() => statement;
}

class _QueryCache {
  _QueryCache(this.preparedStatementName, this.orderedParameters);

  String preparedStatementName;
  List<_PostgreSQLFormatIdentifier> orderedParameters;
  List<_FieldDescription> fieldDescriptions;

  bool get isValid {
    return preparedStatementName != null &&
        orderedParameters != null &&
        fieldDescriptions != null;
  }
}

class _ParameterValue {
  _ParameterValue.binary(dynamic value, this.postgresType) {
    isBinary = true;
    bytes = PostgreSQLCodec
        .encodeBinary(value, this.postgresType)
        ?.buffer
        ?.asUint8List();
    length = bytes?.length ?? 0;
  }

  _ParameterValue.text(dynamic value) {
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

class _FieldDescription {
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
