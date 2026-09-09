import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/application_log.dart';
import '../cubits/application_logs_cubit.dart';
import '../cubits/application_logs_state.dart';

class LocalApplicationLogsView extends StatelessWidget {
  const LocalApplicationLogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<ApplicationLogsCubit>()..load(),
      child: const _ApplicationLogContent(),
    );
  }
}

class _ApplicationLogContent extends StatelessWidget {
  const _ApplicationLogContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApplicationLogsCubit, ApplicationLogsState>(
      builder: (context, state) => switch (state) {
        ApplicationLogsLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        ApplicationLogsFailure() => _Failure(
          onRetry: context.read<ApplicationLogsCubit>().load,
        ),
        ApplicationLogsReady(:final logs) => _LogList(logs: logs),
      },
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({required this.logs});

  final List<ApplicationLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('Noch keine Anwendungseinträge vorhanden.'),
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<ApplicationLogsCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: logs.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (_, index) => _LogItem(log: logs[index]),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.log});

  final ApplicationLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = log.level == ApplicationLogLevel.error;
    final color = isError ? theme.colorScheme.error : theme.colorScheme.primary;
    return Semantics(
      label: '${isError ? 'Fehler' : 'Information'}: ${log.event}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isError ? Icons.error_outline : Icons.info_outline,
          color: color,
        ),
        title: Text(
          log.message ?? log.event,
          style: theme.textTheme.titleSmall,
        ),
        subtitle: _LogSummary(log: log),
      ),
    );
  }
}

class _LogSummary extends StatelessWidget {
  const _LogSummary({required this.log});

  final ApplicationLog log;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final details = <String>[
      if (log.message != null) log.event,
      log.source == ApplicationLogSource.client ? 'Client' : 'Lokale Runtime',
      _timestamp(log.occurredAt),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(details.join('\n'), style: style),
        ),
        if (log.data.isNotEmpty) _LogData(log: log),
      ],
    );
  }

  String _timestamp(DateTime value) {
    String part(int number) => number.toString().padLeft(2, '0');
    return '${part(value.day)}.${part(value.month)}.${value.year} '
        '${part(value.hour)}:${part(value.minute)}:${part(value.second)}';
  }
}

class _LogData extends StatelessWidget {
  const _LogData({required this.log});

  final ApplicationLog log;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final error = log.data['error'];
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      title: Text(
        error is String ? error : 'Technische Details',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(log.data),
            style: style,
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Das Anwendungsprotokoll konnte nicht geladen werden.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Protokoll erneut laden'),
          ),
        ],
      ),
    );
  }
}
