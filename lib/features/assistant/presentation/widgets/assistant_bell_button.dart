import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';

import '../../domain/entities/assistant_context.dart';
import '../cubits/assistant_cubit.dart';
import 'assistant_panel_dialog.dart';

class AssistantBellButton extends StatelessWidget {
  const AssistantBellButton({super.key, required this.contextInfo});

  final AssistantContext contextInfo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'KI-Agent öffnen',
      icon: const Icon(Icons.auto_awesome_outlined),
      onPressed: () => _openAssistant(context),
    );
  }

  Future<void> _openAssistant(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) =>
            serviceLocator<AssistantCubit>()..setContext(contextInfo),
        child: const AssistantPanelDialog(),
      ),
    );
  }
}
