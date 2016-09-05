part of postgres;

abstract class _ServerMessage {
  void readBytes(Uint8List bytes);
}

class _ErrorResponseMessage implements _ServerMessage {
  PostgreSQLException generatedException;
  List<_ErrorField> fields = [new _ErrorField()];

  void readBytes(Uint8List bytes) {
    var lastByteRemovedList = new Uint8List.view(bytes.buffer, bytes.offsetInBytes, bytes.length - 1);

    lastByteRemovedList.forEach((byte) {
      if (byte != 0) {
        fields.last.add(byte);
        return;
      }

      fields.add(new _ErrorField());
    });

    generatedException = new PostgreSQLException._(fields);
  }

  String toString() => generatedException.toString();
}

class _AuthenticationMessage implements _ServerMessage {
  static const int KindOK = 0;
  static const int KindKerberosV5 = 2;
  static const int KindClearTextPassword = 3;
  static const int KindMD5Password = 5;
  static const int KindSCMCredential = 6;
  static const int KindGSS = 7;
  static const int KindGSSContinue = 8;
  static const int KindSSPI = 9;

  int type;

  List<int> salt;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    type = view.getUint32(0);

    if (type == KindMD5Password) {
      salt = new List<int>(4);
      for (var i = 0; i < 4; i++) {
        salt[i] = view.getUint8(4 + i);
      }
    }
  }

  String toString() => "Authentication: $type";
}

class _ParameterStatusMessage extends _ServerMessage {
  String name;
  String value;

  void readBytes(Uint8List bytes) {
    name = new String.fromCharCodes(bytes.sublist(0, bytes.indexOf(0)));
    value = new String.fromCharCodes(bytes.sublist(bytes.indexOf(0) + 1, bytes.lastIndexOf(0)));
  }

  String toString() => "Parameter Message: $name $value";
}

class _ReadyForQueryMessage extends _ServerMessage {
  static const String StateIdle = "I";
  static const String StateTransaction = "T";
  static const String StateTransactionError = "E";

  String state;

  void readBytes(Uint8List bytes) {
    state = new String.fromCharCodes(bytes);
  }

  String toString() => "Ready Message: $state";
}

class _BackendKeyMessage extends _ServerMessage {
  int processID;
  int secretKey;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    processID = view.getUint32(0);
    secretKey = view.getUint32(4);
  }

  String toString() => "Backend Key Message: $processID $secretKey";
}

class _RowDescriptionMessage extends _ServerMessage {
  List<_FieldDescription> fieldDescriptions;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;
    var fieldCount = view.getInt16(offset); offset += 2;

    fieldDescriptions = <_FieldDescription>[];
    for (var i = 0; i < fieldCount; i++) {
      var rowDesc = new _FieldDescription();
      offset = rowDesc.parse(view, offset);
      fieldDescriptions.add(rowDesc);
    }
  }

  String toString() => "RowDescription Message: $fieldDescriptions";
}

class _DataRowMessage extends _ServerMessage {
  List<ByteData> values = [];

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;
    var fieldCount = view.getInt16(offset); offset += 2;

    for (var i = 0; i < fieldCount; i++) {
      var dataSize = view.getInt32(offset); offset += 4;

      if (dataSize == 0) {
        continue;
      } else if (dataSize == -1) {
        values.add(null);
      } else {
        var rawBytes = new ByteData.view(bytes.buffer, bytes.offsetInBytes + offset, dataSize);
        values.add(rawBytes);
        offset += dataSize;
      }
    }
  }

  String toString() => "Data Row Message: ${values}";
}

class _CommandCompleteMessage extends _ServerMessage {
  int rowsAffected;

  static RegExp identifierExpression = new RegExp(r"[A-Z ]*");
  void readBytes(Uint8List bytes) {
    var str = new String.fromCharCodes(bytes.sublist(0, bytes.length - 1));

    var match = identifierExpression.firstMatch(str);
    if (match.end < str.length) {
      rowsAffected = int.parse(str.split(" ").last);
    } else {
      rowsAffected = 0;
    }
  }

  String toString() => "Command Complete Message: $rowsAffected";
}

class _ParseCompleteMessage extends _ServerMessage {
  void readBytes(Uint8List bytes) {}

  String toString() => "Parse Complete Message";
}

class _BindCompleteMessage extends _ServerMessage {
  void readBytes(Uint8List bytes) {}
  String toString() => "Bind Complete Message";
}

class _ParameterDescriptionMessage extends _ServerMessage {
  List<int> objectIDs;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);

    var offset = 0;
    var count = view.getUint16(0); offset += 2;

    objectIDs = [];
    for (var i = 0; i < count; i++) {
      var v = view.getUint32(offset); offset += 4;
      objectIDs.add(v);
    }
  }

  String toString() => "Parameter Description Message: $objectIDs";
}

class _UnknownMessage extends _ServerMessage {
  Uint8List bytes;
  int code;

  void readBytes(Uint8List bytes) {
    this.bytes = bytes;
  }

  String toString() => "Unknown message: $code $bytes";
}
