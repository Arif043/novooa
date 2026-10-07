import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";

test("issues a ticket that can be consumed exactly once and names its session", () => {
  const store = new LocalRuntimeRealtimeTicketStore();
  const ticket = store.issue("session-a");

  assert.equal(store.consume(ticket), "session-a");
  assert.equal(store.consume(ticket), null);
});

test("rejects an unknown ticket", () => {
  const store = new LocalRuntimeRealtimeTicketStore();

  assert.equal(store.consume("unknown"), null);
});

test("rejects an expired ticket", async () => {
  const store = new LocalRuntimeRealtimeTicketStore();
  const ticket = store.issue("session-a");
  // Simuliert Ablauf, ohne 10 echte Sekunden zu warten: Wir greifen auf das
  // private Feld über eine Typumgehung zu, statt eine konfigurierbare
  // Lebensdauer nur für den Test einzuführen.
  (store as unknown as {ticketsByValue: Map<string, {expiresAt: number; sessionToken: string}>})
    .ticketsByValue.set(ticket, {expiresAt: Date.now() - 1, sessionToken: "session-a"});

  assert.equal(store.consume(ticket), null);
});

test("erzeugt für jedes Ticket einen eigenen, unvorhersehbaren Wert", () => {
  const store = new LocalRuntimeRealtimeTicketStore();

  assert.notEqual(store.issue("session-a"), store.issue("session-a"));
});
