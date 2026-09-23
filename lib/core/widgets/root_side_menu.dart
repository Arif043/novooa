import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../root_tab.dart';
import '../theme/app_spacing.dart';
import 'root_side_menu_sections.dart';

class RootSideMenu extends StatelessWidget {
  const RootSideMenu({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.showCurrentUserProfile = true,
    this.onSignOut,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showCurrentUserProfile;

  /// `null` blendet den Menüpunkt „Abmelden“ aus. Was Abmelden konkret
  /// bedeutet, entscheidet der Aufrufer — z.B. `AuthSessionCubit.signOut()`
  /// in der Cloud-Variante oder `RuntimeConnectionCubit.signOut()` im
  /// Standalone-Betrieb (siehe `RootPage`). `RootSideMenu` kennt bewusst
  /// keine dieser Fachlichkeiten.
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
            showCurrentUserProfile: showCurrentUserProfile,
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
    required this.showCurrentUserProfile,
    required this.onSignOut,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool showCurrentUserProfile;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSignOut = this.onSignOut;
    return ListView(
      children: [
        SideMenuHeader(showCurrentUserProfile: showCurrentUserProfile),
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
            title: const Text('Abmelden'),
            onTap: onSignOut,
          ),
      ],
    );
  }
}
