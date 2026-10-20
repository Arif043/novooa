import {RuntimeUserError} from "./runtime-user-error.js";

const pattern = /^[a-z0-9._-]{3,64}$/;

/** Anmeldename eines Kontos: klein geschrieben, 3–64 Zeichen aus `a–z`, `0–9`, `.`, `_`, `-`. */
export class LoginName {
  private constructor(readonly value: string) {}

  static from(raw: string): LoginName {
    const normalized = raw.trim().toLowerCase();
    if (!pattern.test(normalized)) {
      throw new RuntimeUserError("invalid_input",
        "Der Anmeldename braucht 3 bis 64 Zeichen aus Buchstaben a–z, Ziffern, Punkt, Unterstrich oder Bindestrich.");
    }
    return new LoginName(normalized);
  }

  /** Wie [from], liefert für ungültige Eingaben aber `null` – bei der Anmeldung soll kein Formatfehler verraten werden. */
  static tryFrom(raw: string): LoginName | null {
    try {
      return LoginName.from(raw);
    } catch {
      return null;
    }
  }
}
