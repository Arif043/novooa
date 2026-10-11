import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/communication/presentation/widgets/communication_settings_tab.dart';
import 'package:syscat2/features/teams/presentation/widgets/team_settings_tab.dart';

import '../cubits/settings_state.dart';
import 'adaptive_settings_tabs.dart';
import 'ai_model_settings_tab.dart';
import 'profile_settings_tab.dart';
import 'settings_tab_contribution.dart';

/// Einstellungen der Cloud-Variante.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSettingsTabs(tabs: _cloudSettingsTabs());
  }

  List<SettingsTabContribution> _cloudSettingsTabs() => [
    _padded(
      CupertinoIcons.person_crop_circle,
      LocaleKeys.settings_tabs_profile,
      ProfileSettingsTab(state: state),
    ),
    _padded(
      CupertinoIcons.person_2,
      LocaleKeys.settings_tabs_team,
      const TeamSettingsTab(),
    ),
    _padded(
      CupertinoIcons.sparkles,
      LocaleKeys.settings_tabs_language_model,
      const AiModelSettingsTab(),
    ),
    _padded(
      CupertinoIcons.chat_bubble_2,
      LocaleKeys.settings_tabs_communication,
      const CommunicationSettingsTab(),
    ),
  ];

  SettingsTabContribution _padded(IconData icon, String labelKey, Widget tab) {
    return SettingsTabContribution(
      icon: icon,
      labelKey: labelKey,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: tab,
      ),
    );
  }
}
