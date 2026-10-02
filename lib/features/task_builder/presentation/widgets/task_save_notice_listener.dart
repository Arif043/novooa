import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/task_save_notice.dart';

/// Zeigt Rückmeldungen des Speicherns als SnackBar an.
class TaskSaveNoticeListener extends StatefulWidget {
  const TaskSaveNoticeListener({
    super.key,
    required this.notices,
    required this.child,
  });

  final Stream<TaskSaveNotice> notices;
  final Widget child;

  @override
  State<TaskSaveNoticeListener> createState() => _TaskSaveNoticeListenerState();
}

class _TaskSaveNoticeListenerState extends State<TaskSaveNoticeListener> {
  StreamSubscription<TaskSaveNotice>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.notices.listen(_show);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _show(TaskSaveNotice notice) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    final prefix = notice.isRejection ? 'Nicht gespeichert: ' : 'Hinweis: ';
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          showCloseIcon: true,
          backgroundColor: notice.isRejection ? colors.errorContainer : null,
          content: Text(
            '$prefix${notice.message}',
            style: notice.isRejection
                ? TextStyle(color: colors.onErrorContainer)
                : null,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
