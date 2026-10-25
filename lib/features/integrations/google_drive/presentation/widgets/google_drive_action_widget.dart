import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_state.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

import '../../domain/google_drive_actions.dart';
import '../../domain/google_drive_node_config.dart';
import 'google_account_picker_field.dart';
import 'google_drive_read_fields.dart';
import 'google_drive_upload_fields.dart';

/// Formular einer Drive-Aktion: Konto und die Eingaben der Aktion. Erwartet
/// einen [GoogleAccountsCubit] im Kontext.
class GoogleDriveActionWidget extends StatelessWidget {
  const GoogleDriveActionWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as GoogleDriveNodeConfig;
    final spec = GoogleDriveActions.byId(config.action);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spec?.titleKey.tr() ?? 'Google Drive',
            style: SyscatTheme.taskBody,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (spec == null)
            Text(LocaleKeys.google_drive_unknown_action.tr())
          else
            _ActionFields(node: node, config: config, spec: spec),
        ],
      ),
    );
  }
}

class _ActionFields extends StatelessWidget {
  const _ActionFields({
    required this.node,
    required this.config,
    required this.spec,
  });

  final WorkflowNode node;
  final GoogleDriveNodeConfig config;
  final GoogleDriveActionSpec spec;

  @override
  Widget build(BuildContext context) {
    final accounts = _accountsOf(context.watch<GoogleAccountsCubit>().state);
    final account = _selected(accounts);
    void update(GoogleDriveNodeConfig Function(GoogleDriveNodeConfig) change) =>
        updateGoogleDriveNode(context, node.id, change);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoogleAccountPickerField(
          selectedId: config.accountId,
          accounts: accounts,
          onChanged: (id) => update((c) => c.withAccount(id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (spec == GoogleDriveActions.upload)
          GoogleDriveUploadFields(
            config: config,
            account: account,
            update: update,
          )
        else
          GoogleDriveReadFields(
            config: config,
            account: account,
            update: update,
          ),
      ],
    );
  }

  List<GoogleAccount> _accountsOf(GoogleAccountsState state) =>
      state is GoogleAccountsLoaded ? state.accounts : const [];

  GoogleAccount? _selected(List<GoogleAccount> accounts) {
    for (final account in accounts) {
      if (account.id == config.accountId) return account;
    }
    return null;
  }
}

typedef GoogleDriveNodeUpdate =
    void Function(GoogleDriveNodeConfig Function(GoogleDriveNodeConfig) change);

void updateGoogleDriveNode(
  BuildContext context,
  NodeId nodeId,
  GoogleDriveNodeConfig Function(GoogleDriveNodeConfig config) change,
) {
  context.read<TaskBuilderCubit>().updatePluginNode(nodeId, (config) {
    return config is GoogleDriveNodeConfig ? change(config) : config;
  });
}
