import 'package:flutter/material.dart';

const _icons = <String, IconData>{
  'extension': Icons.extension_outlined,
  'waving_hand': Icons.waving_hand_outlined,
  'bolt': Icons.bolt,
  'mail': Icons.mail_outline,
  'chat': Icons.chat_bubble_outline,
  'cloud': Icons.cloud_outlined,
  'storage': Icons.storage_outlined,
  'calendar_today': Icons.calendar_today_outlined,
  'description': Icons.description_outlined,
  'image': Icons.image_outlined,
  'code': Icons.code,
  'tune': Icons.tune,
  'notifications': Icons.notifications_outlined,
  'search': Icons.search,
  'shopping_cart': Icons.shopping_cart_outlined,
  'payments': Icons.payments_outlined,
  'language': Icons.language,
  'translate': Icons.translate,
  'smart_toy': Icons.smart_toy_outlined,
  'build': Icons.build_outlined,
  'send': Icons.send_outlined,
  'timer': Icons.timer_outlined,
  'person': Icons.person_outline,
  'lock': Icons.lock_outline,
};

/// Plugins nennen ein Symbol nur beim Namen; der Client liefert die Zeichen
/// mit. Unbekannte Namen zeigen das allgemeine Plugin-Symbol.
IconData pluginIconFor(String? name) =>
    _icons[name] ?? Icons.extension_outlined;
