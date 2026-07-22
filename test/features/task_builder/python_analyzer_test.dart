import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/python_analyzer.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/python_syntax_parser_contract.dart';

void main() {
  final analyzer = PythonAnalyzer(
    syntaxParser: const _StaticPythonSyntaxParser(),
  );

  test('meldet eine fehlende Block-Einrückung', () async {
    final result = await analyzer.analyze(
      _pythonCode('if enabled:\nprint("ok")'),
    );

    expect(result.issues.single.message, contains('Einrückung'));
  });

  test('meldet einen fehlenden Doppelpunkt im Blockkopf', () async {
    final result = await analyzer.analyze(
      _pythonCode('if enabled\n    print("ok")'),
    );

    expect(
      result.issues.map((issue) => issue.message),
      contains(contains('Doppelpunkt')),
    );
  });

  test('akzeptiert einen korrekt eingerückten Block', () async {
    final result = await analyzer.analyze(
      _pythonCode('if enabled:\n    print("ok")'),
    );

    expect(result.issues, isEmpty);
  });

  test('übernimmt Syntaxfehler des Wasm-Parsers als Editor-Fehler', () async {
    final analyzer = PythonAnalyzer(
      syntaxParser: const _StaticPythonSyntaxParser(
        issues: [
          PythonSyntaxIssue(line: 2, message: 'Ungültige Python-Syntax.'),
        ],
      ),
    );

    final result = await analyzer.analyze(_pythonCode('output = input'));

    expect(result.issues.single.line, 2);
    expect(result.issues.single.message, 'Ungültige Python-Syntax.');
  });
}

Code _pythonCode(String source) => Code(text: source, language: python);

class _StaticPythonSyntaxParser implements PythonSyntaxParser {
  const _StaticPythonSyntaxParser({this.issues = const []});

  final List<PythonSyntaxIssue> issues;

  @override
  Future<List<PythonSyntaxIssue>> analyze(String source) async => issues;
}
