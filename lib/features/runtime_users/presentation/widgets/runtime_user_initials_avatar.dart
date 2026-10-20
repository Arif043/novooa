import 'package:flutter/material.dart';

import '../../domain/entities/runtime_user.dart';
import 'runtime_user_texts.dart';

/// Menschen erscheinen mit Initialen, nicht als Noovi (der steht für Agenten).
class RuntimeUserInitialsAvatar extends StatelessWidget {
  const RuntimeUserInitialsAvatar({super.key, required this.user});

  final RuntimeUser user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 20,
        backgroundColor: user.role.isAdmin
            ? colors.primaryContainer
            : colors.secondaryContainer,
        foregroundColor: user.role.isAdmin
            ? colors.onPrimaryContainer
            : colors.onSecondaryContainer,
        child: Text(initialsOf(user)),
      ),
    );
  }
}
