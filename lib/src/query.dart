part of postgres;

class _Query<T> {
  _Query(this.statement, this.substitutionValues);

  bool onlyReturnAffectedRowCount = false;
  bool allowReuse = false;
  String statement;
  Map<String, dynamic> substitutionValues;
  Completer<T> onComplete = new Completer();
  Future<T> get future => onComplete.future;

  List<int> specifiedParameterTypeCodes;
  List<_FieldDescription> fieldDescriptions;
  List<Iterable<dynamic>> rows = [];

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
    if (onComplete.isCompleted) {
      return;
    }

    if (onlyReturnAffectedRowCount) {
      onComplete.complete(rowsAffected);
      return;
    }

    onComplete.complete(rows.map((row) => row.toList()).toList());
  }

  void completeError(dynamic error) {
    if (onComplete.isCompleted) {
      return;
    }

    onComplete.completeError(error);
  }

  String toString() => statement;
}

class _QueryCache {
  _QueryCache(this.preparedStatementName, this.orderedParameters);

  String preparedStatementName;
  List<PostgreSQLFormatIdentifier> orderedParameters;
  List<_FieldDescription> fieldDescriptions;
}

class _ParameterValue {
  _ParameterValue.binary(dynamic value, this.postgresType) {
    isBinary = true;
    bytes = PostgreSQLCodec.encodeBinary(value, this.postgresType)?.buffer?.asUint8List();
    length = bytes?.length ?? 0;
  }

  _ParameterValue.text(dynamic value) {
    isBinary = false;
    if (value != null) {
      bytes = new Uint8List.fromList(PostgreSQLCodec.encode(value, escapeStrings: false).codeUnits);
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
      byte = byteData.getUint8(offset); offset += 1;
      if (byte != 0) {
        buf.writeCharCode(byte);
      }
    } while (byte != 0);

    fieldName = buf.toString();

    tableID = byteData.getUint32(offset); offset += 4;
    columnID = byteData.getUint16(offset); offset += 2;
    typeID = byteData.getUint32(offset); offset += 4;
    dataTypeSize = byteData.getUint16(offset); offset += 2;
    typeModifier = byteData.getInt32(offset); offset += 4;
    formatCode = byteData.getUint16(offset); offset += 2;

    return offset;
  }

  String toString() {
    return "$fieldName $tableID $columnID $typeID $dataTypeSize $typeModifier $formatCode";
  }
}

