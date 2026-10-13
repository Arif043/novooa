import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/page_insets.dart';
import '../../../../core/theme/luminous_page_theme.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import '../widgets/files_content.dart';
import '../widgets/files_header.dart';
import '../widgets/files_initial_state.dart';

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

/// Gleiches Seitenlayout wie der Zeitplan: ruhiger Grund, mittige Spalte,
/// Kopfzeile mit Aktionen rechts und Einträge als Karten.
class _FilesView extends StatelessWidget {
  const _FilesView();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LuminousPageTheme.from(Theme.of(context)),
      child: Builder(
        builder: (context) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: SafeArea(
            child: BlocConsumer<FilesCubit, FilesState>(
              listenWhen: (previous, current) =>
                  current.message != previous.message,
              listener: _showMessage,
              builder: (_, state) => _FilesBody(state: state),
            ),
          ),
        ),
      ),
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
    if (state.isInitial) {
      return FilesInitialState(isUploading: state.isUploading);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = PageInsets.forWidth(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () async => context.read<FilesCubit>().load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  insets.inset,
                  32,
                  insets.inset,
                  24,
                ),
                sliver: SliverToBoxAdapter(child: FilesHeader(state: state)),
              ),
              ...FilesContent(state: state, insets: insets).slivers(),
            ],
          ),
        );
      },
    );
  }
}
