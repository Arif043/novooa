import 'python_syntax_parser_contract.dart';

PythonSyntaxParser createPythonSyntaxParser() =>
    const _NoopPythonSyntaxParser();

class _NoopPythonSyntaxParser implements PythonSyntaxParser {
  const _NoopPythonSyntaxParser();

  @override
  Future<List<PythonSyntaxIssue>> analyze(String source) async => const [];
}
