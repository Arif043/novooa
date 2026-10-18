import {err, ok, type Result} from "neverthrow";
import {type ScriptPackageInstallFailure} from "../../domain/repositories/script-package-installer.js";
import {type ScriptPackageProbe} from "../../domain/repositories/script-package-probe.js";

/** Wartezeit auf einen freien Platz im Script-Dienst (30 s) plus Laufzeit der Probe. */
const probeTimeoutMs = 60_000;

/** Fragt den Script-Dienst (`POST /probe`); ist er nicht erreichbar, wirft der Aufruf. */
export class HttpScriptPackageProbe implements ScriptPackageProbe {
  private readonly url: URL;

  constructor(scriptRunnerEndpoint: string) {
    this.url = new URL("/probe", scriptRunnerEndpoint);
  }

  async check(id: string, packages: readonly string[]): Promise<Result<void, ScriptPackageInstallFailure>> {
    const body = await this.post({environment: id, packages});
    if (body.loadable === true) return ok(undefined);
    const error = typeof body.error === "string" ? body.error : "";
    const detail = typeof body.module === "string" ? `${body.module}: ${error}` : error;
    return err({reason: "notLoadable", detail});
  }

  private async post(body: unknown): Promise<Record<string, unknown>> {
    let response: Response;
    try {
      response = await fetch(this.url, {
        method: "POST", headers: {"content-type": "application/json"},
        body: JSON.stringify(body), signal: AbortSignal.timeout(probeTimeoutMs),
      });
    } catch {
      throw new Error("Der Script-Dienst ist für die Paketprobe nicht erreichbar.");
    }
    if (!response.ok) throw new Error(`Der Script-Dienst hat die Paketprobe abgelehnt (${response.status}).`);
    return await response.json() as Record<string, unknown>;
  }
}
