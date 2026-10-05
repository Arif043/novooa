import {ShopwareError} from "./shopware-error.js";

/**
 * Liest die Eingaben einer Aktion. `params` stammt aus dem gespeicherten Baustein und ist ungeprüft; Fehler nennen das
 * Feld in der Sprache der Oberfläche, damit Nutzer:innen wissen, was zu ändern ist.
 */
export class ShopwareParams {
  constructor(
    private readonly params: Record<string, unknown>,
    private readonly resolveText: (template: string) => string,
  ) {}

  /** Text mit eingesetzten `{{…}}`-Ausdrücken, getrimmt; leer, wenn nichts eingetragen ist. */
  text(key: string, maxLength = 500): string {
    const raw = this.params[key];
    if (raw === undefined || raw === null) return "";
    if (typeof raw !== "string") throw new ShopwareError(`Die Eingabe „${key}“ muss ein Text sein.`);
    const resolved = this.resolveText(raw).trim();
    if (resolved.length > maxLength) throw new ShopwareError(`Die Eingabe „${key}“ ist zu lang.`);
    return resolved;
  }

  /** Einer der erlaubten Werte; leer, wenn keiner gewählt ist. */
  choice<Value extends string>(key: string, allowed: readonly Value[], label: string): Value | "" {
    const value = this.text(key, 100);
    if (value === "") return "";
    const match = allowed.find((candidate) => candidate === value);
    if (match === undefined) throw new ShopwareError(`„${value}“ ist für „${label}“ nicht erlaubt.`);
    return match;
  }

  /** Ganze Zahl im Bereich; ohne Eingabe gilt der Vorgabewert. */
  integer(key: string, label: string, range: {min: number; max: number; fallback: number}): number {
    const raw = this.params[key];
    if (raw === undefined || raw === null || raw === "") return range.fallback;
    const value = typeof raw === "string" ? Number(this.resolveText(raw).trim()) : raw;
    if (typeof value !== "number" || !Number.isInteger(value) || value < range.min || value > range.max) {
      throw new ShopwareError(`„${label}“ muss eine ganze Zahl von ${range.min} bis ${range.max} sein.`);
    }
    return value;
  }

  /** Zeitpunkt als ISO-8601-String (UTC); leer, wenn nichts eingetragen ist. Akzeptiert auch reine Datumsangaben. */
  dateTime(key: string, label: string): string {
    const value = this.text(key, 100);
    if (value === "") return "";
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) throw new ShopwareError(`„${label}“: „${value}“ ist kein gültiges Datum.`);
    return date.toISOString();
  }
}
