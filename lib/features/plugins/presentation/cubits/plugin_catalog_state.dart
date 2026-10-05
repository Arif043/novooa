import 'package:equatable/equatable.dart';

import '../../domain/entities/plugin_catalog_entry.dart';

enum PluginCatalogStatus { loading, ready, failure }

class PluginCatalogState extends Equatable {
  const PluginCatalogState({
    this.status = PluginCatalogStatus.loading,
    this.entries = const [],
    this.message,
  });

  final PluginCatalogStatus status;
  final List<PluginCatalogEntry> entries;

  /// Erklärt, warum der Katalog fehlt (nicht eingerichtet, offline, Lizenz).
  final String? message;

  @override
  List<Object?> get props => [status, entries, message];
}
