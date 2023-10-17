library legacy;

import 'src/types.dart';

export 'src/exceptions.dart';
export 'src/replication.dart' show ReplicationMode;
export 'src/types.dart';
export 'src/v2/connection.dart';
export 'src/v2/execution_context.dart';
export 'src/v2/substituter.dart';
export 'src/v2/v2_v3_delegate.dart';

typedef PostgreSQLDataType = DataType<Object>;
typedef PostgreSQLSeverity = Severity;
