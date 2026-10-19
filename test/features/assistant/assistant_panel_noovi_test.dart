import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';
import 'package:syscat2/core/widgets/noovi/noovi_thinking.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:syscat2/features/assistant/domain/usecases/ask_assistant.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_panel_dialog.dart';

class _PendingRepository implements AssistantRepository {
  final answer = Completer<AssistantMessage>();

  @override
  Future<AssistantMessage> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) => answer.future;
}

Finder _noovi(NooviPose pose) => find.byWidgetPredicate(
  (widget) => widget is NooviImage && widget.pose == pose,
);

Future<_PendingRepository> _pumpPanel(WidgetTester tester) async {
  final repository = _PendingRepository();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider(
          create: (_) => AssistantCubit(
            askAssistant: AskAssistant(repository),
            context: const AssistantContext(
              area: AssistantArea.general,
              route: '/',
            ),
          ),
          child: AssistantPanel(onClose: () {}),
        ),
      ),
    ),
  );
  return repository;
}

void main() {
  testWidgets('Noovi greets in the empty panel and heads it', (tester) async {
    await _pumpPanel(tester);

    expect(_noovi(NooviPose.wave), findsNWidgets(2));
  });

  testWidgets('Noovi thinks while the agent works and answers as avatar', (
    tester,
  ) async {
    final repository = await _pumpPanel(tester);

    await tester.enterText(find.byType(TextField), 'Was kann ich tun?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.byType(NooviThinking), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      _noovi(NooviPose.present),
      findsNothing,
      reason: 'no avatar on user messages',
    );

    repository.answer.complete(AssistantMessage.agent('Eine Aufgabe bauen.'));
    await tester.pump();

    expect(find.byType(NooviThinking), findsNothing);
    expect(_noovi(NooviPose.present), findsOneWidget);
  });
}
