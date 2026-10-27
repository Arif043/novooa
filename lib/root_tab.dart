import 'package:flutter/material.dart';

class RootTab {
  const RootTab({
    required this.title,
    required this.icon,
    required this.path,
    this.hasPageHeader = false,
  });

  final String title;
  final IconData icon;
  final String path;

  /// Die Seite zeigt ihren Titel selbst groß im Kopf (Luminous-Seitenstil); die obere Leiste
  /// lässt ihn dann weg, damit er nicht doppelt erscheint.
  final bool hasPageHeader;
}
