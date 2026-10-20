import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_password_rule.dart';

void main() {
  test('verlangt mindestens 12 Zeichen', () {
    expect(runtimeNewPasswordProblem('elf-zeichen'), isNotNull);
    expect(runtimeNewPasswordProblem('zwoelf-zeich'), isNull);
  });

  test('meldet abweichende Wiederholung erst nach passender Länge', () {
    expect(
      runtimeNewPasswordProblem('zwoelf-zeich', confirmation: 'anders'),
      'Die Passwörter stimmen nicht überein.',
    );
  });
}
