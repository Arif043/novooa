import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_form_state.dart';
import 'package:syscat2/features/auth/presentation/widgets/auth_form_footer.dart';

// Sichert zwei Dinge: den reparierten Moduswechsel-Hinweis (sein Text war
// fest auf „Du nutzt novooa Standalone?" verdrahtet, während der passende
// `_prefix` toter Code war) und den neuen Variantenwechsel vor der
// Anmeldung.
void main() {
  Future<void> pumpFooter(WidgetTester tester, AuthMode mode) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AuthFormFooter(state: AuthFormState(mode: mode)),
          ),
        ),
      ),
    );
  }

  testWidgets('fragt beim Registrieren nach einem bestehenden Konto', (
    tester,
  ) async {
    await pumpFooter(tester, AuthMode.signUp);

    expect(find.text('Bereits registriert?'), findsOneWidget);
    expect(find.text('Jetzt einloggen'), findsOneWidget);
  });

  testWidgets('fragt beim Login nach einem fehlenden Konto', (tester) async {
    await pumpFooter(tester, AuthMode.signIn);

    expect(find.text('Noch kein Konto?'), findsOneWidget);
    expect(find.text('Jetzt registrieren'), findsOneWidget);
  });

  testWidgets(
    'der Moduswechsel verspricht kein Standalone mehr — dafür gibt es jetzt '
    'den echten Variantenwechsel daneben',
    (tester) async {
      await pumpFooter(tester, AuthMode.signUp);

      expect(find.byType(RuntimeVariantSwitchHint), findsOneWidget);
      expect(find.text('Zur eigenen Runtime wechseln'), findsOneWidget);
    },
  );
}
