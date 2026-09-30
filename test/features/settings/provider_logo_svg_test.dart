import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// Deckt genau die reale Rendering-Kette ab, die
// `language_model_provider_logo.dart`s `providerLogo` für
// `xAi`/`openAiCompatible` nutzt: `SvgPicture.asset` gegen die tatsächlich
// gebündelten Dateien, mit
// eingefärbtem `currentColor` und einem `errorBuilder`-Fallback. Prüft
// direkt, dass die Assets echte, gültige SVGs sind — nicht der historische
// 14-Byte-„404: Not Found"-Platzhalter.
void main() {
  for (final asset in ['assets/icons/xai.svg', 'assets/icons/openai.svg']) {
    testWidgets('rendert $asset ohne auf den errorBuilder zurückzufallen', (
      tester,
    ) async {
      var usedErrorBuilder = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SvgPicture.asset(
              asset,
              width: 16,
              height: 16,
              theme: const SvgTheme(currentColor: Colors.black),
              errorBuilder: (context, error, stackTrace) {
                usedErrorBuilder = true;
                return const Icon(Icons.smart_toy_outlined);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(usedErrorBuilder, isFalse);
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  }
}
