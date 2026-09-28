import {type IncomingMessage, type Server} from "node:http";
import {type Socket} from "node:net";
import {WebSocket, WebSocketServer} from "ws";
import {type LocalRuntimeRealtimeSubscriber} from "./local-runtime-realtime-notifier.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";

const realtimePath = "/v1/realtime";

/**
 * `LocalRuntimeApplication` hält die aktive `LocalRuntimeComposition` (und
 * damit Notifier/Ticket-Store) hinter privaten Feldern, weil sie sich beim
 * Workspace-Wechsel austauscht und vor der Lizenzaktivierung noch gar nicht
 * existiert (siehe `handle`/`handleSetup` dort). Dieses Interface hält
 * `local-runtime-realtime-server.ts` unabhängig von `LocalRuntimeComposition`
 * und erzwingt denselben "gerade aktive Instanz, live nachgeschlagen"-Zugriff
 * wie die bestehenden HTTP-Handler.
 */
export interface LocalRuntimeRealtimeGateway {
  consumeRealtimeTicket(ticket: string): boolean;
  subscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void;
  unsubscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void;
}

/**
 * Hängt den Realtime-Endpunkt (`/v1/realtime`) per HTTP-Upgrade an einen
 * bestehenden `http.Server` — kein eigener Port nötig, dieselbe Adresse wie
 * die reguläre API. Die Autorisierung passiert synchron beim Upgrade über
 * ein Einmal-Ticket; danach nimmt die Verbindung nur noch
 * `{"type":"subscribe","topic":...}`-Nachrichten entgegen und wird beim
 * `publish` eines abonnierten Topics benachrichtigt.
 */
export function attachLocalRuntimeRealtimeServer(
  server: Server,
  gateway: LocalRuntimeRealtimeGateway,
  cors: LocalRuntimeCorsPolicy = new LocalRuntimeCorsPolicy(),
): WebSocketServer {
  const wss = new WebSocketServer({noServer: true});

  server.on("upgrade", (request: IncomingMessage, socket: Socket, head: Buffer) => {
    const url = new URL(request.url ?? "", "http://localhost");
    const ticket = url.searchParams.get("ticket");
    // WebSockets sind nicht CORS-gebunden — ohne diese Prüfung könnte jede
    // beliebige Seite im Browser eine Verbindung aufbauen. Native Clients
    // senden keinen `Origin` und bleiben unberührt.
    if (!cors.allows(headerOf(request, "origin"), headerOf(request, "host"))) {
      socket.destroy();
      return;
    }
    if (url.pathname !== realtimePath || ticket === null || !gateway.consumeRealtimeTicket(ticket)) {
      socket.destroy();
      return;
    }
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit("connection", ws, request);
    });
  });

  wss.on("connection", (ws: WebSocket) => {
    const subscribedTopics = new Set<string>();
    ws.on("message", (raw: Buffer) => {
      const topic = subscribeTopicFrom(raw);
      if (topic === null) return;
      subscribedTopics.add(topic);
      gateway.subscribeRealtime(topic, ws);
    });
    ws.on("close", () => {
      for (const topic of subscribedTopics) gateway.unsubscribeRealtime(topic, ws);
    });
  });

  return wss;
}

function subscribeTopicFrom(raw: Buffer): string | null {
  try {
    const message = JSON.parse(raw.toString("utf8")) as unknown;
    if (message === null || typeof message !== "object") return null;
    const {type, topic} = message as Record<string, unknown>;
    if (type !== "subscribe" || typeof topic !== "string" || topic.length === 0) return null;
    return topic;
  } catch {
    return null;
  }
}

function headerOf(request: IncomingMessage, name: "origin" | "host"): string | undefined {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}
