import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_collection.dart';
import '../cubits/database_actions_cubit.dart';
import '../cubits/database_actions_state.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_import_cubit.dart';
import '../cubits/database_state.dart';
import '../widgets/database_feedback_text.dart';
import '../widgets/database_overview.dart';
import '../widgets/database_records_view.dart';
import '../widgets/database_states.dart';
import '../widgets/database_theme.dart';

class DatabasePage extends StatelessWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<DatabaseImportCubitFactory>.value(
        value: (DataCollection collection) =>
            serviceLocator<DatabaseImportCubit>(param1: collection),
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => serviceLocator<DatabaseCubit>()..loadCollections(),
            ),
            BlocProvider(create: (_) => serviceLocator<DatabaseActionsCubit>()),
          ],
          child: const DatabaseView(),
        ),
      );
}

/// Seite ohne eigene Cubits — erwartet [DatabaseCubit], [DatabaseActionsCubit] und eine
/// [DatabaseImportCubitFactory] im Kontext (für Tests und Einbettung).
class DatabaseView extends StatelessWidget {
  const DatabaseView({super.key});

  @override
  Widget build(BuildContext context) => Theme(
    data: DatabaseTheme.from(Theme.of(context)),
    child: Builder(
      builder: (context) => MultiBlocListener(
        listeners: [
          BlocListener<DatabaseCubit, DatabaseState>(
            listenWhen: (before, after) =>
                after.message != null && before.message != after.message,
            listener: (context, state) => _show(context, state.message!),
          ),
          BlocListener<DatabaseActionsCubit, DatabaseActionsState>(
            listenWhen: (before, after) =>
                after.notice != null && before.notice != after.notice,
            listener: (context, state) =>
                _show(context, databaseNoticeText(state.notice!)),
          ),
        ],
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: const SafeArea(child: _Workspace()),
        ),
      ),
    ),
  );

  void _show(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
}

class _Workspace extends StatelessWidget {
  const _Workspace();

  /// Unterhalb dieser Höhe scrollt die ganze Arbeitsfläche, damit nichts überläuft.
  static const _minimumHeight = 640.0;
  static const _scrolledHeight = 760.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DatabaseCubit>().state;
    final busy = context.select(
      (DatabaseActionsCubit cubit) => cubit.state.isBusy,
    );
    // Die Übersicht scrollt selbst und setzt ihre Ränder wie der Zeitplan.
    if (state.status == DatabaseStatus.collections) {
      return DatabaseOverview(state: state, busy: busy);
    }
    final content = Padding(
      padding: EdgeInsets.all(
        MediaQuery.sizeOf(context).width < 600 ? AppSpacing.md : AppSpacing.lg,
      ),
      child: switch (state.status) {
        DatabaseStatus.failure => DatabaseFailureState(
          message: state.message ?? LocaleKeys.ui_db_load_failed.tr(),
          onRetry: context.read<DatabaseCubit>().loadCollections,
        ),
        DatabaseStatus.records => DatabaseRecordsView(state: state, busy: busy),
        _ => const Center(child: CupertinoActivityIndicator()),
      },
    );
    // Große Schrift braucht mehr Höhe; darunter scrollt die ganze Arbeitsfläche.
    final scale = math.max(
      1.0,
      MediaQuery.textScalerOf(context).scale(14) / 14,
    );
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxHeight < _minimumHeight * scale
          ? SingleChildScrollView(
              child: SizedBox(
                height: math.max(_scrolledHeight, _minimumHeight * scale),
                child: content,
              ),
            )
          : content,
    );
  }
}
