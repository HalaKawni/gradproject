enum GameDiagnosticSeverity { info, warning, error }

enum GameDiagnosticType { syntax, validation, runtime }

class GameSourceSpan {
  final int line;
  final int column;
  final String sourceLine;

  const GameSourceSpan({
    required this.line,
    required this.column,
    required this.sourceLine,
  });

  factory GameSourceSpan.fromJson(Map<String, dynamic> json) {
    return GameSourceSpan(
      line: (json['line'] as num?)?.toInt() ?? 1,
      column: (json['column'] as num?)?.toInt() ?? 1,
      sourceLine: json['sourceLine']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'line': line,
      'column': column,
      'sourceLine': sourceLine,
    };
  }
}

class GameDiagnostic {
  final String message;
  final int line;
  final int column;
  final GameDiagnosticSeverity severity;
  final GameDiagnosticType type;
  final String? hint;
  final String? sourceLine;

  const GameDiagnostic({
    required this.message,
    required this.line,
    this.column = 1,
    this.severity = GameDiagnosticSeverity.error,
    this.type = GameDiagnosticType.syntax,
    this.hint,
    this.sourceLine,
  });

  factory GameDiagnostic.fromSpan({
    required String message,
    required GameSourceSpan span,
    GameDiagnosticSeverity severity = GameDiagnosticSeverity.error,
    GameDiagnosticType type = GameDiagnosticType.runtime,
    String? hint,
  }) {
    return GameDiagnostic(
      message: message,
      line: span.line,
      column: span.column,
      severity: severity,
      type: type,
      hint: hint,
      sourceLine: span.sourceLine,
    );
  }

  String get displayMessage {
    final buffer = StringBuffer('Line $line, Column $column: $message');
    if (hint != null && hint!.isNotEmpty) {
      buffer.write('\nHint: $hint');
    }
    return buffer.toString();
  }
}

class GameExecutionResult {
  final List<GameDiagnostic> diagnostics;

  const GameExecutionResult({this.diagnostics = const <GameDiagnostic>[]});

  bool get hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == GameDiagnosticSeverity.error,
  );

  bool get success => !hasErrors;

  GameDiagnostic? get firstError {
    for (final diagnostic in diagnostics) {
      if (diagnostic.severity == GameDiagnosticSeverity.error) {
        return diagnostic;
      }
    }
    return null;
  }
}
