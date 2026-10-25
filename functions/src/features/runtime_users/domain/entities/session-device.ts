export const sessionDeviceOperatingSystems = ["android", "ios", "macos", "windows", "linux", "unknown"] as const;
export type SessionDeviceOs = typeof sessionDeviceOperatingSystems[number];

export type SessionDeviceInput = {app?: string; os?: string; browser?: string | null};

const maxAppLength = 60;
const maxBrowserLength = 40;

/**
 * Was der Client beim Anmelden über sich meldet, damit Personen ihre Geräte wiedererkennen. Die Angaben sind
 * Selbstauskunft und nur Anzeige, nie Grundlage einer Berechtigung; deshalb wird nur gekürzt, nicht abgelehnt.
 */
export class SessionDevice {
  private constructor(
    readonly app: string,
    readonly os: SessionDeviceOs,
    readonly browser: string | null,
  ) {}

  static readonly unknown = new SessionDevice("", "unknown", null);

  static from(input: SessionDeviceInput | undefined): SessionDevice {
    if (input === undefined) return SessionDevice.unknown;
    const browser = clipped(input.browser ?? "", maxBrowserLength);
    return new SessionDevice(clipped(input.app ?? "", maxAppLength), osFrom(input.os), browser === "" ? null : browser);
  }
}

function osFrom(raw: string | undefined): SessionDeviceOs {
  return sessionDeviceOperatingSystems.find((os) => os === raw) ?? "unknown";
}

function clipped(raw: string, maxLength: number): string {
  return raw.trim().slice(0, maxLength);
}
