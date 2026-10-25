import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';
import 'package:syscat2/features/google_accounts/presentation/widgets/google_accounts_section.dart';
import 'package:syscat2/features/settings/presentation/widgets/settings_section.dart';

import '../../domain/entities/connection.dart';
import '../cubits/connections_cubit.dart';
import '../cubits/connections_state.dart';
import 'connection_editor_dialog.dart';

/// Tab „Verbindungen“ in den Runtime-Einstellungen: HTTP-Verbindungen und
/// Google-Konten.
class ConnectionsSettingsTab extends StatelessWidget {
  const ConnectionsSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<ConnectionsCubit>()..load()),
        BlocProvider(
          create: (_) => serviceLocator<GoogleAccountsCubit>()..load(),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _ConnectionsSection(),
          SizedBox(height: AppSpacing.lg),
          GoogleAccountsSection(),
        ],
      ),
    );
  }
}

class _ConnectionsSection extends StatelessWidget {
  const _ConnectionsSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.link,
      title: 'Verbindungen',
      description:
          'Zugänge zu externen Systemen, z. B. einem Shop. Aufgaben nutzen sie '
          'im Baustein „HTTP-Anfrage“. Die Zugangsdaten bleiben in dieser '
          'Runtime und werden nie angezeigt.',
      child: BlocConsumer<ConnectionsCubit, ConnectionsState>(
        listenWhen: (previous, current) =>
            current.message != null && current.message != previous.message,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
          context.read<ConnectionsCubit>().messageShown();
        },
        builder: (context, state) {
          final cubit = context.read<ConnectionsCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.status == ConnectionsStatus.loading)
                const LinearProgressIndicator()
              else if (state.connections.isEmpty)
                const Text('Noch keine Verbindungen angelegt.')
              else
                for (final connection in state.connections)
                  _ConnectionTile(connection: connection, cubit: cubit),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Verbindung hinzufügen'),
                onPressed: () =>
                    ConnectionEditorDialog.show(context, cubit: cubit),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.connection, required this.cubit});

  final Connection connection;
  final ConnectionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.link),
      title: Text(connection.name),
      subtitle: Text('${connection.baseUrl} · ${connection.auth.label}'),
      onTap: () => ConnectionEditorDialog.show(
        context,
        cubit: cubit,
        existing: connection,
      ),
      trailing: IconButton(
        tooltip: 'Verbindung löschen',
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('„${connection.name}“ löschen?'),
        content: const Text(
          'Bausteine, die diese Verbindung nutzen, schlagen danach fehl, bis '
          'du eine andere Verbindung wählst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete(connection.id);
  }
}
