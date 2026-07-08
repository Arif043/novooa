class TeamId {
  const TeamId(this.value) : assert(value.length > 0);

  factory TeamId.personal(String userId) {
    return TeamId('personal_$userId');
  }

  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TeamId &&
            runtimeType == other.runtimeType &&
            value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
