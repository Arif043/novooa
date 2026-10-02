import 'package:equatable/equatable.dart';

class CatalogSkill extends Equatable {
  const CatalogSkill({
    required this.id,
    required this.name,
    required this.source,
    required this.installs,
  });

  /// Stabile Kennung `{quelle}/{slug}`.
  final String id;
  final String name;
  final String source;
  final int installs;

  @override
  List<Object?> get props => [id, name, source, installs];
}

enum CatalogView { allTime, trending, hot }

class CatalogPage extends Equatable {
  const CatalogPage({required this.items, required this.hasMore});

  final List<CatalogSkill> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}

enum CatalogAuditStatus { pass, warn, fail }

/// Sicherheitsprüfung eines Partners (Socket, Snyk, …) für einen Katalog-Skill.
class CatalogAudit extends Equatable {
  const CatalogAudit({
    required this.provider,
    required this.status,
    required this.summary,
  });

  final String provider;
  final CatalogAuditStatus status;
  final String summary;

  @override
  List<Object?> get props => [provider, status, summary];
}
