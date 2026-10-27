import {type RuntimeDatabase} from "../../db/database.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";

/**
 * Prozessweite Infrastruktur der Runtime: einmal beim Start im Entrypoint gebaut und bis zum
 * Herunterfahren unverändert.
 *
 * Bewusst getrennt von `LocalRuntimeWorkspace`: Der Host besteht schon vor der
 * Lizenzaktivierung (Prozesssperre, Datenbank, Schlüssel) und überdauert jeden
 * Arbeitsbereichswechsel. Der Arbeitsbereich ist dagegen die Identität der aktiven Lizenz —
 * Team und Nutzer — und kann zur Laufzeit wechseln. Team-Daten trennt die Runtime über die
 * `teamId` in der Datenbank, nicht über eigene Verzeichnisse.
 *
 * Nur die Kompositionsebene (Bootstrap, Application, Composition, API) reicht den Host weiter.
 * Feature-Module bekommen daraus nur, was sie brauchen (ISP), etwa `database` und `runtimeRoot`.
 */
export type LocalRuntimeHost = {
  /** Die eine SQLite-Datenbank des Prozesses (`<runtimeRoot>/novooa.sqlite`) für alle Teams. */
  database: RuntimeDatabase;
  /**
   * Wurzelverzeichnis aus `LOCAL_RUNTIME_ROOT`: Datenbank, Dateiablage, Skills, Modellartefakte
   * und Prozesssperre liegen darunter.
   */
  runtimeRoot: string;
  /** Verschlüsselt sensible Datenbankfelder (Passwörter, API-Schlüssel) mit dem lokalen Schlüsselbund. */
  fieldCipher: SensitiveFieldCipher;
};
