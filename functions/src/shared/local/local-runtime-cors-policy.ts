/**
 * Entscheidet, welche Browser-Herkünfte die Runtime ansprechen dürfen.
 *
 * Im vorgesehenen Betrieb liefert die Runtime die App selbst aus — dann ist
 * jede Anfrage Same Origin und CORS gegenstandslos. Native Clients senden
 * gar keinen `Origin` und sind von CORS ohnehin nicht betroffen; es ist ein
 * reiner Browser-Mechanismus.
 *
 * Gebraucht wird es allein für die **lokale Entwicklung**:
 * `flutter run -d chrome` läuft auf `localhost:59193`, die Runtime auf
 * `:8090` — verschiedene Ports sind verschiedene Origins. Deshalb ist die
 * Liste per Env konfigurierbar und **standardmäßig leer**: im Betrieb ist
 * nichts geöffnet, und es gibt bewusst kein pauschales `*`.
 */
export class LocalRuntimeCorsPolicy {
  constructor(private readonly allowedOrigins: ReadonlySet<string> = new Set()) {}

  static fromEnvironment(
    configured: string | undefined = process.env.LOCAL_RUNTIME_ALLOWED_ORIGINS,
  ): LocalRuntimeCorsPolicy {
    const origins = (configured ?? "")
      .split(",")
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0);
    return new LocalRuntimeCorsPolicy(new Set(origins));
  }

  /**
   * Ohne `Origin` ist es kein Browser-Aufruf (nativer Client) — durchlassen.
   * Stimmt die Herkunft mit dem angesprochenen Host überein, ist es Same
   * Origin. Sonst muss sie ausdrücklich erlaubt sein.
   */
  allows(origin: string | undefined, host: string | undefined): boolean {
    if (origin === undefined || origin.length === 0) return true;
    if (host !== undefined && origin === `http://${host}`) return true;
    if (host !== undefined && origin === `https://${host}`) return true;
    return this.allowedOrigins.has(origin);
  }

  /** Nur für ausdrücklich erlaubte Fremd-Herkünfte nötig. */
  headersFor(origin: string | undefined): Record<string, string> | null {
    if (origin === undefined || !this.allowedOrigins.has(origin)) return null;
    return {
      "access-control-allow-origin": origin,
      "access-control-allow-methods": "GET, POST, PUT, DELETE, OPTIONS",
      "access-control-allow-headers": "authorization, content-type",
      "access-control-max-age": "600",
      // Die Antwort hängt von der Herkunft ab — sonst könnte ein Cache die
      // Freigabe einer Origin an eine andere ausliefern.
      vary: "Origin",
    };
  }
}
