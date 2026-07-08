import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/upload_file_input.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import '../widgets/file_tile.dart';

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
      builder: (context, state) => _FilesBody(state: state),
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
          _UploadBar(isUploading: state.isUploading),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _FilesContent(state: state)),
        ],
      ),
    );
  }
}

class _UploadBar extends StatelessWidget {
  const _UploadBar({required this.isUploading});

  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: isUploading ? null : () => _pickAndUpload(context),
        icon: isUploading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file_outlined),
        label: Text(isUploading ? 'Wird hochgeladen' : 'Datei hochladen'),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final input = await _pickFile();
    if (!context.mounted || input == null) return;
    await context.read<FilesCubit>().upload(input);
  }

  Future<UploadFileInput?> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    final file = result?.files.firstOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return UploadFileInput(
      name: file.name,
      bytes: Uint8List.fromList(bytes),
      sizeBytes: file.size,
      contentType: _contentTypeFor(file.extension),
    );
  }

  String _contentTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'json' => 'application/json',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}

class _FilesContent extends StatelessWidget {
  const _FilesContent({required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      FilesLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      FilesLoadStatus.failure => _FailureState(message: state.message),
      FilesLoadStatus.ready when state.files.isEmpty => const _EmptyState(),
      FilesLoadStatus.ready => _FileList(state: state),
    };
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<FilesCubit>().load(),
      child: ListView.separated(
        itemCount: state.files.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => FileTile(file: state.files[index]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Noch keine Dateien hochgeladen.'));
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Dateien konnten nicht geladen werden.'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: context.read<FilesCubit>().load,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
