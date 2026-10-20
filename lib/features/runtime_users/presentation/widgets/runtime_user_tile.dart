import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/runtime_user.dart';
import '../cubits/runtime_users_cubit.dart';
import 'runtime_user_initials_avatar.dart';
import 'runtime_user_texts.dart';

enum _UserAction { makeAdmin, makeMember, resetPassword, delete }

/// Ein Konto in der Liste; das eigene Konto hat kein Menü.
class RuntimeUserTile extends StatelessWidget {
  const RuntimeUserTile({super.key, required this.user, required this.isSelf});

  final RuntimeUser user;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final details = [
      user.loginName,
      user.role.label,
      if (!user.hasPassword) LocaleKeys.runtime_users_invitation_pending.tr(),
      if (isSelf) LocaleKeys.runtime_users_you.tr(),
    ];
    return ListTile(
      leading: RuntimeUserInitialsAvatar(user: user),
      title: Text(user.displayName),
      subtitle: Text(details.join(' · ')),
      trailing: isSelf ? null : _UserMenu(user: user),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu({required this.user});

  final RuntimeUser user;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserAction>(
      tooltip: LocaleKeys.runtime_users_actions.tr(args: [user.displayName]),
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        if (user.role.isAdmin)
          _item(_UserAction.makeMember, LocaleKeys.runtime_users_make_member)
        else
          _item(_UserAction.makeAdmin, LocaleKeys.runtime_users_make_admin),
        _item(
          _UserAction.resetPassword,
          LocaleKeys.runtime_users_reset_password,
        ),
        _item(_UserAction.delete, LocaleKeys.runtime_users_delete),
      ],
    );
  }

  PopupMenuItem<_UserAction> _item(_UserAction action, String labelKey) =>
      PopupMenuItem(value: action, child: Text(labelKey.tr()));

  Future<void> _run(BuildContext context, _UserAction action) async {
    final cubit = context.read<RuntimeUsersCubit>();
    switch (action) {
      case _UserAction.makeAdmin:
        await cubit.changeRole(user, RuntimeRole.admin);
      case _UserAction.makeMember:
        await cubit.changeRole(user, RuntimeRole.member);
      case _UserAction.resetPassword:
        await cubit.resetPassword(user);
      case _UserAction.delete:
        if (await _confirmDelete(context)) await cubit.delete(user);
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.runtime_users_delete_title.tr()),
        content: Text(
          LocaleKeys.runtime_users_delete_message.tr(args: [user.displayName]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(LocaleKeys.runtime_users_cancel.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(LocaleKeys.runtime_users_delete.tr()),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
