import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/runtime_users_state.dart';

/// Zeigt einen Einladungscode genau einmal; die Runtime speichert ihn nur als
/// Hash und kann ihn später nicht wieder anzeigen.
Future<void> showRuntimeInvitationDialog(
  BuildContext context,
  IssuedInvitation issued,
) => showDialog<void>(
  context: context,
  builder: (_) => RuntimeInvitationDialog(issued: issued),
);

class RuntimeInvitationDialog extends StatelessWidget {
  const RuntimeInvitationDialog({super.key, required this.issued});

  final IssuedInvitation issued;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expiresAt = DateFormat.yMd(
      context.locale.toLanguageTag(),
    ).add_Hm().format(issued.invitation.expiresAt);
    return AlertDialog(
      title: Text(LocaleKeys.runtime_users_invitation_title.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.runtime_users_invitation_description.tr(
                args: [issued.displayName],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SelectableText(
              issued.invitation.code,
              style: textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.runtime_users_invitation_expires.tr(args: [expiresAt]),
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy_outlined),
          label: Text(LocaleKeys.runtime_users_invitation_copy.tr()),
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: issued.invitation.code)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.runtime_users_invitation_done.tr()),
        ),
      ],
    );
  }
}
