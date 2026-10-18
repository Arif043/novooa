import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/script_packages/domain/entities/script_package_environment.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_packages/script_package_status_row.dart';

void main() {
  Future<int> pump(
    WidgetTester tester,
    ScriptPackageEnvironment? environment,
  ) async {
    var installs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptPackageStatusRow(
            environment: environment,
            onInstall: () => installs++,
          ),
        ),
      ),
    );
    return installs;
  }

  testWidgets('nicht installiert: Klick startet die Installation', (
    tester,
  ) async {
    var installs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptPackageStatusRow(
            environment: null,
            onInstall: () => installs++,
          ),
        ),
      ),
    );

    expect(find.text('Nicht installiert'), findsOneWidget);
    await tester.tap(find.text('Pakete installieren'));
    expect(installs, 1);
  });

  testWidgets('wird installiert, installiert und gescheitert', (tester) async {
    await pump(
      tester,
      const ScriptPackageEnvironment(
        packages: ['six'],
        state: ScriptPackageEnvironmentState.installing,
      ),
    );
    expect(find.text('Wird installiert …'), findsOneWidget);

    await pump(
      tester,
      const ScriptPackageEnvironment(
        packages: ['six'],
        state: ScriptPackageEnvironmentState.ready,
        sizeBytes: 3 * 1024 * 1024,
      ),
    );
    expect(find.text('Installiert (3,0 MB)'), findsOneWidget);

    await pump(
      tester,
      const ScriptPackageEnvironment(
        packages: ['gibtsnicht'],
        state: ScriptPackageEnvironmentState.failed,
        problem: ScriptPackageInstallProblem.notFound,
        detail: 'gibtsnicht was not found',
      ),
    );
    expect(
      find.text('Ein Paket wurde auf PyPI nicht gefunden.'),
      findsOneWidget,
    );
    expect(find.text('gibtsnicht was not found'), findsOneWidget);
    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('names the module that could not be loaded', (tester) async {
    await pump(
      tester,
      const ScriptPackageEnvironment(
        packages: ['weasyprint'],
        state: ScriptPackageEnvironmentState.failed,
        problem: ScriptPackageInstallProblem.notLoadable,
        detail: 'weasyprint: OSError: cannot load library libpango',
      ),
    );

    expect(
      find.textContaining('ließ sich im Script-Container aber nicht laden'),
      findsOneWidget,
    );
    expect(
      find.text('weasyprint: OSError: cannot load library libpango'),
      findsOneWidget,
    );
  });
}
