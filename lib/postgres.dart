library postgres;

import 'src/types.dart';

export 'src/connection.dart';
export 'src/execution_context.dart';
export 'src/replication.dart' show ReplicationMode;
export 'src/substituter.dart';
export 'src/types.dart';

typedef PostgreSQLDataType = PgDataType<Object>;
typedef PostgreSQLSeverity = PgSeverity;
