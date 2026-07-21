import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/file_version.dart';
import '../cubits/file_detail_cubit.dart';
import '../cubits/file_detail_state.dart';

class FileVersionTimeline extends StatelessWidget {
  const FileVersionTimeline({super.key, required this.state});

  final FileDetailState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Versionen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(child: _VersionList(state: state)),
        ],
      ),
    );
  }
}

class _VersionList extends StatelessWidget {
  const _VersionList({required this.state});
  final FileDetailState state;

  @override
  Widget build(BuildContext context) {
    if (state.versions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: state.versions.length,
      itemBuilder: (context, index) => _VersionTile(
        version: state.versions[index],
        isSelected: state.selectedVersion?.id == state.versions[index].id,
      ),
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile({required this.version, required this.isSelected});
  final FileVersion version;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final date = version.createdAt;
    return ListTile(
      selected: isSelected,
      leading: Icon(isSelected ? Icons.history_toggle_off : Icons.history),
      title: Text(isSelected ? 'Aktueller Stand' : 'Frühere Version'),
      subtitle: Text(
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      ),
      onTap: () => context.read<FileDetailCubit>().selectVersion(version),
    );
  }
}
