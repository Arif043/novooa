import 'package:flutter/material.dart';

import '../../domain/entities/communication_channel.dart';
import 'mail_provider_option.dart';

/// Das Logo eines Anbieters, sonst das Icon der Kanalart. Das Logo ist
/// Schmuck: Der Name steht immer daneben, Screenreader überspringen es.
class CommunicationProviderLogo extends StatelessWidget {
  const CommunicationProviderLogo({
    super.key,
    required this.provider,
    required this.fallbackIcon,
    this.size = 24,
  });

  final CommunicationProvider provider;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = mailProviderFor(provider)?.logoAsset;
    if (asset == null) return _fallback(context);
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) => Icon(
    fallbackIcon,
    size: size,
    color: Theme.of(context).colorScheme.primary,
  );
}
