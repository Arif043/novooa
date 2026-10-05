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

  /** Wahrheitswert; ohne Eingabe `false`. Akzeptiert auch „true“/„false“ als Text. */
  boolean(key: string, label: string): boolean {
    const raw = this.params[key];
    if (raw === undefined || raw === null || raw === "") return false;
    const value = typeof raw === "string" ? this.resolveText(raw).trim().toLowerCase() : raw;
    if (value === true || value === "true") return true;
    if (value === false || value === "false" || value === "") return false;
    throw new ShopwareError(`„${label}“ muss ein/aus sein.`);
  }

  /** Ganze Zahl im Bereich oder `undefined`, wenn nichts eingetragen ist. */
  optionalInteger(key: string, label: string, range: {min: number; max: number}): number | undefined {
    const raw = this.params[key];
    if (raw === undefined || raw === null || raw === "") return undefined;
    return this.integer(key, label, {...range, fallback: range.min});
  }

  /** Dezimalzahl (Komma oder Punkt) im Bereich oder `undefined`, wenn nichts eingetragen ist. */
  optionalDecimal(key: string, label: string, range: {min: number; max: number}): number | undefined {
    const raw = this.params[key];
    if (raw === undefined || raw === null || raw === "") return undefined;
    const text = typeof raw === "string" ? this.resolveText(raw).trim().replace(",", ".") : raw;
    if (text === "") return undefined;
    const value = typeof text === "number" ? text : Number(text);
    if (!Number.isFinite(value) || value < range.min || value > range.max) {
      throw new ShopwareError(`„${label}“ muss eine Zahl von ${range.min} bis ${range.max} sein.`);
    }
    return value;
  }

  /** Ein JSON-Objekt aus einem Textfeld; leer ergibt `{}`. */
  jsonObject(key: string, label: string, maxLength = 20_000): Record<string, unknown> {
    const text = this.text(key, maxLength);
    if (text === "") return {};
    let parsed: unknown;
    try {
      parsed = JSON.parse(text);
    } catch {
      throw new ShopwareError(`„${label}“ ist kein gültiges JSON.`);
    }
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      throw new ShopwareError(`„${label}“ muss ein JSON-Objekt sein.`);
    }
    return parsed as Record<string, unknown>;
  }
}
