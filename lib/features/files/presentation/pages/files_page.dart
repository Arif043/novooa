import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import '../widgets/files_action_bar.dart';
import '../widgets/files_content.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<FilesCubit>()..load(),
      child: const _FilesView(),
    );
  }
}

class _FilesView extends StatelessWidget {
  const _FilesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FilesCubit, FilesState>(
      listenWhen: (previous, current) => current.message != previous.message,
      listener: _showMessage,
      builder: (_, state) => _FilesBody(state: state),
    );
  }

  void _showMessage(BuildContext context, FilesState state) {
    final message = state.message;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FilesBody extends StatelessWidget {
  const _FilesBody({required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilesActionBar(state: state),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: FilesContent(state: state)),
        ],
      ),
    );
  }
}
