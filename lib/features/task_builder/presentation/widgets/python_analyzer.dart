import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import 'python_syntax_parser.dart';
import 'python_syntax_parser_contract.dart';

class PythonAnalyzer extends AbstractAnalyzer {
  PythonAnalyzer({PythonSyntaxParser? syntaxParser})
    : _syntaxParser = syntaxParser ?? createPythonSyntaxParser();

  final PythonSyntaxParser _syntaxParser;

  @override
  Future<AnalysisResult> analyze(Code code) async {
    final defaultResult = await const DefaultLocalAnalyzer().analyze(code);
    final syntaxIssues = await _syntaxParser.analyze(code.text);
    final issues = [
      ...defaultResult.issues,
      ..._indentationIssues(code.text),
      ...syntaxIssues.map(_issueFor),
    ]..sort(issueLineComparator);
    return AnalysisResult(issues: issues);
  }
}

Issue _issueFor(PythonSyntaxIssue issue) {
  return Issue(line: issue.line, message: issue.message, type: IssueType.error);
}

List<Issue> _indentationIssues(String source) {
  final state = _PythonIndentationState();
  final issues = <Issue>[];
  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    state.inspect(lines[index], index, issues);
  }
  return issues;
}

class _PythonIndentationState {
  final _levels = <int>[0];
  bool _expectsIndentedBlock = false;

  void inspect(String line, int lineIndex, List<Issue> issues) {
    final executableCode = _withoutComment(line);
    if (executableCode.trim().isEmpty) return;
    final indentation = _indentationOf(line);
    _reportMixedIndentation(line, lineIndex, issues);
    _validateLevel(indentation, lineIndex, issues);
    _reportMissingColon(executableCode, lineIndex, issues);
    _expectsIndentedBlock = executableCode.trimRight().endsWith(':');
  }

  void _validateLevel(int indentation, int lineIndex, List<Issue> issues) {
    final currentLevel = _levels.last;
    if (_expectsIndentedBlock && indentation <= currentLevel) {
      _addIssue(issues, lineIndex, LocaleKeys.ui_py_expected_indent.tr());
      return;
    }
    if (!_expectsIndentedBlock && indentation > currentLevel) {
      _addIssue(issues, lineIndex, LocaleKeys.ui_py_unexpected_indent.tr());
      return;
    }
    _alignLevel(indentation, lineIndex, issues);
  }

  void _alignLevel(int indentation, int lineIndex, List<Issue> issues) {
    if (indentation > _levels.last) {
      _levels.add(indentation);
      return;
    }
    while (indentation < _levels.last) {
      _levels.removeLast();
    }
    if (indentation != _levels.last) {
      _addIssue(issues, lineIndex, LocaleKeys.ui_py_indent_mismatch.tr());
    }
  }

  void _reportMixedIndentation(String line, int lineIndex, List<Issue> issues) {
    final indentation = line.substring(0, line.length - line.trimLeft().length);
    if (indentation.contains(' ') && indentation.contains('\t')) {
      _addIssue(issues, lineIndex, LocaleKeys.ui_py_mixed_tabs.tr());
    }
  }

  void _reportMissingColon(String code, int lineIndex, List<Issue> issues) {
    final trimmedCode = code.trimRight();
    if (_isBlockHeaderWithoutColon(trimmedCode)) {
      _addIssue(issues, lineIndex, LocaleKeys.ui_py_missing_colon.tr());
    }
  }
}

int _indentationOf(String line) {
  final indentation = line.substring(0, line.length - line.trimLeft().length);
  return indentation.replaceAll('\t', '    ').length;
}

String _withoutComment(String line) {
  String? quote;
  for (var index = 0; index < line.length; index++) {
    final character = line[index];
    if (character == '\\') {
      index += 1;
      continue;
    }
    if (quote == null && (character == "'" || character == '"')) {
      quote = character;
      continue;
    }
    if (quote == character) {
      quote = null;
      continue;
    }
    if (quote == null && character == '#') return line.substring(0, index);
  }
  return line;
}

bool _isBlockHeaderWithoutColon(String code) {
  if (code.endsWith(':')) return false;
  return RegExp(
    r'^(async\s+def|def|class|if|elif|else|for|while|try|except|finally|with|match|case)\b',
  ).hasMatch(code.trimLeft());
}

void _addIssue(List<Issue> issues, int lineIndex, String message) {
  issues.add(Issue(line: lineIndex, message: message, type: IssueType.error));
}
