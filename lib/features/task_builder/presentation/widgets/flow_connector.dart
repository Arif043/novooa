import 'package:flutter/material.dart';

import '../../../../core/theme/syscat_theme.dart';

/// Schmaler Chevron zwischen zwei [NodeCard]s.
///
/// Bewusst minimal gehalten — 16 px Höhe mit einem zentrierten
/// `expand_more`-Pfeil. Deutet die Reihenfolge im Flow an, ohne selbst
/// Aufmerksamkeit zu binden.
class FlowConnector extends StatelessWidget {
  const FlowConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Center(
        child: Icon(
          Icons.expand_more,
          size: 16,
          color: SyscatTheme.textHint,
        ),
      ),
    );
  }
}