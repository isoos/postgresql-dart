extension AppendToEnd on List {
  void replaceLast(dynamic item) {
    if (length == 0) {
      add(item);
    } else {
      this[length - 1] = item;
    }
  }

  /// like python index function
  /// Example: var placeholders = ['a','b','c','d','e'];
  /// pidx = placeholders.index(placeholders[-1],0,-1);
  /// Exception: ValueError: 'e' is not in list
  int indexWithEnd(Object? element, [int start = 0, int? stop]) {
    if (start < 0) start = 0;

    if (stop != null && stop < 0) stop = length - 1;

    for (int i = start; i < (stop ?? length); i++) {
      if (this[i] == element) return i;
    }
    throw Exception("ValueError: '$element' is not in list");
  }
}

/// outside quoted string
const OUTSIDE = 0;

/// inside single-quote string '...'
const INSIDE_SQ = 1;

/// inside quoted identifier   "..."
const INSIDE_QI = 2;

/// inside escaped single-quote string, E'...'
const INSIDE_ES = 3;

/// inside parameter name eg. :name
const INSIDE_PN = 4;

/// inside inline comment eg. --
const INSIDE_CO = 5;

/// The isalnum() method returns True if all characters in the string are alphanumeric (either alphabets or numbers). If not, it returns False.
bool isalnum(String? s) {
  // alphanumeric
  final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
  if (s == null) {
    return false;
  }
  return validCharacters.hasMatch(s);
}

/// the toStatement function is used to replace the 'placeholderIdentifier' to  '$#' for postgres sql statement style
/// Example: "INSERT INTO book (title) VALUES (:title)" to "INSERT INTO book (title) VALUES ($1)"
/// [placeholderIdentifier] placeholder identifier character represents the pattern that will be
///  replaced in the execution of the query by the supplied parameters
/// [params] parameters can be a list or a map
/// `Returns` [ String query,  List<dynamic> Function(dynamic) make_vals ]
/// Postgres uses $# for placeholders https://www.postgresql.org/docs/9.1/sql-prepare.html
List toStatement(String query, Map params,
    {String placeholderIdentifier = ':'}) {
  var inQuoteEscape = false;
  final placeholders = [];
  final outputQuery = [];
  var state = OUTSIDE;
  // ignore: prefer_typing_uninitialized_variables
  var prevC;
  String? nextC;

  //add space to end
  final splitString = '$query  '.split('');
  for (var i = 0; i < splitString.length; i++) {
    final c = splitString[i];

    if (i + 1 < splitString.length) {
      nextC = splitString[i + 1];
    } else {
      nextC = null;
    }

    if (state == OUTSIDE) {
      if (c == "'") {
        outputQuery.add(c);
        if (prevC == 'E') {
          state = INSIDE_ES;
        } else {
          state = INSIDE_SQ;
        }
      } else if (c == '"') {
        outputQuery.add(c);
        state = INSIDE_QI;
      } else if (c == '-') {
        outputQuery.add(c);
        if (prevC == '-') {
          state = INSIDE_CO;
        }

        //ignore operator @@ or := :: @= ?? ?=
      } else if (c == placeholderIdentifier &&
          '$placeholderIdentifier='.contains(nextC ?? '') == false &&
          '$placeholderIdentifier$placeholderIdentifier'
                  .contains(nextC ?? '') ==
              false &&
          prevC != placeholderIdentifier) {
        state = INSIDE_PN;
        placeholders.add('');
      } else {
        outputQuery.add(c);
      }
    }
    //
    else if (state == INSIDE_SQ) {
      if (c == "'") {
        if (inQuoteEscape) {
          inQuoteEscape = false;
        } else if (nextC == "'") {
          inQuoteEscape = true;
        } else {
          state = OUTSIDE;
        }
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_QI) {
      if (c == '"') {
        state = OUTSIDE;
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_ES) {
      if (c == "'" && prevC != '\\') {
        // check for escaped single-quote
        state = OUTSIDE;
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_PN) {
      placeholders.replaceLast(placeholders.last + c);

      if (nextC == null || (!isalnum(nextC) && nextC != '_')) {
        state = OUTSIDE;
        try {
          //print('to_statement last: ${placeholders.last}');
          final pidx = placeholders.indexWithEnd(placeholders.last, 0, -1);
          //print('to_statement pidx: $pidx');
          outputQuery.add('\$${pidx + 1}');
          //del placeholders[-1]
          placeholders.removeLast();
        } catch (_) {
          outputQuery.add('\$${placeholders.length}');
        }
      }
    }
    //
    else if (state == INSIDE_CO) {
      outputQuery.add(c);
      if (c == '\n') {
        state = OUTSIDE;
      }
    }
    prevC = c;
  }

  for (var reserved in ['types', 'stream']) {
    if (placeholders.contains(reserved)) {
      throw Exception(
          "The name '$reserved' can't be used as a placeholder because it's "
          'used for another purpose.');
    }
  }

  /// [args]
  // ignore: non_constant_identifier_names
  make_vals(Map args) {
    final vals = [];
    for (var p in placeholders) {
      try {
        vals.add(args[p]);
      } catch (_) {
        throw Exception(
            "There's a placeholder '$p' in the query, but no matching "
            'keyword argument.');
      }
    }
    return vals;
  }

  var resultQuery = outputQuery.join('');
  //resultQuery = resultQuery.substring(0, resultQuery.length - 1);
  resultQuery = resultQuery.trim();
  return [resultQuery, make_vals(params)];
}

/// the toStatement2 function is used to replace the Question mark '?' to  '$1' for sql statement
/// "INSERT INTO book (title) VALUES (?)" to "INSERT INTO book (title) VALUES ($1)"
/// `Returns` [ String query,  List<dynamic> Function(dynamic) make_vals ]
/// Postgres uses $# for placeholders https://www.postgresql.org/docs/9.1/sql-prepare.html
String toStatement2(String query) {
  final placeholderIdentifier = '?';
  var inQuoteEscape = false;
  // var placeholders = [];
  final outputQuery = [];
  var state = OUTSIDE;
  var paramCount = 1;
  //character anterior

  String? prevC;
  String? nextC;

  //add space to end of string to force INSIDE_PN;
  final splitString = '$query  '.split('');
  for (var i = 0; i < splitString.length; i++) {
    final c = splitString[i];

    //print('for state: $state');

    if (i + 1 < splitString.length) {
      nextC = splitString[i + 1];
    } else {
      nextC = null;
    }

    if (state == OUTSIDE) {
      if (c == "'") {
        outputQuery.add(c);
        if (prevC == 'E') {
          state = INSIDE_ES;
        } else {
          state = INSIDE_SQ;
        }
      } else if (c == '"') {
        outputQuery.add(c);
        state = INSIDE_QI;
      } else if (c == '-') {
        outputQuery.add(c);
        if (prevC == '-') {
          state = INSIDE_CO;
        }
        //ignore operator @@ or := :: @= ?? ?=
      } else if (c == placeholderIdentifier && prevC != placeholderIdentifier) {
        state = INSIDE_PN;

        //print('c == placeholder: $c');
        // placeholders.add("");
        outputQuery.add('\$$paramCount');
        paramCount++;
      } else {
        outputQuery.add(c);
      }
    }
    //
    else if (state == INSIDE_SQ) {
      if (c == "'") {
        if (inQuoteEscape) {
          inQuoteEscape = false;
        } else if (nextC == "'") {
          inQuoteEscape = true;
        } else {
          state = OUTSIDE;
        }
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_QI) {
      if (c == '"') {
        state = OUTSIDE;
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_ES) {
      if (c == "'" && prevC != '\\') {
        // check for escaped single-quote
        state = OUTSIDE;
      }
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_PN) {
      if (nextC == null || (!isalnum(nextC) && nextC != '_')) {
        state = OUTSIDE;
      }
      //print('state == INSIDE_PN: $c');
      outputQuery.add(c);
    }
    //
    else if (state == INSIDE_CO) {
      outputQuery.add(c);
      if (c == '\n') {
        state = OUTSIDE;
      }
    }
    prevC = c;
  }

  final resultQuery = outputQuery.join('');
  //resultQuery = resultQuery.substring(0, resultQuery.length - 1);
  return resultQuery.trim();
}
