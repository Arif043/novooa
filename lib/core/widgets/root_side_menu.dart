import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../root_tab.dart';
import '../localization/locale_keys.g.dart';
import '../theme/app_spacing.dart';
import 'root_side_menu_sections.dart';

class RootSideMenu extends StatelessWidget {
  const RootSideMenu({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.currentUserName,
    this.onSignOut,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? currentUserName;

  /// `null` blendet den Menüpunkt „Abmelden“ aus. Was Abmelden bedeutet,
  /// entscheidet der Aufrufer (siehe `RootPage`).
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.gutter,
          ),
          child: _SideMenuContent(
            tabs: tabs,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            currentUserName: currentUserName,
            onSignOut: onSignOut,
          ),
        ),
      ),
    );
  }
}

class _SideMenuContent extends StatelessWidget {
  const _SideMenuContent({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    required this.currentUserName,
    required this.onSignOut,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String? currentUserName;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSignOut = this.onSignOut;
    return ListView(
      children: [
        SideMenuHeader(currentUserName: currentUserName),
        const SizedBox(height: AppSpacing.md),
        SideMenuTabList(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        if (onSignOut != null)
          ListTile(
            selected: false,
            iconColor: colorScheme.error,
            textColor: colorScheme.error,
            leading: SideMenuIcon(
              icon: CupertinoIcons.square_arrow_left,
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            title: Text(LocaleKeys.navigation_sign_out.tr()),
            onTap: onSignOut,
          ),
      ],
    );
  }
}
