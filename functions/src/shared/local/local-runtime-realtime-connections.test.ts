import assert from "node:assert/strict";
import test from "node:test";
import {
  LocalRuntimeRealtimeConnections,
  RealtimeSessionGuard,
  realtimeSessionEndedCode,
} from "./local-runtime-realtime-connections.js";

function connection(name: string, closedBy: string[]) {
  return {close: (code: number) => { closedBy.push(`${name}:${code}`); }};
}

test("closeOtherSessions keeps only the connections of the current session", () => {
  const closed: string[] = [];
  const connections = new LocalRuntimeRealtimeConnections();
  connections.add(connection("eigene", closed), "aktuell");
  connections.add(connection("fremd-1", closed), "alt");
  connections.add(connection("fremd-2", closed), "anderes-geraet");

  connections.closeOtherSessions("aktuell");

  assert.deepEqual(closed.sort(), [`fremd-1:${realtimeSessionEndedCode}`, `fremd-2:${realtimeSessionEndedCode}`]);
  assert.equal(connections.size, 1);
});

test("the guard closes connections of expired sessions", async () => {
  const closed: string[] = [];
  const connections = new LocalRuntimeRealtimeConnections();
  connections.add(connection("aktiv", closed), "gueltig");
  connections.add(connection("abgelaufen", closed), "abgelaufen");
  const guard = new RealtimeSessionGuard({
    connections, isSessionActive: async (token) => token === "gueltig", isLicenseActive: () => true,
  });

  await guard.sweep();

  assert.deepEqual(closed, [`abgelaufen:${realtimeSessionEndedCode}`]);
});

test("the guard closes every connection once the license is gone", async () => {
  const closed: string[] = [];
  const connections = new LocalRuntimeRealtimeConnections();
  connections.add(connection("a", closed), "s1");
  connections.add(connection("b", closed), "s2");
  const guard = new RealtimeSessionGuard({
    connections, isSessionActive: async () => true, isLicenseActive: () => false,
  });

  await guard.sweep();

  assert.equal(closed.length, 2);
  assert.equal(connections.size, 0);
});

test("a failing check is reported and closes nothing", async () => {
  const failures: unknown[] = [];
  const closed: string[] = [];
  const connections = new LocalRuntimeRealtimeConnections();
  connections.add(connection("a", closed), "s1");
  const guard = new RealtimeSessionGuard({
    connections, isLicenseActive: () => true, onFailure: (error) => failures.push(error),
    isSessionActive: async () => { throw new Error("Datenbank gesperrt"); },
  });

  await guard.sweep();

  assert.equal(failures.length, 1);
  assert.deepEqual(closed, []);
});
