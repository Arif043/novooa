import 'package:cloud_functions/cloud_functions.dart';

import 'team_member_actions_datasource.dart';

class FirebaseFunctionsTeamMemberActionsDatasource
    implements TeamMemberActionsDatasource {
  FirebaseFunctionsTeamMemberActionsDatasource({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<void> addMember(String identifier) async {
    await _functions.httpsCallable('addTeamMemberFlow').call<void>({
      'identifier': identifier,
    });
  }

  @override
  Future<void> removeMember(String uid) async {
    await _functions.httpsCallable('removeTeamMemberFlow').call<void>({
      'uid': uid,
    });
  }
}
