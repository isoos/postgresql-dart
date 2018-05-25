import 'dart:convert';
import 'dart:typed_data';

import 'connection.dart';
import 'query.dart';

abstract class ServerMessage {
  void readBytes(Uint8List bytes);
}

class ErrorResponseMessage implements ServerMessage {
  List<ErrorField> fields = [new ErrorField()];

  void readBytes(Uint8List bytes) {
    var lastByteRemovedList = new Uint8List.view(bytes.buffer, bytes.offsetInBytes, bytes.length - 1);

    lastByteRemovedList.forEach((byte) {
      if (byte != 0) {
        fields.last.add(byte);
        return;
      }

      fields.add(new ErrorField());
    });
  }
}

class AuthenticationMessage implements ServerMessage {
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
}

class ParameterStatusMessage extends ServerMessage {
  String name;
  String value;

  void readBytes(Uint8List bytes) {
    name = utf8.decode(bytes.sublist(0, bytes.indexOf(0)));
    value = utf8.decode(bytes.sublist(bytes.indexOf(0) + 1, bytes.lastIndexOf(0)));
  }
}

class ReadyForQueryMessage extends ServerMessage {
  static const String StateIdle = "I";
  static const String StateTransaction = "T";
  static const String StateTransactionError = "E";

  String state;

  void readBytes(Uint8List bytes) {
    state = utf8.decode(bytes);
  }
}

class BackendKeyMessage extends ServerMessage {
  int processID;
  int secretKey;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    processID = view.getUint32(0);
    secretKey = view.getUint32(4);
  }
}

class RowDescriptionMessage extends ServerMessage {
  List<FieldDescription> fieldDescriptions;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;
    var fieldCount = view.getInt16(offset);
    offset += 2;

    fieldDescriptions = <FieldDescription>[];
    for (var i = 0; i < fieldCount; i++) {
      var rowDesc = new FieldDescription();
      offset = rowDesc.parse(view, offset);
      fieldDescriptions.add(rowDesc);
    }
  }
}

class DataRowMessage extends ServerMessage {
  List<ByteData> values = [];

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;
    var fieldCount = view.getInt16(offset);
    offset += 2;

    for (var i = 0; i < fieldCount; i++) {
      var dataSize = view.getInt32(offset);
      offset += 4;

      if (dataSize == 0) {
        values.add(new ByteData(0));
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

class NotificationResponseMessage extends ServerMessage {
  int processID;
  String channel;
  String payload;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);
    processID = view.getUint32(0);
    channel = utf8.decode(bytes.sublist(4, bytes.indexOf(0, 4)));
    payload = utf8.decode(bytes.sublist(bytes.indexOf(0, 4) + 1, bytes.lastIndexOf(0)));
  }
}

class CommandCompleteMessage extends ServerMessage {
  int rowsAffected;

  static RegExp identifierExpression = new RegExp(r"[A-Z ]*");

  void readBytes(Uint8List bytes) {
    var str = utf8.decode(bytes.sublist(0, bytes.length - 1));

    var match = identifierExpression.firstMatch(str);
    if (match.end < str.length) {
      rowsAffected = int.parse(str.split(" ").last);
    } else {
      rowsAffected = 0;
    }
  }
}

class ParseCompleteMessage extends ServerMessage {
  void readBytes(Uint8List bytes) {}

  String toString() => "Parse Complete Message";
}

class BindCompleteMessage extends ServerMessage {
  void readBytes(Uint8List bytes) {}

  String toString() => "Bind Complete Message";
}

class ParameterDescriptionMessage extends ServerMessage {
  List<int> parameterTypeIDs;

  void readBytes(Uint8List bytes) {
    var view = new ByteData.view(bytes.buffer, bytes.offsetInBytes);

    var offset = 0;
    var count = view.getUint16(0);
    offset += 2;

    parameterTypeIDs = [];
    for (var i = 0; i < count; i++) {
      var v = view.getUint32(offset);
      offset += 4;
      parameterTypeIDs.add(v);
    }
  }
}

class NoDataMessage extends ServerMessage {
  void readBytes(Uint8List bytes) {}

  String toString() => "No Data Message";
}

class UnknownMessage extends ServerMessage {
  Uint8List bytes;
  int code;

  void readBytes(Uint8List bytes) {
    this.bytes = bytes;
  }

  @override
  int get hashCode {
    return bytes.hashCode;
  }

  @override
  operator ==(dynamic other) {
    if (bytes != null) {
      if (bytes.length != other.bytes.length) {
        return false;
      }
      for (var i = 0; i < bytes.length; i++) {
        if (bytes[i] != other.bytes[i]) {
          return false;
        }
      }
    } else {
      if (other.bytes != null) {
        return false;
      }
    }
    return code == other.code;
  }
}

class ErrorField {
  static const int SeverityIdentifier = 83;
  static const int CodeIdentifier = 67;
  static const int MessageIdentifier = 77;
  static const int DetailIdentifier = 68;
  static const int HintIdentifier = 72;
  static const int PositionIdentifier = 80;
  static const int InternalPositionIdentifier = 112;
  static const int InternalQueryIdentifier = 113;
  static const int WhereIdentifier = 87;
  static const int SchemaIdentifier = 115;
  static const int TableIdentifier = 116;
  static const int ColumnIdentifier = 99;
  static const int DataTypeIdentifier = 100;
  static const int ConstraintIdentifier = 110;
  static const int FileIdentifier = 70;
  static const int LineIdentifier = 76;
  static const int RoutineIdentifier = 82;

  static PostgreSQLSeverity severityFromString(String str) {
    switch (str) {
      case "ERROR":
        return PostgreSQLSeverity.error;
      case "FATAL":
        return PostgreSQLSeverity.fatal;
      case "PANIC":
        return PostgreSQLSeverity.panic;
      case "WARNING":
        return PostgreSQLSeverity.warning;
      case "NOTICE":
        return PostgreSQLSeverity.notice;
      case "DEBUG":
        return PostgreSQLSeverity.debug;
      case "INFO":
        return PostgreSQLSeverity.info;
      case "LOG":
        return PostgreSQLSeverity.log;
    }

    return PostgreSQLSeverity.unknown;
  }

  int identificationToken;

  String get text => _buffer.toString();
  StringBuffer _buffer = new StringBuffer();

  void add(int byte) {
    if (identificationToken == null) {
      identificationToken = byte;
    } else {
      _buffer.writeCharCode(byte);
    }
  }
}
