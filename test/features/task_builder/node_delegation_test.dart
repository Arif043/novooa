import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_delegation.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';

const _skill = SkillAttachment(name: 'pdf', description: 'PDFs');
const _other = SkillAttachment(name: 'mails', description: 'Mails');

NodeConfigDocumentMapper _mapper() => NodeConfigDocumentMapper(
  graphToDocument: (_) => const {},
  graphFromDocument: (_) => WorkflowGraph.empty(),
);

void main() {
  group('resolveNodeDelegation', () {
    test('ein Mitarbeiter leert die Fähigkeiten', () {
      final result = resolveNodeDelegation(
        currentEmployeeId: null,
        currentSkills: const [_skill],
        employeeId: 'e1',
      );

      expect(result.employeeId, 'e1');
      expect(result.skillAttachments, isEmpty);
    });

    test('nicht leere Fähigkeiten entfernen den Mitarbeiter', () {
      final result = resolveNodeDelegation(
        currentEmployeeId: 'e1',
        currentSkills: const [],
        skillAttachments: const [_skill],
      );

      expect(result.employeeId, isNull);
      expect(result.skillAttachments, [_skill]);
    });

    test('eine leere Fähigkeitenliste lässt den Mitarbeiter bestehen', () {
      final result = resolveNodeDelegation(
        currentEmployeeId: 'e1',
        currentSkills: const [],
        skillAttachments: const [],
      );

      expect(result.employeeId, 'e1');
    });

    test('clearEmployee entfernt den Mitarbeiter und behält Fähigkeiten', () {
      final result = resolveNodeDelegation(
        currentEmployeeId: 'e1',
        currentSkills: const [],
        clearEmployee: true,
      );

      expect(result.employeeId, isNull);
      expect(result.skillAttachments, isEmpty);
    });

    test('Altdaten mit beidem: der Mitarbeiter gewinnt', () {
      final result = normalizedNodeDelegation(
        employeeId: 'e1',
        skillAttachments: const [_skill, _other],
      );

      expect(result.employeeId, 'e1');
      expect(result.skillAttachments, isEmpty);
    });
  });

  group('PromptNodeConfig', () {
    test('Mitarbeiter und Fähigkeiten schließen sich über copyWith aus', () {
      final withSkills = PromptNodeConfig.initial().attachSkill(_skill);
      final withEmployee = withSkills.assignEmployee('e1');
      final backToSkills = withEmployee.attachSkill(_other);

      expect(withSkills.employeeId, isNull);
      expect(withEmployee.employeeId, 'e1');
      expect(withEmployee.skillAttachments, isEmpty);
      expect(backToSkills.employeeId, isNull);
      expect(backToSkills.skillAttachments, [_other]);
    });

    test('unassignEmployee entfernt nur den Mitarbeiter', () {
      final config = PromptNodeConfig.initial().assignEmployee('e1');

      expect(config.unassignEmployee().employeeId, isNull);
      expect(config.unassignEmployee().skillAttachments, isEmpty);
    });
  });

  group('IterativeRefinementNodeConfig', () {
    test('gleiche Regel wie beim Prompt', () {
      final config = IterativeRefinementNodeConfig.initial()
          .attachSkill(_skill)
          .assignEmployee('e1');

      expect(config.employeeId, 'e1');
      expect(config.skillAttachments, isEmpty);
      expect(config.attachSkill(_skill).employeeId, isNull);
    });
  });

  group('Mapper', () {
    test('speichert nur die ID und liest sie zurück', () {
      final mapper = _mapper();
      final config = PromptNodeConfig.initial().assignEmployee('e1');

      final document = mapper.toDocument(config);
      final restored = mapper.fromDocument(document) as PromptNodeConfig;

      expect(document['employeeId'], 'e1');
      expect(document.containsKey('employee'), isFalse);
      expect(restored.employeeId, 'e1');
    });

    test('Dokumente mit Mitarbeiter und Fähigkeiten werden bereinigt', () {
      final restored =
          _mapper().fromDocument({
                'primitive': 'prompt',
                'instruction': 'x',
                'employeeId': 'e1',
                'skillAttachments': [
                  {'name': 'pdf', 'description': 'PDFs'},
                ],
              })
              as PromptNodeConfig;

      expect(restored.employeeId, 'e1');
      expect(restored.skillAttachments, isEmpty);
    });

    test('eine leere ID gilt als kein Mitarbeiter, Fähigkeiten bleiben', () {
      final restored =
          _mapper().fromDocument({
                'primitive': 'iterativeRefinement',
                'employeeId': '',
                'skillAttachments': [
                  {'name': 'pdf', 'description': 'PDFs'},
                ],
              })
              as IterativeRefinementNodeConfig;

      expect(restored.employeeId, isNull);
      expect(restored.skillAttachments.single.name, 'pdf');
    });
  });
}
