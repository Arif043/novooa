abstract interface class TeamMemberActionsDatasource {
  Future<void> addMember(String identifier);

  Future<void> removeMember(String uid);
}
