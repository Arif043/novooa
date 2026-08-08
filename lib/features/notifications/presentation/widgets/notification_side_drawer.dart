import 'package:flutter/material.dart';

import 'notification_panel.dart';

class NotificationSideDrawer extends StatelessWidget {
  const NotificationSideDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(left: false, child: NotificationPanel(onClose: onClose)),
    );
  }
}
