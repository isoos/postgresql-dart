library legacy;

import 'src/exceptions.dart';
import 'src/types.dart';

export 'src/v2/connection.dart';
export 'src/v2/execution_context.dart';
export 'src/v2/substituter.dart';

@Deprecated('Do not use v2 API, will be removed in next release.')
typedef PostgreSQLDataType = Type<Object>;
@Deprecated('Do not use v2 API, will be removed in next release.')
typedef PostgreSQLSeverity = Severity;
