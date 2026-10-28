import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/luminous_page_theme.dart';
import '../../../../core/widgets/luminous_status_placeholder.dart';
import '../../domain/entities/team_file.dart';
import '../cubits/file_actions_cubit.dart';
import '../cubits/file_actions_state.dart';
import '../cubits/file_detail_cubit.dart';
import '../cubits/file_detail_state.dart';
import '../widgets/detail/file_action_feedback.dart';
import '../widgets/detail/file_detail_layout.dart';

class FileDetailPage extends StatelessWidget {
  const FileDetailPage({super.key, required this.file});

  final TeamFile file;

  static Route<void> route(TeamFile file) =>
      MaterialPageRoute<void>(builder: (_) => FileDetailPage(file: file));

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<FileDetailCubit>()..load(file),
        ),
        BlocProvider(create: (_) => serviceLocator<FileActionsCubit>()),
      ],
      child: Theme(
        data: LuminousPageTheme.from(Theme.of(context)),
        child: const _FileDetailView(),
      ),
    );
  }
}

class _FileDetailView extends StatelessWidget {
  const _FileDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<FileActionsCubit, FileActionsState>(
              listener: (context, state) => showFileActionFeedback(
                context,
                state,
                onOpenCopy: (copy) => Navigator.of(
                  context,
                ).pushReplacement(FileDetailPage.route(copy)),
              ),
            ),
            BlocListener<FileDetailCubit, FileDetailState>(
              listenWhen: (_, current) => current is FileDetailDeleted,
              listener: (context, _) => Navigator.of(context).maybePop(),
            ),
          ],
          child: BlocBuilder<FileDetailCubit, FileDetailState>(
            builder: (context, state) => switch (state) {
              FileDetailReady() => FileDetailLayout(state: state),
              FileDetailLoading() || FileDetailDeleted() => const Center(
                child: CircularProgressIndicator(),
              ),
              FileDetailFailure() => LuminousStatusPlaceholder(
                loading: false,
                message: LocaleKeys.files_file_load_failed.tr(),
                fallbackMessage: LocaleKeys.files_file_load_failed.tr(),
                onRetry: context.read<FileDetailCubit>().retry,
              ),
            },
          ),
        ),
      ),
    );
  }
}
