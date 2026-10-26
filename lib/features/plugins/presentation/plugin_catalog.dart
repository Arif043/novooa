import 'package:flutter/widgets.dart';

import '../domain/entities/plugin_activation.dart';

/// Was ein Plugin für die Liste unter Einstellungen → Plugins mitbringt.
class PluginDescription {
  const PluginDescription({
    required this.id,
    required this._title,
    required this._description,
    required this.icon,
    this.settingsBuilder,
  });

  final PluginId id;

  /// Erst beim Anzeigen übersetzt; Plugins melden sich vor dem Laden der
  /// Übersetzungen an.
  final String Function() _title;
  final String Function() _description;
  final IconData icon;

  /// Eigener Einstellungsbereich, sichtbar nur bei aktivem Plugin.
  final WidgetBuilder? settingsBuilder;

  String get title => _title();
  String get description => _description();
}

/// Die eingebauten Plugins der App, in der Reihenfolge ihrer Anmeldung.
class PluginCatalog {
  PluginCatalog._();

  static final Map<PluginId, PluginDescription> _byId = {};

  static void register(PluginDescription plugin) => _byId[plugin.id] = plugin;

  static void unregister(PluginId id) => _byId.remove(id);

  static List<PluginDescription> get all => List.unmodifiable(_byId.values);
}
