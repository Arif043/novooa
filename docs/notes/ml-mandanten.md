# ML-Mandanten

> Jede Runtime meldet sich mit ihrer Lizenz-ID beim ML-Dienst an und erhält ein eigenes Token; Teammodelle hängen an dieser Registrierung.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- **Kennung = `licenseId`.** Jede Lizenz ist nur einmal aktivierbar, also hat
  jeder Stack seine eigene, auch bei mehreren Lizenzen desselben Teams. Ohne
  Angabe beim Ausstellen eine zufällige UUID — Lizenzen deshalb ohne lesbare
  `--license-id` ausstellen, sonst könnte ein anderer Stack sie vorab
  belegen. Die Kennung ist kein Geheimnis und nie ein Token.
- **Anmeldung** (`MlTenantSession`) bei der ersten Anfrage: Token `nml_…`
  (32 Zufallsbytes); der Dienst speichert nur dessen SHA-256
  (`tenants.sqlite3`). Die Runtime legt es verschlüsselt unter
  `credentials/ml-service-token.json` ab; die Schlüsselrotation schlüsselt es
  um. Wer zuerst anmeldet, erhält die Kennung, sonst `409`.
- **Abmeldung:** Meldet die [Lizenzprüfung](./lizenz-regelmaessige-pruefung.md)
  eindeutig „ungültig“, sendet die Runtime `DELETE /v1/tenants/self`; ist das
  Gateway nur unerreichbar, nichts. Wird die Lizenz wieder gültig, meldet sie
  sich neu an und lädt Teammodelle bei Bedarf erneut hoch.
- **`401`:** Ein ungültiges Token ersetzt die Runtime einmal durch eine neue
  Anmeldung.
- **Trennung:** Teammodelle und Sitzungen hängen an der Registrierung, nicht
  an der Kennung; eine neu vergebene Kennung sieht keine Reste.
- **Verwaltung im Container:** `python -m novooa_ml.tenants list`,
  `python -m novooa_ml.tenants delete <kennung>`.
- **Ohne Mandanten** (`ML_TENANCY=off`): ein Nutzer, kein Token, z. B. für
  die Entwicklung.

**Grenze:** Vorab belegen kann nur, wer die UUID eines anderen Stacks kennt.
Im ML-Netz sind nur Runtimes, Script-Bausteine haben keinen Zugang. Die
Abmeldung ist Aufräumen, kein Schutz gegen eine manipulierte Runtime.

## Siehe auch

- [Schnittstelle des ML-Dienstes](./ml-dienst-schnittstelle.md)
- [Lizenz ausstellen](./lizenz-ausstellen.md)
