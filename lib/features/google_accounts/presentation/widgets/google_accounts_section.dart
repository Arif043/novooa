import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/settings/presentation/widgets/settings_section.dart';

import '../cubits/google_accounts_cubit.dart';
import '../cubits/google_accounts_state.dart';
import 'google_account_tile.dart';
import 'google_authorization_launcher.dart';

/// Abschnitt „Google-Konten“ im Tab „Verbindungen“. Erwartet einen
/// [GoogleAccountsCubit] im Kontext.
class GoogleAccountsSection extends StatelessWidget {
  const GoogleAccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.add_to_drive,
      title: LocaleKeys.google_drive_section_title.tr(),
      description: LocaleKeys.google_drive_section_description.tr(),
      child: BlocBuilder<GoogleAccountsCubit, GoogleAccountsState>(
        builder: (context, state) => switch (state) {
          GoogleAccountsLoading() => const LinearProgressIndicator(),
          GoogleAccountsFailure() => const _LoadFailure(),
          GoogleAccountsLoaded(accounts: final accounts) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (accounts.isEmpty)
                Text(LocaleKeys.google_drive_empty.tr())
              else
                for (final account in accounts)
                  GoogleAccountTile(account: account),
              const SizedBox(height: AppSpacing.md),
              const _ConnectButton(),
            ],
          ),
        },
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: Text(LocaleKeys.google_drive_connect.tr()),
      onPressed: () => startGoogleAuthorization(context),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(LocaleKeys.google_drive_load_failed.tr())),
        TextButton(
          onPressed: () => context.read<GoogleAccountsCubit>().load(),
          child: Text(LocaleKeys.google_drive_retry.tr()),
        ),
      ],
    );
  }
}
