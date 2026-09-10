import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_state.dart';

import 'settings_section.dart';
import 'ai_model_settings_tab.dart';

class LocalSettingsContent extends StatelessWidget {
  const LocalSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        _LocalRuntimeSection(),
        SizedBox(height: AppSpacing.lg),
        AiModelSettingsTab(scrollable: false, localRuntime: true),
        SizedBox(height: AppSpacing.lg),
        _LocalDataSection(),
      ],
    );
  }
}

class _LocalRuntimeSection extends StatelessWidget {
  const _LocalRuntimeSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.dns_outlined,
      title: 'Lokale Runtime',
      description: 'Status und Lizenz der lokal ausgeführten novooa-Umgebung.',
      child:
          BlocBuilder<LocalRuntimeLicenseCubit, LocalRuntimeLicenseCubitState>(
            builder: (context, state) => switch (state) {
              LocalRuntimeLicenseLoading() || LocalRuntimeLicenseActivating() =>
                const LinearProgressIndicator(),
              LocalRuntimeLicenseActive(:final status) => _LicenseStatus(
                expiresAt: status.expiresAt,
              ),
              LocalRuntimeLicenseNeedsActivation() ||
              LocalRuntimeLicenseFailureState() => const Text(
                'Die lokale Runtime ist nicht aktiviert.',
              ),
            },
          ),
    );
  }
}

class _LicenseStatus extends StatelessWidget {
  const _LicenseStatus({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final date = expiresAt;
    final expiresText = date == null
        ? 'Unbefristet aktiv'
        : 'Aktiv bis ${_dateLabel(date)}';
    return Row(
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

class _LocalDataSection extends StatelessWidget {
  const _LocalDataSection();

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      icon: Icons.storage_outlined,
      title: 'Lokale Daten',
      description:
          'Daten und Anwendungsprotokolle werden auf diesem Gerät verwaltet.',
      child: Text(
        'Die lokale Runtime nutzt SQLite für Aufgaben, Aktivitäten, Dateien und Protokolle.',
      ),
    );
  }
}
