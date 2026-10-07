import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/runtime_sessions_cubit.dart';
import '../cubits/runtime_sessions_state.dart';

/// Meldet alle anderen Geräte von dieser Runtime ab — etwa nach dem Verlust
/// eines Geräts. Die eigene Sitzung bleibt bestehen.
class RuntimeSessionsSection extends StatelessWidget {
  const RuntimeSessionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RuntimeSessionsCubit, RuntimeSessionsState>(
      listener: _showResult,
      builder: (context, state) => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: state is RuntimeSessionsRevoking
                ? null
                : () => _confirmRevoke(context),
            icon: const Icon(Icons.devices_other_outlined),
            label: const Text('Andere Geräte abmelden'),
          ),
          if (state is RuntimeSessionsRevoking)
            const SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  void _showResult(BuildContext context, RuntimeSessionsState state) {
    final message = switch (state) {
      RuntimeSessionsRevoked(:final count) => _revokedMessage(count),
      RuntimeSessionsFailed(:final message) => message,
      RuntimeSessionsIdle() || RuntimeSessionsRevoking() => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _revokedMessage(int count) => switch (count) {
    0 => 'Es waren keine anderen Geräte angemeldet.',
    1 => '1 anderes Gerät wurde abgemeldet.',
    _ => '$count andere Geräte wurden abgemeldet.',
  };

  Future<void> _confirmRevoke(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Andere Geräte abmelden?'),
        content: const Text(
          'Alle anderen Geräte müssen sich danach mit dem Passwort neu anmelden. '
          'Dieses Gerät bleibt angemeldet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<RuntimeSessionsCubit>().revokeOtherSessions();
    }
  }
}
