import 'package:equatable/equatable.dart';

import '../../domain/entities/skill_catalog.dart';

enum SkillCatalogStatus { checking, unavailable, loading, ready, failure }

class SkillCatalogState extends Equatable {
  const SkillCatalogState({
    this.status = SkillCatalogStatus.checking,
    this.query = '',
    this.items = const [],
    this.message,
  });

  final SkillCatalogStatus status;
  final String query;
  final List<CatalogSkill> items;
  final String? message;

  @override
  List<Object?> get props => [status, query, items, message];
}
