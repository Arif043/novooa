import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_state.dart';
import '../../root_tab.dart';
import '../theme/app_spacing.dart';
import 'root_side_menu_sections.dart';

class RootSideMenu extends StatelessWidget {
  const RootSideMenu({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listenWhen: _isNewFailure,
      listener: _showFailure,
      child: Material(
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
            ),
          ),
        ),
      ),
    );
  }

  bool _isNewFailure(AuthSessionState previous, AuthSessionState current) {
    return current.status == AuthSessionStatus.failure &&
        previous.message != current.message;
  }

  void _showFailure(BuildContext context, AuthSessionState state) {
    final message = state.message ?? 'Abmelden fehlgeschlagen.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SideMenuContent extends StatelessWidget {
  const _SideMenuContent({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RootTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SideMenuHeader(),
        const SizedBox(height: AppSpacing.md),
        SideMenuTabList(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onSelected: onSelected,
        ),
        ListTile(
          selected: false,
          iconColor: colorScheme.error,
          textColor: colorScheme.error,
          leading: const Icon(Icons.logout),
          title: const Text('Abmelden'),
          onTap: () => context.read<AuthSessionCubit>().signOut(),
        ),
      ],
    );
  }
}
