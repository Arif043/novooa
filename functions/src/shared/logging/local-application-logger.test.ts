import assert from "node:assert/strict";
import test from "node:test";
import {LocalApplicationLogger} from "./local-application-logger.js";
import {type LocalApplicationLog, type LocalApplicationLogStore} from "./local-application-log-store.js";

test("persists structured local application logs", async () => {
  const store = new MemoryApplicationLogStore();
  const logger = new LocalApplicationLogger(store, "team-1", {
    clock: () => new Date("2026-09-09T10:00:00.000Z"),
    writeToConsole: false,
  });

  logger.info("task_run.started", {runId: "run-1"});
  logger.exception("task_run.failed", new Error("Ausfuehrung fehlgeschlagen"));
  logger.readableInfo("[Aufgabe] Startet");
  await logger.flush();

  assert.equal(store.items.length, 3);
  assert.deepEqual(store.items.map((log) => log.event), [
    "task_run.started", "task_run.failed", "application.message",
  ]);
  assert.equal(store.items[1]?.data.error instanceof Object, true);
  assert.equal(store.items[2]?.message, "[Aufgabe] Startet");
  assert.deepEqual(store.items.map((log) => log.source), ["runtime", "runtime", "runtime"]);
});

test("readable entries can carry their own event name and keep their level", async () => {
  const store = new MemoryApplicationLogStore();
  const logger = new LocalApplicationLogger(store, "team-1", {writeToConsole: false});

  logger.readableInfo("[Script-Log]\nhallo", "script_node.stdout");
  logger.readableError("[Script-Fehlerausgabe]\nwarnung", "script_node.stderr");
  logger.readableError("Fehler ohne Ereignis");
  await logger.flush();

  assert.deepEqual(store.items.map((log) => [log.level, log.event]), [
    ["info", "script_node.stdout"], ["error", "script_node.stderr"], ["error", "application.message"],
  ]);
});

class MemoryApplicationLogStore implements LocalApplicationLogStore {
  readonly items: LocalApplicationLog[] = [];

  async append(log: LocalApplicationLog): Promise<void> {
    this.items.push(log);
  }

  async recent(): Promise<LocalApplicationLog[]> {
    return this.items;
  }
}
