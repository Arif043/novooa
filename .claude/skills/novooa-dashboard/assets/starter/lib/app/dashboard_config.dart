/// Was dieses Kunden-Dashboard zeigt. Pro Kunde anpassen; alles andere bleibt
/// gleich, damit Updates des Skills sich übernehmen lassen.
class DashboardConfig {
  const DashboardConfig._();

  /// Erscheint in der Titelleiste und im Browser-Tab.
  static const title = '__DASHBOARD_TITLE__';

  /// IDs der Aufgaben, die das Dashboard anbietet. Leer: alle Aufgaben der
  /// Runtime. Die IDs stehen im offiziellen Frontend in der Adresse einer
  /// Aufgabe.
  static const allowedTaskIds = <String>{};

  /// Wie viele Läufe die Läufe-Seite zeigt; die Runtime liefert höchstens 100.
  static const visibleRunCount = 50;

  static bool showsTask(String taskId) =>
      allowedTaskIds.isEmpty || allowedTaskIds.contains(taskId);
}
