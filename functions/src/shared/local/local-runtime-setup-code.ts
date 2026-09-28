import {randomBytes, timingSafeEqual} from "node:crypto";

/**
 * Der Kopplungscode für die Ersteinrichtung einer nackt installierten
 * Runtime.
 *
 * Er ersetzt die bisherige Netzwerkgrenze (`/v1/setup` nur auf dem
 * loopback-gebundenen Setup-Port) als *Bedienbarkeits*-Grenze, ohne den
 * Vertrauensanker zu verschieben: Der Code steht im Start-Log, und
 * `docker compose logs` zu lesen setzt weiterhin Host-Zugriff voraus.
 * Dadurch kann die Einrichtung von jedem Client aus passieren — auch auf
 * headless installierten Runtimes (VPS, NAS, Raspberry Pi), wo bislang nur
 * SSH-Portweiterleitung blieb.
 *
 * Bewusst **nur im Prozessspeicher**: Es gibt kein Geheimnis at rest, keine
 * Migration, und der Code verfällt zusätzlich bei jedem Neustart. Wer ihn
 * verloren hat, startet die Runtime neu oder nutzt den weiterhin
 * bestehenden Weg über den loopback-gebundenen Setup-Port.
 */
export class LocalRuntimeSetupCode {
  /** `null`, sobald der Code verbraucht wurde. */
  private code: string | null;

  constructor(generate: () => string = generateSetupCode) {
    this.code = generate();
  }

  get current(): string | null {
    return this.code;
  }

  /**
   * Vergleicht in konstanter Zeit. Führende/folgende Leerzeichen und
   * Groß-/Kleinschreibung werden verziehen — der Code wird abgetippt.
   */
  matches(candidate: unknown): boolean {
    const code = this.code;
    if (code === null || typeof candidate !== "string") return false;
    const normalized = Buffer.from(candidate.trim().toLowerCase(), "utf8");
    const expected = Buffer.from(code, "utf8");
    if (normalized.length !== expected.length) return false;
    return timingSafeEqual(normalized, expected);
  }

  /**
   * Nach erfolgreicher Einrichtung hat der Code keinen Zweck mehr und wäre
   * nur noch Angriffsfläche.
   */
  consume(): void {
    this.code = null;
  }
}

/** 48 Bit als Hex — kurz genug zum Abtippen, zu gross zum Raten. */
export function generateSetupCode(): string {
  return randomBytes(6).toString("hex");
}
