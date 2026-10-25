import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/runtime_sessions_state.dart';
import 'revoke_other_sessions_button.dart';
import 'runtime_session_tile.dart';

/// Alle Geräte des eigenen Kontos, dieses Gerät eingeschlossen.
class RuntimeSessionList extends StatelessWidget {
  const RuntimeSessionList({super.key, required this.state});

  final RuntimeSessionsLoaded state;

  @override
  Widget build(BuildContext context) {
    final revoking = state.revoking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final session in state.sessions)
          RuntimeSessionTile(
            session: session,
            isRevoking:
                revoking is RevokingSession && revoking.id == session.id,
            canRevoke: !state.isBusy,
          ),
        if (!state.hasOtherSessions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              LocaleKeys.runtime_sessions_only_this_device.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        RevokeOtherSessionsButton(
          enabled: state.hasOtherSessions && !state.isBusy,
          isRevoking: revoking is RevokingOthers,
        ),
      ],
    );
  }
}
