import 'package:flutter/material.dart';

class RootTab {
  const RootTab({
    required this.title,
    required this.icon,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}
