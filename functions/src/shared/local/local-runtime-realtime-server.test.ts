import assert from "node:assert/strict";
import {createServer} from "node:http";
import test from "node:test";
import {WebSocket} from "ws";
import {
  attachLocalRuntimeRealtimeServer,
  type LocalRuntimeRealtimeGateway,
} from "./local-runtime-realtime-server.js";
import {type LocalRuntimeRealtimeSubscriber} from "./local-runtime-realtime-notifier.js";

class FakeGateway implements LocalRuntimeRealtimeGateway {
  validTickets = new Set<string>();
  subscribedTopics = new Map<string, Set<LocalRuntimeRealtimeSubscriber>>();

  consumeRealtimeTicket(ticket: string): boolean {
    if (!this.validTickets.has(ticket)) return false;
    this.validTickets.delete(ticket);
    return true;
  }

  subscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    const subscribers = this.subscribedTopics.get(topic) ?? new Set();
    subscribers.add(subscriber);
    this.subscribedTopics.set(topic, subscribers);
  }

  unsubscribeRealtime(topic: string, subscriber: LocalRuntimeRealtimeSubscriber): void {
    this.subscribedTopics.get(topic)?.delete(subscriber);
  }

  publish(topic: string): void {
    const message = JSON.stringify({type: "changed", topic});
    for (const subscriber of this.subscribedTopics.get(topic) ?? []) subscriber.send(message);
  }
}

async function withServer(
  run: (port: number, gateway: FakeGateway) => Promise<void>,
): Promise<void> {
  const server = createServer((_, response) => response.end());
  const gateway = new FakeGateway();
  attachLocalRuntimeRealtimeServer(server, gateway);
  await new Promise<void>((resolve) => server.listen(0, resolve));
  const address = server.address();
  if (address === null || typeof address === "string") throw new Error("no port");
  try {
    await run(address.port, gateway);
  } finally {
    server.close();
  }
}

function nextMessage(socket: WebSocket): Promise<unknown> {
  return new Promise((resolve) => {
    socket.once("message", (raw: Buffer) => resolve(JSON.parse(raw.toString("utf8"))));
  });
}

function opened(socket: WebSocket): Promise<void> {
  return new Promise((resolve, reject) => {
    socket.once("open", () => resolve());
    socket.once("error", reject);
  });
}

function closed(socket: WebSocket): Promise<number> {
  return new Promise((resolve) => socket.once("close", (code: number) => resolve(code)));
}

/**
 * Ein per Socket-Destroy abgelehnter Upgrade (kein HTTP-Response, keine
 * WebSocket-Handshake-Antwort) erreicht auf Client-Seite nicht zuverlässig
 * ein "close"-Event — je nach Timing meldet `ws` stattdessen "error"
 * (z.B. ECONNRESET) oder "unexpected-response". Beide Fälle zählen hier als
 * Ablehnung; ein eigener "error"-Listener verhindert außerdem, dass Node
 * bei einem unbehandelten "error"-Event den Testlauf abbricht.
 */
function rejected(socket: WebSocket): Promise<void> {
  return new Promise((resolve) => {
    let settled = false;
    const settle = () => {
      if (settled) return;
      settled = true;
      resolve();
    };
    socket.once("error", settle);
    socket.once("close", settle);
    socket.once("unexpected-response", settle);
  });
}

test("lehnt den Upgrade ohne gültiges Ticket ab", async () => {
  await withServer(async (port) => {
    const socket = new WebSocket(`ws://127.0.0.1:${port}/v1/realtime?ticket=unknown`);
    let didOpen = false;
    socket.once("open", () => {
      didOpen = true;
    });

    await rejected(socket);

    assert.equal(didOpen, false);
  });
});

test("akzeptiert den Upgrade mit gültigem Ticket und verbraucht es sofort", async () => {
  await withServer(async (port, gateway) => {
    gateway.validTickets.add("ticket-1");
    const socket = new WebSocket(`ws://127.0.0.1:${port}/v1/realtime?ticket=ticket-1`);
    await opened(socket);

    assert.equal(gateway.consumeRealtimeTicket("ticket-1"), false);
    socket.close();
    await closed(socket);
  });
});

test("liefert eine changed-Nachricht für ein abonniertes Topic", async () => {
  await withServer(async (port, gateway) => {
    gateway.validTickets.add("ticket-1");
    const socket = new WebSocket(`ws://127.0.0.1:${port}/v1/realtime?ticket=ticket-1`);
    await opened(socket);
    socket.send(JSON.stringify({type: "subscribe", topic: "task-runs"}));
    await new Promise((resolve) => setTimeout(resolve, 20));

    gateway.publish("task-runs");
    const message = await nextMessage(socket);

    assert.deepEqual(message, {type: "changed", topic: "task-runs"});
    socket.close();
    await closed(socket);
  });
});

test("lehnt einen Upgrade auf einen fremden Pfad ab", async () => {
  await withServer(async (port, gateway) => {
    gateway.validTickets.add("ticket-1");
    const socket = new WebSocket(`ws://127.0.0.1:${port}/not-realtime?ticket=ticket-1`);
    let didOpen = false;
    socket.once("open", () => {
      didOpen = true;
    });

    await rejected(socket);

    assert.equal(didOpen, false);
  });
});
