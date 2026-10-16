# Auflagen an den Modellkatalog

> Ein Modellkanal in ein Kundennetz ist ein Code-Lieferkanal; Integrität, Offline-Fähigkeit, keine Telemetrie und kein Auto-Update sind deshalb Pflicht.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

1. **Integrität:** Größe und SHA-256 jeder Datei im Katalog; Versionen im
   Modellspeicher unveränderlich. Der ML-Dienst prüft vor Sichtbarkeit eines
   Bündels.
2. **Optionalität:** Offline-Installationen (Enterprise) brauchen einen
   manuellen Weg: ein signiertes Bundle aus Manifest und Artefakt per
   Datenträger. Ohne Katalogverbindung bleibt die Runtime voll funktionsfähig.
   Das Bundle-Format ist noch offen.
3. **Keine Telemetrie:** Der Abruf übermittelt nicht, welche Modelle wie oft
   laufen — ein Listenabruf und ein Download, mehr nicht. Nachträglich wäre
   das nicht mehr glaubhaft herzustellen.
4. **Kein Auto-Update:** Der Sync holt Metadaten; welche Version läuft,
   entscheidet die Administration, auch bei unverändertem Vertrag.

Firestore `modelCatalog` ist Master; Runtimes lesen Metadaten nach der
Firebase-Anmeldung, die Artefakte lädt der ML-Dienst direkt aus dem
[globalen Modellspeicher](./globaler-modellspeicher.md). Ein
unauthentifizierter Katalogzugriff ist nicht vorgesehen.

## Siehe auch

- [Entscheidung: ML-Inferenz nur lokal](./ml-nur-lokal-entscheidung.md)
- [Modellversionierung](./modellversionierung.md)
