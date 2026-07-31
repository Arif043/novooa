import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../settings/presentation/widgets/settings_section.dart';
import '../cubits/team_settings_cubit.dart';
import '../cubits/team_settings_state.dart';
import 'add_team_member_form.dart';
import 'team_id_display.dart';
import 'team_member_list.dart';

class TeamSettingsTab extends StatefulWidget {
  const TeamSettingsTab({super.key});

  @override
  State<TeamSettingsTab> createState() => _TeamSettingsTabState();
}

class _TeamSettingsTabState extends State<TeamSettingsTab>
    with AutomaticKeepAliveClientMixin {
  late final TeamSettingsCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<TeamSettingsCubit>()..load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(value: _cubit, child: const _TeamSettingsView());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }
}

class _TeamSettingsView extends StatelessWidget {
  const _TeamSettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamSettingsCubit, TeamSettingsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) {
        return switch (state.status) {
          TeamSettingsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          TeamSettingsStatus.failure => _FailureState(
            onRetry: context.read<TeamSettingsCubit>().load,
          ),
          TeamSettingsStatus.ready => _ReadyTeamSettings(state: state),
        };
      },
    );
  }

  void _showMessage(BuildContext context, TeamSettingsState state) {
    final message = state.message;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReadyTeamSettings extends StatelessWidget {
  const _ReadyTeamSettings({required this.state});

  final TeamSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.team == null) return const _EmptyState();
    return SingleChildScrollView(
      child: SettingsSection(
        icon: Icons.groups_outlined,
        title: 'Team',
        description: 'Verwalte deinen Arbeitsbereich und seine Mitglieder.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: ValueKey(state.team!.id),
              initialValue: state.nameInput,
              enabled: !state.isSaving,
              decoration: const InputDecoration(labelText: 'Teamname'),
              onChanged: context.read<TeamSettingsCubit>().updateName,
            ),
            const SizedBox(height: AppSpacing.md),
            TeamIdDisplay(teamId: state.team!.id),
            const SizedBox(height: AppSpacing.lg),
            AddTeamMemberForm(state: state),
            const SizedBox(height: AppSpacing.lg),
            TeamMemberList(state: state),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: state.isSaving
                    ? null
                    : context.read<TeamSettingsCubit>().saveName,
                icon: state.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Team speichern'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Kein Team gefunden.'));
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Team erneut laden'),
      ),
    );
  }
}
