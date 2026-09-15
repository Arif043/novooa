import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_state.dart';

import 'settings_section.dart';
import 'ai_model_settings_tab.dart';
import 'runtime_license_status.dart';
import '../../../machine_learning/presentation/widgets/machine_learning_settings_tab.dart';

class RuntimeSettingsContent extends StatelessWidget {
  const RuntimeSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const _RuntimeSettingsTabs(),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: const [
                    _RuntimeSection(),
                    SizedBox(height: AppSpacing.lg),
                    _DeviceDataSection(),
                  ],
                ),
                const SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: AiModelSettingsTab(
                    scrollable: false,
                    isStandalone: true,
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

class _RuntimeSettingsTabs extends StatelessWidget {
  const _RuntimeSettingsTabs();

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
            0: _RuntimeSettingsTabLabel(
              icon: Icons.settings_outlined,
              label: 'Allgemein',
            ),
            1: _RuntimeSettingsTabLabel(
              icon: Icons.auto_awesome,
              label: 'Sprachmodelle',
            ),
            2: _RuntimeSettingsTabLabel(
              icon: Icons.memory_outlined,
              label: 'Machine Learning',
            ),
          },
        ),
      ),
    );
  }
}

class _RuntimeSettingsTabLabel extends StatelessWidget {
  const _RuntimeSettingsTabLabel({required this.icon, required this.label});

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

class _RuntimeSection extends StatelessWidget {
  const _RuntimeSection();

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.dns_outlined,
      title: 'Runtime',
      description: 'Status und Lizenz dieser novooa-Installation.',
      child: BlocBuilder<RuntimeLicenseCubit, RuntimeLicenseCubitState>(
        builder: (context, state) => switch (state) {
          RuntimeLicenseLoading() ||
          RuntimeLicenseActivating() ||
          RuntimeLicenseReleasing() => const LinearProgressIndicator(),
          RuntimeLicenseActive(:final status) => RuntimeLicenseStatusContent(
            status: status,
          ),
          RuntimeLicenseNeedsActivation() || RuntimeLicenseFailureState() =>
            const Text('Die Runtime ist nicht aktiviert.'),
        },
      ),
    );
  }
}

class _DeviceDataSection extends StatelessWidget {
  const _DeviceDataSection();

  @override
  Widget build(BuildContext context) {
    return const SettingsSection(
      icon: Icons.storage_outlined,
      title: 'Gerätedaten',
      description:
          'Daten und Anwendungsprotokolle werden auf diesem Gerät verwaltet.',
      child: Text(
        'Daten und Protokolle liegen in einer SQLite-Datenbank auf diesem Gerät.',
      ),
    );
  }
}
