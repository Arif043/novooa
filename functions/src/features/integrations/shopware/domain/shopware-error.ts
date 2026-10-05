/** Eine Anfrage an Shopware ist gescheitert; die Meldung ist deutsch und für Nutzer:innen bestimmt. */
export class ShopwareError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
    this.name = "ShopwareError";
  }
}

type ShopwareErrorBody = {errors?: Array<{status?: unknown; code?: unknown; title?: unknown; detail?: unknown}>};

/**
 * Macht aus einer Fehlerantwort von Shopware (`{errors: [{status, code, title, detail}]}`) eine verständliche Meldung.
 * Rechte der Integration sind die häufigste Ursache für 403.
 */
export function shopwareFailureMessage(status: number, body: string): string {
  const detail = detailOf(body);
  switch (status) {
  case 401: return "Shopware hat die Anmeldung abgelehnt. Prüfe Zugriffsschlüssel und Geheimen Zugriffsschlüssel der Verbindung.";
  case 403: return `Der Integration in Shopware fehlt eine Berechtigung${detail === "" ? "." : `: ${detail}`}`;
  case 404: return `Shopware kennt diese Adresse oder diesen Datensatz nicht${detail === "" ? "." : `: ${detail}`}`;
  case 429: return "Shopware begrenzt die Anfragen gerade. Versuche es später erneut.";
  default:
    if (status >= 500) return `Shopware meldet einen Fehler (Status ${status})${detail === "" ? "." : `: ${detail}`}`;
    return `Shopware hat die Anfrage abgelehnt (Status ${status})${detail === "" ? "." : `: ${detail}`}`;
  }
}

function detailOf(body: string): string {
  let parsed: ShopwareErrorBody;
  try {
    parsed = JSON.parse(body) as ShopwareErrorBody;
  } catch {
    return "";
  }
  const first = Array.isArray(parsed.errors) ? parsed.errors[0] : undefined;
  const text = typeof first?.detail === "string" ? first.detail : typeof first?.title === "string" ? first.title : "";
  return text.trim().slice(0, 300);
}
