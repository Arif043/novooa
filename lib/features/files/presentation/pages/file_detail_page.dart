import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/team_file.dart';
import '../cubits/file_detail_cubit.dart';
import '../cubits/file_detail_state.dart';
import '../widgets/file_content_editor.dart';
import '../widgets/file_version_timeline.dart';

class FileDetailPage extends StatelessWidget {
  const FileDetailPage({super.key, required this.file});

  final TeamFile file;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<FileDetailCubit>()..load(file),
      child: _FileDetailView(file: file),
    );
  }
}

class _FileDetailView extends StatelessWidget {
  const _FileDetailView({required this.file});

  final TeamFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(file.displayName)),
      body: BlocConsumer<FileDetailCubit, FileDetailState>(
        listenWhen: (previous, current) => current.message != previous.message,
        listener: _showMessage,
        builder: (_, state) => _FileDetailBody(file: file, state: state),
      ),
    );
  }

  void _showMessage(BuildContext context, FileDetailState state) {
    final message = state.message;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _FileDetailBody extends StatelessWidget {
  const _FileDetailBody({required this.file, required this.state});

  final TeamFile file;
  final FileDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == FileDetailStatus.failure) {
      return Center(
        child: Text(state.message ?? 'Datei konnte nicht geladen werden.'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? Row(
              children: [
                Expanded(
                  child: FileContentEditor(file: file, state: state),
                ),
                FileVersionTimeline(state: state),
              ],
            )
          : Column(
              children: [
                Expanded(
                  child: FileContentEditor(file: file, state: state),
                ),
                FileVersionTimeline(state: state),
              ],
            ),
    );
  }
}
