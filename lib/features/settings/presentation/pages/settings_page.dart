import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../widgets/ai_model_settings_tab.dart';
import '../widgets/profile_settings_tab.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<SettingsCubit>()..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) {
        return previous.message != current.message && current.message != null;
      },
      listener: _showMessage,
      builder: (context, state) => _SettingsBody(state: state),
    );
  }

  void _showMessage(BuildContext context, SettingsState state) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.message!)));
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.loadStatus) {
      SettingsLoadStatus.loading => const _LoadingState(),
      SettingsLoadStatus.failure => _FailureState(message: state.message),
      SettingsLoadStatus.ready => _ReadySettings(state: state),
    };
  }
}

class _ReadySettings extends StatelessWidget {
  const _ReadySettings({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SettingsTabs(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                children: [
                  ProfileSettingsTab(state: state),
                  AiModelSettingsTab(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.person_outline), text: 'Profil'),
          Tab(icon: Icon(Icons.auto_awesome), text: 'Sprachmodell'),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'Einstellungen konnten nicht geladen werden.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: context.read<SettingsCubit>().load,
              icon: const Icon(Icons.refresh),
              label: Text('Erneut versuchen', style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
