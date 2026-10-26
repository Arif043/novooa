import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.g.dart';

/// Gruß nach Tageszeit mit dem Vornamen, z. B. „Guten Abend, Arif!“.
class UserGreeting extends StatelessWidget {
  const UserGreeting({super.key, required this.displayName, required this.now});

  final String? displayName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Text(
      _greeting(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  String _greeting() {
    final (plain, named) = switch (now.hour) {
      >= 5 && < 12 => (
        LocaleKeys.navigation_greeting_morning,
        LocaleKeys.navigation_greeting_morning_named,
      ),
      >= 12 && < 18 => (
        LocaleKeys.navigation_greeting_day,
        LocaleKeys.navigation_greeting_day_named,
      ),
      _ => (
        LocaleKeys.navigation_greeting_evening,
        LocaleKeys.navigation_greeting_evening_named,
      ),
    };
    final firstName = _firstName();
    if (firstName.isEmpty) return plain.tr();
    return named.tr(namedArgs: {'name': firstName});
  }

  String _firstName() {
    final parts = displayName?.trim().split(RegExp(r'\s+')) ?? const [];
    return parts.isEmpty ? '' : parts.first;
  }
}
