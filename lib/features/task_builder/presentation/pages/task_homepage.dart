import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskHomepage extends StatelessWidget {
  const TaskHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton(
          onPressed: () {
            context.go('/tasks/builder');
          },
          child: const Text('Neue Aufgabe'),
        ),
      ],
    );
  }
}
