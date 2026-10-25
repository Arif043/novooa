import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/runtime_sessions_cubit.dart';
import '../cubits/runtime_sessions_state.dart';
import 'runtime_session_list.dart';
import 'runtime_session_texts.dart';

/// Angemeldete Geräte mit Laden, Fehler und Liste. Leer kann die Liste nicht
/// sein, weil dieses Gerät immer dazugehört; dann gilt sie als Fehler.
class RuntimeSessionsSection extends StatelessWidget {
  const RuntimeSessionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RuntimeSessionsCubit, RuntimeSessionsState>(
      listenWhen: (_, current) =>
          current is RuntimeSessionsLoaded && current.notice != null,
      listener: _showNotice,
      builder: (context, state) => switch (state) {
        RuntimeSessionsLoading() => Semantics(
          label: LocaleKeys.runtime_sessions_loading.tr(),
          child: const LinearProgressIndicator(),
        ),
        RuntimeSessionsLoaded(:final sessions) when sessions.isEmpty =>
          const _LoadFailure(),
        RuntimeSessionsLoaded() => RuntimeSessionList(state: state),
        RuntimeSessionsLoadFailed() => const _LoadFailure(),
      },
    );
  }

  void _showNotice(BuildContext context, RuntimeSessionsState state) {
    final notice = (state as RuntimeSessionsLoaded).notice;
    final message = switch (notice) {
      SessionRevokedNotice() => LocaleKeys.runtime_sessions_revoked.tr(),
      OthersRevokedNotice(count: 0) =>
        LocaleKeys.runtime_sessions_others_revoked_none.tr(),
      OthersRevokedNotice(count: 1) =>
        LocaleKeys.runtime_sessions_others_revoked_one.tr(),
      OthersRevokedNotice(:final count) =>
        LocaleKeys.runtime_sessions_others_revoked_many.tr(args: ['$count']),
      RevokeFailedNotice(:final failure) => failure.text,
      null => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(LocaleKeys.runtime_sessions_load_failed.tr()),
        OutlinedButton.icon(
          onPressed: context.read<RuntimeSessionsCubit>().load,
          icon: const Icon(Icons.refresh),
          label: Text(LocaleKeys.runtime_sessions_retry.tr()),
        ),
      ],
    );
  }
}
