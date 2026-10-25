import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/runtime_sessions_cubit.dart';
import 'confirm_sign_out_dialog.dart';

/// Meldet alle anderen Geräte ab, etwa nach dem Verlust eines Geräts.
class RevokeOtherSessionsButton extends StatelessWidget {
  const RevokeOtherSessionsButton({
    super.key,
    required this.enabled,
    required this.isRevoking,
  });

  final bool enabled;
  final bool isRevoking;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: enabled && !isRevoking
              ? () => _confirmAndRevoke(context)
              : null,
          icon: const Icon(Icons.devices_other_outlined),
          label: Text(LocaleKeys.runtime_sessions_revoke_others.tr()),
        ),
        if (isRevoking)
          const SizedBox.square(
            dimension: AppSpacing.md,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }

  Future<void> _confirmAndRevoke(BuildContext context) async {
    final confirmed = await confirmSignOut(
      context,
      title: LocaleKeys.runtime_sessions_revoke_others_title.tr(),
      message: LocaleKeys.runtime_sessions_revoke_others_message.tr(),
    );
    if (confirmed && context.mounted) {
      await context.read<RuntimeSessionsCubit>().revokeOthers();
    }
  }
}
