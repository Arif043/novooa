import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/script_packages/domain/services/import_package_names.dart';
import 'package:syscat2/features/script_packages/domain/services/python_import_scanner.dart';

void main() {
  test(
    'findet Paket-Imports und lässt Standardbibliothek und Kommentare weg',
    () {
      const script = '''
import json, os.path
import numpy as np, pandas
from cv2 import imread
from sklearn.linear_model import LinearRegression
from . import lokal
# import auskommentiert
def f():
    import yaml
    from datetime import date
''';

      expect(const PythonImportScanner()(script), [
        'numpy',
        'pandas',
        'cv2',
        'sklearn',
        'yaml',
      ]);
    },
  );

  test('schlägt für abweichende Module das richtige Paket vor', () {
    const names = ImportPackageNames();

    expect(names.packageFor('cv2'), 'opencv-python-headless');
    expect(names.packageFor('sklearn'), 'scikit-learn');
    expect(names.packageFor('pandas'), 'pandas');
  });
}
