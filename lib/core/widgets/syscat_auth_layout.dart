import 'package:flutter/material.dart';

import '../../generated/assets.dart';
import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';
import 'syscat_background.dart';

/// Gemeinsamer Rahmen der Anmelde- und Einrichtungsseiten: orange/weißer
/// Blur-Hintergrund, darauf eine zentrierte Karte mit Logo. Die Cloud-
/// Anmeldung und die Runtime-Einrichtung (Adresse, Lizenz, Passwort) teilen
/// ihn, damit beide Wege gleich aussehen.
class SyscatAuthLayout extends StatelessWidget {
  const SyscatAuthLayout({
    super.key,
    required this.child,
    this.maxCardWidth = defaultCardWidth,
  });

  final Widget child;

  /// Breite der Cloud-Anmeldung.
  static const double defaultCardWidth = 416;

  /// Breite der Runtime-Einrichtung: Die 16 quadratischen Felder des
  /// Lizenz-Tokens sollen mit 48 px Kantenlänge in eine Reihe passen.
  static const double runtimeCardWidth = 920;

  final double maxCardWidth;

  @override
  Widget build(BuildContext context) {
    return SyscatBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pageMobile),
              child: _AuthCard(maxWidth: maxCardWidth, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: SyscatTheme.shadowMedium,
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'novooa',
                image: true,
                child: ExcludeSemantics(
                  // Auf breiteren Karten so groß wie in der Cloud-Anmeldung.
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth:
                            SyscatAuthLayout.defaultCardWidth -
                            2 * AppSpacing.xl,
                      ),
                      child: Image.asset(Assets.iconsFullv2Transparent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
