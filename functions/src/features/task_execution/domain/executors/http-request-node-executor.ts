import {OutboundHttpError} from "../../../connections/domain/repositories/outbound-http-client.js";
import {type NodeOutputValue} from "../entities/workflow-value.js";
import {type NodeExecutor, executedNode} from "./node-executor.js";

const errorExcerptLength = 300;

export const httpRequestNodeExecutor: NodeExecutor = {
  primitive: "httpRequest",
  async execute(node, runContext) {
    if (node.config.primitive !== "httpRequest") throw new Error("Der Baustein ist keine HTTP-Anfrage.");
    const config = node.config;
    const client = runContext.outboundHttpClient;
    if (client === undefined) throw new OutboundHttpError("HTTP-Anfragen sind in dieser Betriebsvariante nicht verfügbar.");
    const resolve = (text: string) => runContext.templateExpressionResolver.resolveText(text);

    const sendsBody = config.bodyType !== "none" && config.method !== "GET";
    const body = sendsBody ? resolve(config.body) : undefined;
    if (body !== undefined && config.bodyType === "json" && body.trim() !== "" && !isJson(body)) {
      throw new OutboundHttpError("Der Body ist nach dem Einsetzen der Werte kein gültiges JSON. Prüfe Anführungszeichen in eingesetzten Werten.");
    }
    const headers = Object.fromEntries(config.headers
      .filter((header) => header.name.trim() !== "")
      .map((header) => [header.name.trim(), resolve(header.value)]));
    if (body !== undefined && config.bodyType === "json" && !Object.keys(headers).some((name) => name.toLowerCase() === "content-type")) {
      headers["content-type"] = "application/json";
    }

    const response = await client.send({
      teamId: runContext.teamId,
      connectionId: config.connectionId === undefined || config.connectionId === "" ? undefined : config.connectionId,
      method: config.method,
      url: resolve(config.url),
      query: config.query.map((entry) => ({name: resolve(entry.name).trim(), value: resolve(entry.value)})),
      headers,
      ...(body === undefined ? {} : {body}),
      timeoutMs: config.timeoutSeconds * 1000,
    });

    const ok = response.status >= 200 && response.status < 300;
    if (!ok && config.failOnHttpError) {
      const excerpt = response.body.trim().slice(0, errorExcerptLength);
      throw new OutboundHttpError(`Die Anfrage ist mit Status ${response.status} fehlgeschlagen${excerpt === "" ? "." : `: ${excerpt}`}`);
    }
    return executedNode(node, {
      value: {type: "json", value: parsed(response.body)},
      status: {type: "number", value: response.status},
      ok: {type: "boolean", value: ok},
      headers: {type: "json", value: response.headers},
    } satisfies Record<string, NodeOutputValue>);
  },
};

function isJson(text: string): boolean {
  try {
    JSON.parse(text);
    return true;
  } catch {
    return false;
  }
}

/** JSON-Antworten werden ausgewertet (`{{antwort.feld}}`), alles andere bleibt Text. */
function parsed(body: string): unknown {
  if (body.trim() === "") return null;
  try {
    return JSON.parse(body) as unknown;
  } catch {
    return body;
  }
}
