import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/runtime_user.dart';
import '../cubits/current_runtime_user_cubit.dart';
import '../cubits/runtime_users_cubit.dart';
import 'add_runtime_user_dialog.dart';
import 'runtime_user_tile.dart';

/// Belegung, „Benutzer hinzufügen“ und die Konten.
class RuntimeUserList extends StatelessWidget {
  const RuntimeUserList({super.key, required this.overview});

  final RuntimeUserOverview overview;

  @override
  Widget build(BuildContext context) {
    final currentState = context.watch<CurrentRuntimeUserCubit>().state;
    final selfUid = currentState is CurrentRuntimeUserLoaded
        ? currentState.user.uid
        : null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _Header(overview: overview),
        const SizedBox(height: AppSpacing.md),
        if (overview.users.isEmpty)
          Text(LocaleKeys.runtime_users_empty.tr())
        else
          for (final user in overview.users)
            RuntimeUserTile(user: user, isSelf: user.uid == selfUid),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.overview});

  final RuntimeUserOverview overview;

  @override
  Widget build(BuildContext context) {
    final count = overview.users.length;
    final usage = overview.maxUsers == null
        ? LocaleKeys.runtime_users_usage_unlimited.tr(args: ['$count'])
        : LocaleKeys.runtime_users_usage.tr(
            args: ['$count', '${overview.maxUsers}'],
          );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(usage, style: Theme.of(context).textTheme.titleMedium),
        FilledButton.icon(
          icon: const Icon(Icons.person_add_alt_1_outlined),
          label: Text(LocaleKeys.runtime_users_add_action.tr()),
          onPressed: overview.isFull ? null : () => _add(context),
        ),
        if (overview.isFull) Text(LocaleKeys.runtime_users_limit_hint.tr()),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final cubit = context.read<RuntimeUsersCubit>();
    final user = await showAddRuntimeUserDialog(context);
    if (user != null) await cubit.create(user);
  }
}
