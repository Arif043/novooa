/**
 * Einstiegspunkt des Kindprozesses, in dem Plugin-Code läuft. Er importiert bewusst nichts außer Node-Bordmitteln:
 * Der Prozess startet mit dem Permission-Modell und darf nur diese Datei und den Plugin-Ordner lesen.
 *
 * Protokoll: eine JSON-Anfrage auf stdin, eine JSON-Antwort auf stdout.
 */
type HostRequest = {
  entryUrl: string;
  kind: "primitive";
  type: string;
  settings: Record<string, unknown>;
  panel: Record<string, unknown>;
};

type Handler = (context: {settings: Record<string, unknown>; panel: Record<string, unknown>}) => unknown;

async function readRequest(): Promise<HostRequest> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
  return JSON.parse(Buffer.concat(chunks).toString("utf8")) as HostRequest;
}

async function main(): Promise<void> {
  const request = await readRequest();
  const module = await import(request.entryUrl) as {default?: {primitives?: Record<string, Handler>}};
  const handler = module.default?.primitives?.[request.type];
  if (typeof handler !== "function") throw new Error(`Das Plugin liefert keinen Handler für den Baustein „${request.type}“.`);
  const outputs = await handler({settings: request.settings, panel: request.panel});
  process.stdout.write(JSON.stringify({ok: true, outputs}));
}

main().catch((error: unknown) => {
  process.stdout.write(JSON.stringify({ok: false, error: error instanceof Error ? error.message : String(error)}));
});
