import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RootAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RootAppBar({
    super.key,
    this.title,
    required this.onMenuPressed,
    this.actions,
  });

  final Widget? title;
  final VoidCallback onMenuPressed;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        tooltip: 'Menü öffnen',
        icon: const Icon(CupertinoIcons.sidebar_left),
        onPressed: onMenuPressed,
      ),
      title: title,
      actions: actions,
    );
  }
}
