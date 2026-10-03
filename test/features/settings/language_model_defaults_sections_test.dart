import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_defaults_state.dart';
import 'package:syscat2/features/settings/presentation/widgets/language_model_defaults_sections.dart';

class _FakeCubit extends Cubit<LanguageModelDefaultsState>
    implements LanguageModelDefaultsCubit {
  _FakeCubit(super.state);

  final List<String?> savedBlock = [];
  final List<String?> savedKnowledgeAssistant = [];

  @override
  Future<void> saveBlockDefault(String? modelId) async =>
      savedBlock.add(modelId);

  @override
  Future<void> saveKnowledgeAssistantDefault(String? modelId) async =>
      savedKnowledgeAssistant.add(modelId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

LanguageModel _model(String id, String name, LanguageModelProvider provider) {
  return LanguageModel(
    id: id,
    name: name,
    modelId: name.toLowerCase(),
    supportsImageInput: false,
    supportsStructuredOutput: true,
    supportsImageGeneration: false,
    provider: provider,
  );
}

Widget _host(_FakeCubit cubit, {bool standalone = false}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<LanguageModelDefaultsCubit>.value(
          value: cubit,
          child: LanguageModelDefaultsSections(
            usedByKnowledgeAssistant: standalone,
          ),
        ),
      ),
    ),
  );
}

void main() {
  final models = [
    _model('g1', 'Gemini Flash', LanguageModelProvider.googleAi),
    _model('m1', 'Mistral Small', LanguageModelProvider.mistral),
  ];

  _FakeCubit cubitWith({String? block, bool saving = false}) {
    return _FakeCubit(
      LanguageModelDefaultsState(
        status: LanguageModelDefaultsStatus.ready,
        models: models,
        defaults: LanguageModelDefaults(blockModelId: block),
        isSavingBlockDefault: saving,
      ),
    );
  }

  testWidgets('zeigt die Systemvorgabe und das gewählte Modell mit Anbieter', (
    tester,
  ) async {
    await tester.pumpWidget(_host(cubitWith(block: 'g1')));

    expect(find.text('Gemini Flash · Google AI'), findsOneWidget);
    expect(find.text('Sprachmodell des Wissensbasis-Agenten'), findsNothing);
    expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
  });

  testWidgets('wählt Anbieter, dann Modell und speichert die Auswahl', (
    tester,
  ) async {
    final cubit = cubitWith();
    await tester.pumpWidget(_host(cubit));

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    expect(find.text('Systemvorgabe verwenden'), findsWidgets);
    await tester.tap(find.text('Mistral AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mistral Small'));
    await tester.pumpAndSettle();

    expect(cubit.savedBlock, ['m1']);
  });

  testWidgets('die Systemvorgabe wird als null gespeichert', (tester) async {
    final cubit = cubitWith(block: 'g1');
    await tester.pumpWidget(_host(cubit));

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Systemvorgabe verwenden').last);
    await tester.pumpAndSettle();

    expect(cubit.savedBlock, [null]);
  });

  testWidgets(
    'in der Runtime gibt es zusätzlich das Modell des Wissensbasis-Agenten',
    (tester) async {
      await tester.pumpWidget(_host(cubitWith(block: 'g1'), standalone: true));

      expect(
        find.text('Sprachmodell des Wissensbasis-Agenten'),
        findsOneWidget,
      );
      expect(find.byType(InputDecorator), findsNWidgets(2));
    },
  );

  testWidgets('das Modell des Wissensbasis-Agenten wird getrennt gespeichert', (
    tester,
  ) async {
    final cubit = cubitWith(block: 'g1');
    await tester.pumpWidget(_host(cubit, standalone: true));

    await tester.tap(find.byType(InputDecorator).last);
    await tester.pumpAndSettle();
    expect(find.text('Standardmodell verwenden'), findsWidgets);
    await tester.tap(find.text('Mistral AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mistral Small'));
    await tester.pumpAndSettle();

    expect(cubit.savedKnowledgeAssistant, ['m1']);
    expect(cubit.savedBlock, isEmpty);
  });

  testWidgets('beim Speichern ist die Auswahl gesperrt', (tester) async {
    await tester.pumpWidget(_host(cubitWith(saving: true)));

    await tester.tap(find.byType(InputDecorator).first);
    await tester.pumpAndSettle();

    expect(find.text('Mistral AI'), findsNothing);
  });

  testWidgets('ohne verbundene Modelle bleibt der Abschnitt ausgeblendet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _FakeCubit(
          const LanguageModelDefaultsState(
            status: LanguageModelDefaultsStatus.ready,
          ),
        ),
      ),
    );

    expect(find.byType(InputDecorator), findsNothing);
  });
}
