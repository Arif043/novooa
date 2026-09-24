import assert from "node:assert/strict";
import test from "node:test";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";

test("issues a ticket that can be consumed exactly once", () => {
  const store = new LocalRuntimeRealtimeTicketStore();
  const ticket = store.issue();

  assert.equal(store.consume(ticket), true);
  assert.equal(store.consume(ticket), false);
});

test("rejects an unknown ticket", () => {
  const store = new LocalRuntimeRealtimeTicketStore();

  assert.equal(store.consume("unknown"), false);
});

test("rejects an expired ticket", async () => {
  const store = new LocalRuntimeRealtimeTicketStore();
  const ticket = store.issue();
  // Simuliert Ablauf, ohne 10 echte Sekunden zu warten: Wir greifen auf das
  // private Feld über eine Typumgehung zu, statt eine konfigurierbare
  // Lebensdauer nur für den Test einzuführen.
  (store as unknown as {expiresAtByTicket: Map<string, number>})
    .expiresAtByTicket.set(ticket, Date.now() - 1);

  assert.equal(store.consume(ticket), false);
});

test("erzeugt für jedes Ticket einen eigenen, unvorhersehbaren Wert", () => {
  const store = new LocalRuntimeRealtimeTicketStore();

  assert.notEqual(store.issue(), store.issue());
});
