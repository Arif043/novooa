import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../domain/entities/runtime_session.dart';
import '../cubits/runtime_sessions_cubit.dart';
import 'confirm_sign_out_dialog.dart';
import 'runtime_session_texts.dart';

/// Ein angemeldetes Gerät: was es ist, seit wann und wann zuletzt aktiv.
class RuntimeSessionTile extends StatelessWidget {
  const RuntimeSessionTile({
    super.key,
    required this.session,
    required this.isRevoking,
    required this.canRevoke,
  });

  final RuntimeSession session;
  final bool isRevoking;

  /// Während eine andere Abmeldung läuft, bleibt der Button gesperrt.
  final bool canRevoke;

  @override
  Widget build(BuildContext context) {
    final device = session.device;
    final details = [
      session.signedInText(Localizations.localeOf(context)),
      session.lastActiveText(DateTime.now()),
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(device.icon, semanticLabel: device.label),
      title: Text(device.label),
      subtitle: Text(details),
      trailing: session.isCurrent
          ? Chip(label: Text(LocaleKeys.runtime_sessions_this_device.tr()))
          : _RevokeButton(
              session: session,
              isRevoking: isRevoking,
              enabled: canRevoke,
            ),
    );
  }
}

class _RevokeButton extends StatelessWidget {
  const _RevokeButton({
    required this.session,
    required this.isRevoking,
    required this.enabled,
  });

  final RuntimeSession session;
  final bool isRevoking;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (isRevoking) {
      return const SizedBox.square(
        dimension: kMinInteractiveDimension,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      tooltip: LocaleKeys.runtime_sessions_revoke.tr(
        args: [session.device.label],
      ),
      icon: const Icon(Icons.logout),
      onPressed: enabled ? () => _confirmAndRevoke(context) : null,
    );
  }

  Future<void> _confirmAndRevoke(BuildContext context) async {
    final confirmed = await confirmSignOut(
      context,
      title: LocaleKeys.runtime_sessions_revoke_title.tr(),
      message: LocaleKeys.runtime_sessions_revoke_message.tr(
        args: [session.device.label],
      ),
    );
    if (confirmed && context.mounted) {
      await context.read<RuntimeSessionsCubit>().revoke(session);
    }
  }
}
