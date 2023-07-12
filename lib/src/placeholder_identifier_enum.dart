/// placeholder Identifier
class PlaceholderIdentifier {
  final String value;
  const PlaceholderIdentifier(this.value);

  /// The colon is the symbol ":"
  /// Example: "SELECT * FROM book WHERE title = :title AND code = :code"
  //static const PlaceholderIdentifier colon = PlaceholderIdentifier(':');

  // The question mark ? (also known as interrogation point)
  //static const PlaceholderStyle questionMark = const PlaceholderStyle('?');

  /// The question mark ? (also known as interrogation point)
  /// Example: "SELECT * FROM book WHERE title = ? AND code = ?"
  /// Note: You cannot enclose the question mark in quotation marks. incorrect '?' => correct ??
  static const PlaceholderIdentifier onlyQuestionMark =
      PlaceholderIdentifier('?');

  /// In business, @ (Arroba ) is a symbol meaning "at" or "each."
  /// Example: "SELECT * FROM book WHERE title = @title AND code = @code"
  static const PlaceholderIdentifier atSign = PlaceholderIdentifier('@');

  /// Postgresql default style
  /// Example: "SELECT * FROM book WHERE title = $1 AND code = $2"
  /// Postgres uses $# for placeholders https://www.postgresql.org/docs/9.1/sql-prepare.html
  //static const PlaceholderIdentifier pgDefault = PlaceholderIdentifier(r'$#');

  @override
  String toString() {
    switch (this) {
      // case pgDefault:
      //   return 'PlaceholderIdentifier.pgDefault';
      case atSign:
        return 'PlaceholderIdentifier.atSign';
      case onlyQuestionMark:
        return 'PlaceholderIdentifier.onlyQuestionMark';
      // case colon:
      //   return 'PlaceholderIdentifier.colon';
      default:
        return 'PlaceholderIdentifier unknown';
    }
  }
}
