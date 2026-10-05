/**
 * Einstiegspunkt des Kindprozesses, in dem Plugin-Code läuft. Er importiert bewusst nichts außer Node-Bordmitteln:
 * Der Prozess startet mit dem Permission-Modell und darf nur diese Datei und den Plugin-Ordner lesen.
 *
 * Protokoll: eine JSON-Anfrage auf stdin, eine JSON-Antwort auf stdout.
 */
type HostRequest = {
  entryUrl: string;
  kind: "primitive" | "trigger";
  type: string;
  settings: Record<string, unknown>;
  panel: Record<string, unknown>;
  /** Nur für Trigger: der zuletzt zurückgegebene Zustand. */
  state?: unknown;
};

type Handler = (context: {settings: Record<string, unknown>; panel: Record<string, unknown>; state?: unknown}) => unknown;
type PluginModule = {default?: {primitives?: Record<string, Handler>; triggers?: Record<string, Handler>}};

async function readRequest(): Promise<HostRequest> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
  return JSON.parse(Buffer.concat(chunks).toString("utf8")) as HostRequest;
}

async function main(): Promise<void> {
  const request = await readRequest();
  const module = await import(request.entryUrl) as PluginModule;
  const handlers = request.kind === "trigger" ? module.default?.triggers : module.default?.primitives;
  const handler = handlers?.[request.type];
  if (typeof handler !== "function") {
    throw new Error(`Das Plugin liefert keinen Handler für ${request.kind === "trigger" ? "den Trigger" : "den Baustein"} „${request.type}“.`);
  }
  const outputs = await handler({settings: request.settings, panel: request.panel, state: request.state});
  process.stdout.write(JSON.stringify({ok: true, outputs}));
}

main().catch((error: unknown) => {
  process.stdout.write(JSON.stringify({ok: false, error: error instanceof Error ? error.message : String(error)}));
});
