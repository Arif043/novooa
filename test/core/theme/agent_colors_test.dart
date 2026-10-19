import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/agent_colors.dart';

void main() {
  test('an employee keeps his colour, on every platform', () {
    // Festgeschrieben: FNV-1a von „e1“ ergibt Platz 3. Ein anderer Wert hieße,
    // dass Mitarbeiter je nach Plattform oder Version anders aussehen.
    expect(AgentColors.memberColor('e1'), AgentColors.members[3]);
    expect(AgentColors.memberColor('e1'), AgentColors.memberColor('e1'));
  });

  test('different employees spread over the palette', () {
    final colours = {
      for (var index = 0; index < 40; index++)
        AgentColors.memberColor('employee-$index'),
    };

    expect(colours.length, greaterThanOrEqualTo(6));
  });

  test('orchestrator and review take their colours from the theme', () {
    const scheme = ColorScheme.light(
      primary: Colors.orange,
      tertiary: Colors.teal,
    );

    expect(AgentColors.orchestratorOf(scheme), Colors.orange);
    expect(AgentColors.reviewerOf(scheme), Colors.teal);
  });
}
