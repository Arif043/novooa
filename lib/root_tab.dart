import 'package:flutter/material.dart';

class RootTab {
  const RootTab({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;
}
