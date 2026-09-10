import 'package:flutter/material.dart';
import 'package:syscat2/features/communication/presentation/widgets/communication_settings_tab.dart';
import 'package:syscat2/features/teams/presentation/widgets/team_settings_tab.dart';

import '../cubits/settings_state.dart';
import 'ai_model_settings_tab.dart';
import 'profile_settings_tab.dart';

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        ProfileSettingsTab(state: state),
        const TeamSettingsTab(),
        const AiModelSettingsTab(),
        const CommunicationSettingsTab(),
      ],
    );
  }
}
