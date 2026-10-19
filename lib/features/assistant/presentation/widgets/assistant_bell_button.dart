import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/assistant_context.dart';
import '../cubits/assistant_cubit.dart';
import 'assistant_panel_dialog.dart';

class AssistantBellButton extends StatelessWidget {
  const AssistantBellButton({super.key, required this.contextInfo});

  final AssistantContext contextInfo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: LocaleKeys.ui_ki_agent_oeffnen.tr(),
      icon: const NooviImage(pose: NooviPose.wave, size: 28),
      onPressed: () => _openAssistant(context),
    );
  }

  Future<void> _openAssistant(BuildContext context) {
    return showIosDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) =>
            serviceLocator<AssistantCubit>()..setContext(contextInfo),
        child: const AssistantPanelDialog(),
      ),
    );
  }
}
