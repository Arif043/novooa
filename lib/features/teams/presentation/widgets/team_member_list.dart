import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_member.dart';
import '../cubits/team_settings_cubit.dart';
import '../cubits/team_settings_state.dart';

class TeamMemberList extends StatelessWidget {
  const TeamMemberList({required this.state, super.key});

  final TeamSettingsState state;

  @override
  Widget build(BuildContext context) {
    if (state.members.isEmpty) {
      return const Text('Noch keine Mitglieder vorhanden.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mitglieder', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final member in state.members)
          _TeamMemberTile(member: member, state: state),
      ],
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.member, required this.state});

  final TeamMember member;
  final TeamSettingsState state;

  @override
  Widget build(BuildContext context) {
    final isRemoving = state.removingMemberUid == member.uid;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(member.uid),
      subtitle: Text(member.role.label),
      trailing: member.role == TeamMemberRole.owner
          ? null
          : IconButton(
              tooltip: 'Mitglied entfernen',
              onPressed: isRemoving ? null : () => _remove(context),
              icon: isRemoving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_remove_outlined),
            ),
    );
  }

  void _remove(BuildContext context) {
    context.read<TeamSettingsCubit>().removeMember(member.uid);
  }
}
