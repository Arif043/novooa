import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import '../../domain/entities/employee_failure.dart';
import '../../domain/repositories/employee_repository.dart';
import '../models/employee_model.dart';

class FirestoreEmployeeRepository implements EmployeeRepository {
  const FirestoreEmployeeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Employee>> watchEmployees(TeamId teamId) {
    return _employeesReference(
      teamId,
    ).orderBy('name').snapshots().map(_employeesFrom);
  }

  @override
  Future<Result<Employee, EmployeeFailure>> createEmployee({
    required TeamId teamId,
    required EmployeeDraft draft,
  }) async {
    if (draft.name.trim().isEmpty) return _invalidName();
    try {
      final employeeId = UniqueId.random().value;
      await _employeesReference(
        teamId,
      ).doc(employeeId).set(_createDocument(draft));
      return _loadEmployee(teamId, employeeId);
    } catch (_) {
      return const Error(EmployeeFailure(EmployeeFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<Employee, EmployeeFailure>> updateEmployee({
    required TeamId teamId,
    required String employeeId,
    required EmployeeDraft draft,
  }) async {
    if (draft.name.trim().isEmpty) return _invalidName();
    try {
      await _employeesReference(
        teamId,
      ).doc(employeeId).update(_updateDocument(draft));
      return _loadEmployee(teamId, employeeId);
    } catch (_) {
      return const Error(EmployeeFailure(EmployeeFailureKind.saveFailed));
    }
  }

  @override
  Future<Result<Unit, EmployeeFailure>> deleteEmployee({
    required TeamId teamId,
    required String employeeId,
  }) async {
    try {
      await _employeesReference(teamId).doc(employeeId).delete();
      return const Success(unit);
    } catch (_) {
      return const Error(EmployeeFailure(EmployeeFailureKind.deleteFailed));
    }
  }

  List<Employee> _employeesFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(EmployeeModel.fromDocument)
        .map((model) => model.toDomain())
        .toList(growable: false);
  }

  Future<Result<Employee, EmployeeFailure>> _loadEmployee(
    TeamId teamId,
    String employeeId,
  ) async {
    final snapshot = await _employeesReference(teamId).doc(employeeId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return const Error(EmployeeFailure(EmployeeFailureKind.loadFailed));
    }
    return Success(EmployeeModel.fromDocument(snapshot).toDomain());
  }

  CollectionReference<Map<String, dynamic>> _employeesReference(TeamId teamId) {
    return _firestore
        .collection('teams')
        .doc(teamId.value)
        .collection('employees');
  }

  Map<String, Object?> _createDocument(EmployeeDraft draft) {
    return {
      ..._employeeDocument(draft),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _updateDocument(EmployeeDraft draft) {
    return _employeeDocument(draft);
  }

  Map<String, Object?> _employeeDocument(EmployeeDraft draft) {
    return {
      'name': draft.name.trim(),
      'role': draft.role,
      'promptTemplate': draft.promptTemplate,
      'defaultSkills': draft.defaultSkills.map(_skillToDocument).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> _skillToDocument(SkillAttachment skill) {
    return {'name': skill.name, 'description': skill.description};
  }

  Result<Employee, EmployeeFailure> _invalidName() {
    return const Error(EmployeeFailure(EmployeeFailureKind.invalidName));
  }
}
