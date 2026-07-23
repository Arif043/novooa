class MvpFeatureFlags {
  const MvpFeatureFlags._();

  static const bool skillsEnabled = false;
  static const bool employeesEnabled = false;

  static const bool promptDelegationEnabled = skillsEnabled || employeesEnabled;
}
