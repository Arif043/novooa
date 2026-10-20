import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/runtime_user.dart';
import 'runtime_user_texts.dart';

/// Fragt Name, Anmeldename und Rolle eines neuen Kontos ab.
Future<NewRuntimeUser?> showAddRuntimeUserDialog(BuildContext context) =>
    showDialog<NewRuntimeUser>(
      context: context,
      builder: (_) => const AddRuntimeUserDialog(),
    );

class AddRuntimeUserDialog extends StatefulWidget {
  const AddRuntimeUserDialog({super.key});

  @override
  State<AddRuntimeUserDialog> createState() => _AddRuntimeUserDialogState();
}

class _AddRuntimeUserDialogState extends State<AddRuntimeUserDialog> {
  final _nameController = TextEditingController();
  final _loginNameController = TextEditingController();
  RuntimeRole _role = RuntimeRole.member;

  @override
  void dispose() {
    _nameController.dispose();
    _loginNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.runtime_users_add_title.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: LocaleKeys.runtime_access_display_name.tr(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _loginNameController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: LocaleKeys.runtime_access_login_name.tr(),
                helperText: LocaleKeys.runtime_users_login_name_hint.tr(),
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<RuntimeRole>(
              segments: [
                for (final role in RuntimeRole.values)
                  ButtonSegment(value: role, label: Text(role.label)),
              ],
              selected: {_role},
              onSelectionChanged: (roles) =>
                  setState(() => _role = roles.single),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.runtime_users_cancel.tr()),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(LocaleKeys.runtime_users_add_action.tr()),
        ),
      ],
    );
  }

  void _submit() => Navigator.of(context).pop(
    NewRuntimeUser(
      displayName: _nameController.text,
      loginName: _loginNameController.text,
      role: _role,
    ),
  );
}
