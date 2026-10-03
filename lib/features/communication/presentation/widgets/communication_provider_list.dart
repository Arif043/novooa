import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'communication_provider_logo.dart';
import 'mail_provider_option.dart';

/// Zweite Seite des Postfach-Dialogs: alle Anbieter, bei denen sich ein
/// Postfach verbinden lässt.
class CommunicationProviderList extends StatelessWidget {
  const CommunicationProviderList({super.key, required this.onSelected});

  final ValueChanged<MailProviderOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: mailProviderOptions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final option = mailProviderOptions[index];
        return ListTile(
          minVerticalPadding: AppSpacing.md,
          leading: CommunicationProviderLogo(
            provider: option.provider,
            fallbackIcon: option.icon,
            size: AppSpacing.lg + AppSpacing.sm,
          ),
          title: Text(option.label),
          subtitle: Text(option.description),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onSelected(option),
        );
      },
    );
  }
}
