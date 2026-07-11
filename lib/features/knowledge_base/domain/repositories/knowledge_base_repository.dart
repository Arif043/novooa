import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/knowledge_note.dart';

abstract class KnowledgeBaseRepository {
  Stream<List<KnowledgeNote>> watchNotes(TeamId teamId);
}
