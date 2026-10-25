import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../app/dashboard_theme.dart';
import '../l10n/dashboard_keys.dart';

/// Lizenz, Ersteinrichtung und Notzugang gehören ins offizielle Frontend.
class SetupRequiredNotice extends StatelessWidget {
  const SetupRequiredNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size: Spacing.xl * 2,
          color: theme.colorScheme.primary,
          semanticLabel: DashboardKeys.connectionSetupRequired.tr(),
        ),
        const SizedBox(height: Spacing.md),
        Text(
          DashboardKeys.connectionSetupRequired.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
