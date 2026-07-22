import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/languages/python.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/python_analyzer.dart';

void main() {
  const analyzer = PythonAnalyzer();

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
}

Code _pythonCode(String source) => Code(text: source, language: python);
