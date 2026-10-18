import {err, ok, type Result} from "neverthrow";
import {
  type InstalledScriptPackageEnvironment,
  type ScriptPackageInstaller,
  type ScriptPackageInstallFailure,
  type ScriptPackageInstallProblem,
} from "../../domain/repositories/script-package-installer.js";

/** Installieren kann Minuten dauern (große Pakete, langsames Netz); der Dienst bricht selbst nach 15 Minuten ab. */
const installTimeoutMs = 16 * 60 * 1000;
const requestTimeoutMs = 20_000;
const problems: readonly ScriptPackageInstallProblem[] = ["notFound", "noWheel", "tooLarge", "failed"];

/** Spricht mit dem Paketdienst `novooa-packages`; ist er nicht erreichbar, wirft der Aufruf. */
export class HttpScriptPackageInstaller implements ScriptPackageInstaller {
  constructor(private readonly endpoint: string) {}

  async list(): Promise<InstalledScriptPackageEnvironment[]> {
    const body = await this.request("GET", "/environments", undefined, requestTimeoutMs);
    return Array.isArray(body.items) ? body.items as InstalledScriptPackageEnvironment[] : [];
  }

  async install(
    id: string, packages: readonly string[],
  ): Promise<Result<InstalledScriptPackageEnvironment, ScriptPackageInstallFailure>> {
    const response = await this.send("POST", "/environments", {id, packages}, installTimeoutMs);
    const body = await response.json().catch(() => ({})) as Record<string, unknown>;
    if (response.ok) return ok(body as InstalledScriptPackageEnvironment);
    if (response.status === 422) return err(failureFrom(body));
    throw new Error(`Der Paketdienst hat die Installation abgelehnt (${response.status}).`);
  }

  async remove(id: string): Promise<void> {
    await this.request("DELETE", `/environments/${encodeURIComponent(id)}`, undefined, requestTimeoutMs);
  }

  private async request(method: string, path: string, body: unknown, timeoutMs: number): Promise<Record<string, unknown>> {
    const response = await this.send(method, path, body, timeoutMs);
    if (!response.ok) throw new Error(`Der Paketdienst antwortet mit ${response.status}.`);
    return response.status === 204 ? {} : await response.json() as Record<string, unknown>;
  }

  private async send(method: string, path: string, body: unknown, timeoutMs: number): Promise<Response> {
    try {
      return await fetch(new URL(path, this.endpoint), {
        method,
        headers: body === undefined ? undefined : {"content-type": "application/json"},
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch {
      throw new Error("Der Paketdienst ist nicht erreichbar.");
    }
  }
}

function failureFrom(body: Record<string, unknown>): ScriptPackageInstallFailure {
  const reason = problems.find((problem) => problem === body.reason) ?? "failed";
  return {reason, detail: typeof body.detail === "string" ? body.detail : ""};
}
