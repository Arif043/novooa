import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/team_settings_cubit.dart';
import '../cubits/team_settings_state.dart';

class AddTeamMemberForm extends StatefulWidget {
  const AddTeamMemberForm({required this.state, super.key});

  final TeamSettingsState state;

  @override
  State<AddTeamMemberForm> createState() => _AddTeamMemberFormState();
}

class _AddTeamMemberFormState extends State<AddTeamMemberForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.memberInput);
  }

  @override
  void didUpdateWidget(AddTeamMemberForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.memberInput.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mitglied hinzufügen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                enabled: !state.isAddingMember,
                decoration: const InputDecoration(
                  labelText: 'Nutzer-ID oder E-Mail',
                ),
                onChanged: context.read<TeamSettingsCubit>().updateMemberInput,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: state.isAddingMember
                  ? null
                  : context.read<TeamSettingsCubit>().addMember,
              icon: state.isAddingMember
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Hinzufügen'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
