import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/runtime_users_cubit.dart';
import '../cubits/runtime_users_state.dart';
import 'runtime_invitation_dialog.dart';
import 'runtime_user_list.dart';
import 'runtime_user_texts.dart';

/// Einstellungen → Benutzer (nur Admins): Konten, Rollen und Einladungen.
class RuntimeUsersSettingsTab extends StatelessWidget {
  const RuntimeUsersSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<RuntimeUsersCubit>()..load(),
      child: const _RuntimeUsersNotices(child: _RuntimeUsersBody()),
    );
  }
}

/// Zeigt Codes, Fehler und Bestätigungen einmalig an.
class _RuntimeUsersNotices extends StatelessWidget {
  const _RuntimeUsersNotices({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RuntimeUsersCubit, RuntimeUsersState>(
      listenWhen: (_, state) =>
          state.failure != null ||
          state.confirmation != null ||
          state.issuedInvitation != null,
      listener: _show,
      child: child,
    );
  }

  Future<void> _show(BuildContext context, RuntimeUsersState state) async {
    final cubit = context.read<RuntimeUsersCubit>();
    cubit.noticeShown();
    final invitation = state.issuedInvitation;
    if (invitation != null) {
      await showRuntimeInvitationDialog(context, invitation);
      return;
    }
    final text = state.failure?.message ?? _confirmationText(state);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _confirmationText(RuntimeUsersState state) =>
      switch (state.confirmation) {
        RuntimeUsersConfirmation.roleChanged =>
          LocaleKeys.runtime_users_role_changed.tr(),
        _ => LocaleKeys.runtime_users_deleted.tr(),
      };
}

class _RuntimeUsersBody extends StatelessWidget {
  const _RuntimeUsersBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RuntimeUsersCubit, RuntimeUsersState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.overview != current.overview,
      builder: (context, state) => switch (state.status) {
        RuntimeUsersStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        RuntimeUsersStatus.failure => _LoadFailure(
          onRetry: context.read<RuntimeUsersCubit>().load,
        ),
        RuntimeUsersStatus.ready => RuntimeUserList(overview: state.overview),
      },
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.runtime_users_load_failed.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(LocaleKeys.runtime_users_retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
