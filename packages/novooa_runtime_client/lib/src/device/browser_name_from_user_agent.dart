/// Bekannte Browser in der Reihenfolge, in der sie geprüft werden müssen:
/// Edge und Opera nennen auch `Chrome`, Chrome nennt auch `Safari`.
const _browserMarkers = [
  ('Edg/', 'Edge'),
  ('OPR/', 'Opera'),
  ('Firefox/', 'Firefox'),
  ('FxiOS/', 'Firefox'),
  ('CriOS/', 'Chrome'),
  ('Chrome/', 'Chrome'),
  ('Safari/', 'Safari'),
];

/// Name des Browsers aus dem User-Agent, `null` wenn unbekannt.
String? browserNameFromUserAgent(String userAgent) {
  for (final (marker, name) in _browserMarkers) {
    if (userAgent.contains(marker)) return name;
  }
  return null;
}
