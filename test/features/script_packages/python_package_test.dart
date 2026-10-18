import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';

void main() {
  test('normalisiert wie das Backend (normalizedScriptPackages)', () {
    final packages = [
      ' Pandas == 2.2.3',
      'requests[SOCKS, security] >=2.31, <3',
      'opencv_python',
      'pandas==2.2.3',
    ].map(PythonPackage.parse).whereType<PythonPackage>();

    expect(PythonPackage.normalizedList(packages), [
      'opencv-python',
      'pandas==2.2.3',
      'requests[security,socks]>=2.31,<3',
    ]);
  });

  test('behält die Eingabe als Angabe und kennt den Paketnamen', () {
    final package = PythonPackage.parse(' Scikit_Learn>=1.5 ')!;

    expect(package.spec, 'Scikit_Learn>=1.5');
    expect(package.name, 'scikit-learn');
  });

  test('lehnt URLs, Pfade, Optionen und Leeres ab', () {
    for (final text in [
      'https://evil.example/x.whl',
      './lokal',
      '--index-url=http://x',
      'pkg @ http://x',
      'a;b',
      '',
    ]) {
      expect(PythonPackage.parse(text), isNull, reason: text);
    }
  });
}
