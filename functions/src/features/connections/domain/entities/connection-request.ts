import {ConnectionRequestError, type ConnectionAuth, type ConnectionInput} from "./connection.js";

type AuthBody = {kind?: string; headerName?: string; tokenUrl?: string; clientId?: string; scope?: string; tokenRequestFormat?: string};
export type ConnectionBody = {name?: string; baseUrl?: string; auth?: AuthBody};

const headerNamePattern = /^[A-Za-z0-9-]{1,64}$/;

/** Prüft und normalisiert die Eingabe einer Verbindung (ohne Geheimnis). */
export function connectionInputFrom(body: ConnectionBody): ConnectionInput {
  const name = (body.name ?? "").trim();
  if (name.length === 0 || name.length > 80) throw new ConnectionRequestError("Der Name muss 1 bis 80 Zeichen lang sein.");
  return {name, baseUrl: httpUrlFrom(body.baseUrl, "Die Basis-URL", true), auth: authFrom(body.auth ?? {})};
}

/** Das Geheimnis (API-Key, Token oder Client-Secret). Leerzeichen und Zeilenumbrüche an den Rändern entfallen. */
export function connectionSecretFrom(value: string | undefined): string {
  const secret = (value ?? "").trim();
  if (secret.length === 0) throw new ConnectionRequestError("Bitte gib das Geheimnis (API-Key, Token oder Client-Secret) an.");
  if (secret.length > 4096) throw new ConnectionRequestError("Das Geheimnis ist zu lang.");
  return secret;
}

function authFrom(auth: AuthBody): ConnectionAuth {
  switch (auth.kind) {
  case "apiKey": {
    const headerName = (auth.headerName ?? "").trim();
    if (!headerNamePattern.test(headerName)) {
      throw new ConnectionRequestError("Der Header-Name darf nur Buchstaben, Ziffern und Bindestriche enthalten (z. B. X-API-Key).");
    }
    return {kind: "apiKey", headerName};
  }
  case "bearer":
    return {kind: "bearer"};
  case "oauthClientCredentials": {
    const clientId = (auth.clientId ?? "").trim();
    if (clientId.length === 0 || clientId.length > 500) throw new ConnectionRequestError("Bitte gib die Client-ID an.");
    const scope = (auth.scope ?? "").trim();
    const format = (auth.tokenRequestFormat ?? "form").trim() || "form";
    if (format !== "form" && format !== "json") throw new ConnectionRequestError("Das Format der Token-Anfrage ist ungültig.");
    return {
      kind: "oauthClientCredentials",
      tokenUrl: httpUrlFrom(auth.tokenUrl, "Die Token-URL", false),
      clientId,
      ...(scope.length === 0 ? {} : {scope: scope.slice(0, 500)}),
      // Nur die Abweichung wird gespeichert: Verbindungen ohne Angabe bleiben unverändert.
      ...(format === "json" ? {tokenRequestFormat: "json" as const} : {}),
    };
  }
  default:
    throw new ConnectionRequestError("Die Anmeldeart ist ungültig.");
  }
}

function httpUrlFrom(value: string | undefined, label: string, stripTrailingSlash: boolean): string {
  let url: URL;
  try {
    url = new URL((value ?? "").trim());
  } catch {
    throw new ConnectionRequestError(`${label} ist keine gültige Adresse.`);
  }
  if (url.protocol !== "https:" && url.protocol !== "http:") throw new ConnectionRequestError(`${label} muss mit https:// oder http:// beginnen.`);
  if (url.username !== "" || url.password !== "") throw new ConnectionRequestError(`${label} darf keine Zugangsdaten enthalten.`);
  if (url.search !== "" || url.hash !== "") throw new ConnectionRequestError(`${label} darf keine Parameter oder Anker enthalten.`);
  const href = url.href;
  return stripTrailingSlash ? href.replace(/\/+$/, "") : href;
}
