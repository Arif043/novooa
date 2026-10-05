import {randomBytes} from "node:crypto";

export const webhookHmacAlgorithms = ["sha256", "sha512"] as const;
export const webhookSignatureEncodings = ["hex", "base64"] as const;

export type WebhookVerification =
  | {kind: "none"}
  | {
    kind: "hmac";
    /** Name der Kopfzeile, die die Signatur trägt (kleingeschrieben). */
    header: string;
    algorithm: (typeof webhookHmacAlgorithms)[number];
    encoding: (typeof webhookSignatureEncodings)[number];
    /** Steht vor der Signatur, z. B. `sha256=`. */
    prefix: string;
  };

/** Das Geheimnis der Signaturprüfung gehört nicht hierher: Es liegt verschlüsselt im Secret-Speicher. */
export type WebhookConfig = {
  token: string;
  verification: WebhookVerification;
  /** Query-Parameter, den ein Absender beim Einrichten erwartet zurückzubekommen (Microsoft Graph: `validationToken`). Leer = kein Handshake. */
  validationParameter: string;
};

const headerNamePattern = /^[a-z0-9-]{1,100}$/;
const parameterNamePattern = /^[A-Za-z0-9_-]{1,64}$/;

export function generateWebhookToken(): string {
  return randomBytes(32).toString("base64url");
}

/** Tolerant beim Lesen: Unbekanntes fällt auf sichere Vorgaben zurück. Streng prüft `assertWebhookConfig`. */
export function webhookConfigFrom(value: unknown): WebhookConfig {
  const data = isRecord(value) ? value : {};
  return {
    token: typeof data.token === "string" ? data.token : "",
    verification: verificationFrom(data.verification),
    validationParameter: typeof data.validationParameter === "string" ? data.validationParameter.trim() : "",
  };
}

/** Fehlermeldung für eine unbrauchbare Eingabe, sonst `null`. */
export function webhookConfigProblem(config: WebhookConfig, hasSecret: boolean): string | null {
  if (config.validationParameter.length > 0 && !parameterNamePattern.test(config.validationParameter)) {
    return "Der Parametername für die Einrichtungsprüfung ist ungültig.";
  }
  if (config.verification.kind === "none") return null;
  if (!headerNamePattern.test(config.verification.header)) return "Der Name der Signatur-Kopfzeile ist ungültig.";
  if (config.verification.prefix.length > 50) return "Das Präfix der Signatur ist zu lang.";
  return hasSecret ? null : "Für die Signaturprüfung ist ein Geheimnis nötig.";
}

function verificationFrom(value: unknown): WebhookVerification {
  const data = isRecord(value) ? value : {};
  if (data.kind !== "hmac") return {kind: "none"};
  return {
    kind: "hmac",
    header: typeof data.header === "string" ? data.header.trim().toLowerCase() : "",
    algorithm: webhookHmacAlgorithms.find((algorithm) => algorithm === data.algorithm) ?? "sha256",
    encoding: webhookSignatureEncodings.find((encoding) => encoding === data.encoding) ?? "hex",
    prefix: typeof data.prefix === "string" ? data.prefix : "",
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
