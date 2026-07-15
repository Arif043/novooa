class TeamMember {
  const TeamMember({
    required this.uid,
    required this.role,
    required this.joinedAt,
  });

  final String uid;
  final TeamMemberRole role;
  final DateTime joinedAt;
}

enum TeamMemberRole {
  owner('Besitzer'),
  admin('Admin'),
  member('Mitglied');

  const TeamMemberRole(this.label);

  final String label;
}
