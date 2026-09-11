import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_state.dart';

import 'settings_section.dart';
import 'ai_model_settings_tab.dart';
import '../../../machine_learning/presentation/widgets/machine_learning_settings_tab.dart';

class LocalSettingsContent extends StatelessWidget {
  const LocalSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const _LocalSettingsTabs(),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: const [
                    _LocalRuntimeSection(),
                    SizedBox(height: AppSpacing.lg),
                    _LocalDataSection(),
                  ],
                ),
                const SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AiModelSettingsTab(
                    scrollable: false,
                    localRuntime: true,
                  ),
                ),
                const MachineLearningSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalSettingsTabs extends StatelessWidget {
  const _LocalSettingsTabs();

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: controller.index,
          onValueChanged: (selection) {
            if (selection != null) controller.animateTo(selection);
          },
          children: const {
            0: _LocalSettingsTabLabel(
              icon: Icons.settings_outlined,
              label: 'Allgemein',
            ),
            1: _LocalSettingsTabLabel(
              icon: Icons.auto_awesome,
              label: 'Sprachmodelle',
            ),
            2: _LocalSettingsTabLabel(
              icon: Icons.memory_outlined,
              label: 'Machine Learning',
            ),
          },
        ),
      ),
    );
  }
}

class _LocalSettingsTabLabel extends StatelessWidget {
  const _LocalSettingsTabLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: AppSpacing.sm),
        Text(label),
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
