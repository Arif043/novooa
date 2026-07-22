import 'dart:convert';
import 'dart:js_interop';

import 'python_syntax_parser_contract.dart';

@JS('novooaPythonParser.analyze')
external JSPromise<JSString> _analyzePythonSyntax(JSString source);

PythonSyntaxParser createPythonSyntaxParser() => _WasmPythonSyntaxParser();

class _WasmPythonSyntaxParser implements PythonSyntaxParser {
  @override
  Future<List<PythonSyntaxIssue>> analyze(String source) async {
    try {
      final response = await _analyzePythonSyntax(source.toJS).toDart;
      return _issuesFromJson(response.toDart);
    } on Object {
      return const [];
    }
  }

  List<PythonSyntaxIssue> _issuesFromJson(String response) {
    final values = jsonDecode(response) as List<dynamic>;
    return [
      for (final value in values)
        if (value case {'line': int line, 'message': String message})
          PythonSyntaxIssue(line: line, message: message),
    ];
  }
}
