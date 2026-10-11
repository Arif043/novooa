import 'package:flutter/material.dart';

import 'settings_tab_contribution.dart';
import 'settings_tab_detail.dart';
import 'settings_tab_list.dart';

/// Mobile-Ansicht: erst die Liste aller Bereiche, dann der gewählte Bereich.
/// Der Wechsel bleibt im selben Widget-Baum statt eine Route zu öffnen,
/// damit die Bereiche weiter die Cubits der Einstellungsseite erreichen.
class CompactSettingsNavigation extends StatefulWidget {
  const CompactSettingsNavigation({super.key, required this.tabs});

  final List<SettingsTabContribution> tabs;

  @override
  State<CompactSettingsNavigation> createState() =>
      _CompactSettingsNavigationState();
}

class _CompactSettingsNavigationState extends State<CompactSettingsNavigation> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;
    return PopScope(
      canPop: selectedIndex == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: selectedIndex == null
          ? SettingsTabList(tabs: widget.tabs, onSelected: _select)
          : SettingsTabDetail(
              tab: widget.tabs[selectedIndex],
              onBack: () => _select(null),
            ),
    );
  }

  void _select(int? index) => setState(() => _selectedIndex = index);
}
