import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/licensing/domain/entities/runtime_license.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_cubit.dart';

class RuntimeLicenseStatusContent extends StatelessWidget {
  const RuntimeLicenseStatusContent({required this.status, super.key});

  final RuntimeLicenseStatus status;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LicenseExpiry(expiresAt: status.expiresAt),
        OutlinedButton.icon(
          onPressed: () => _confirmRelease(context),
          icon: const Icon(Icons.link_off_outlined),
          label: const Text('Lizenz entfernen'),
        ),
      ],
    );
  }

  Future<void> _confirmRelease(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lizenz entfernen?'),
        content: const Text(
          'Diese Runtime verliert den Zugriff. Der Lizenzschlüssel kann danach auf einer anderen Runtime aktiviert werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Lizenz entfernen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<RuntimeLicenseCubit>().release();
    }
  }
}

class _LicenseExpiry extends StatelessWidget {
  const _LicenseExpiry({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final expiresText = expiresAt == null
        ? 'Unbefristet aktiv'
        : 'Aktiv bis ${_dateLabel(expiresAt!)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(expiresText),
      ],
    );
  }

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }
}
