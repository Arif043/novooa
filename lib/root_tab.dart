import 'package:flutter/material.dart';

class RootTab {
  const RootTab({
    required this.title,
    required this.icon,
    required this.builder,
    this.useCustomAppBar = false,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;

  /// Wenn `true`, rendert das Tab seinen eigenen [Scaffold] inkl.
  /// [AppBar]. Der globale App-Bar des [RootPage] wird in dem Fall
  /// ausgeblendet, damit das Tab die volle Höhe für seinen eigenen
  /// Header nutzen kann.
  final bool useCustomAppBar;
}
