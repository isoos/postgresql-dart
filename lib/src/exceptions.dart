part of postgres;

enum PostgreSQLSeverity {
  panic, fatal, error,
  warning, notice,
  debug, info, log,
  unknown
}

class PostgreSQLException implements Exception {
  PostgreSQLException(String message, {PostgreSQLSeverity severity: PostgreSQLSeverity.error, this.stackTrace}) {
    this.severity = severity;
    this.message = message;
    code = "-----";
  }

  PostgreSQLException._(List<_ErrorField> errorFields, {this.stackTrace}) {
    var finder = (int identifer) => (errorFields.firstWhere((_ErrorField e) => e.identificationToken == identifer, orElse: () => null));

    severity = _ErrorField.severityFromString(finder(_ErrorField.SeverityIdentifier).text);
    code = finder(_ErrorField.CodeIdentifier).text;
    message = finder(_ErrorField.MessageIdentifier).text;
    detail = finder(_ErrorField.DetailIdentifier)?.text;
    hint = finder(_ErrorField.HintIdentifier)?.text;

    internalQuery = finder(_ErrorField.InternalQueryIdentifier)?.text;
    trace = finder(_ErrorField.WhereIdentifier)?.text;
    schemaName = finder(_ErrorField.SchemaIdentifier)?.text;
    tableName = finder(_ErrorField.TableIdentifier)?.text;
    columnName = finder(_ErrorField.ColumnIdentifier)?.text;
    dataTypeName = finder(_ErrorField.DataTypeIdentifier)?.text;
    constraintName = finder(_ErrorField.ConstraintIdentifier)?.text;
    fileName = finder(_ErrorField.FileIdentifier)?.text;
    routineName = finder(_ErrorField.RoutineIdentifier)?.text;

    var i = finder(_ErrorField.PositionIdentifier)?.text;
    position = (i != null ? int.parse(i) : null);

    i = finder(_ErrorField.InternalPositionIdentifier)?.text;
    internalPosition = (i != null ? int.parse(i) : null);

    i = finder(_ErrorField.LineIdentifier)?.text;
    lineNumber = (i != null ? int.parse(i) : null);
  }

  PostgreSQLSeverity severity;
  String code;
  String message;
  String detail;
  String hint;
  int position;
  int internalPosition;
  String internalQuery;
  String trace;
  String schemaName;
  String tableName;
  String columnName;
  String dataTypeName;
  String constraintName;
  String fileName;
  int lineNumber;
  String routineName;

  StackTrace stackTrace;

  String toString() => "$severity $code: $message Detail: $detail Hint: $hint Table: $tableName Column: $columnName Constraint: $constraintName";
}

class _ErrorField {
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
      case "ERROR" : return PostgreSQLSeverity.error;
      case "FATAL" : return PostgreSQLSeverity.fatal;
      case "PANIC" : return PostgreSQLSeverity.panic;
      case "WARNING" : return PostgreSQLSeverity.warning;
      case "NOTICE" : return PostgreSQLSeverity.notice;
      case "DEBUG" : return PostgreSQLSeverity.debug;
      case "INFO" : return PostgreSQLSeverity.info;
      case "LOG" : return PostgreSQLSeverity.log;
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

  String toString() => text;
}
