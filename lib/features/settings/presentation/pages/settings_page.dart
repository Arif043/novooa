import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../widgets/settings_content.dart';
import '../widgets/settings_filter_tabs.dart';
import '../widgets/runtime_settings_content.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.isStandalone = false});

  final bool isStandalone;

  @override
  Widget build(BuildContext context) {
    if (isStandalone) return const RuntimeSettingsContent();
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
      length: 4,
      child: _SettingsLayout(state: state),
    );
  }
}

class _SettingsLayout extends StatelessWidget {
  const _SettingsLayout({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SettingsFilterTabs(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: SettingsContent(state: state),
          ),
        ),
      ],
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
