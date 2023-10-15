library postgres;

import 'src/types.dart';

export 'src/exceptions.dart';
export 'src/replication.dart' show ReplicationMode;
export 'src/types.dart';
export 'src/v2/connection.dart';
export 'src/v2/execution_context.dart';
export 'src/v2/substituter.dart';

typedef PostgreSQLDataType = PgDataType<Object>;
typedef PostgreSQLSeverity = PgSeverity;
