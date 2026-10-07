/// Anzahl der Sitzungen, die beim Abmelden anderer Geräte beendet wurden.
class RevokedSessions {
  const RevokedSessions(this.count) : assert(count >= 0);

  final int count;
}
