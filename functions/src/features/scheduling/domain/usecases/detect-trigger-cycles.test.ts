import assert from "node:assert/strict";
import test from "node:test";
import {eventTriggerConfigFrom} from "../entities/event-trigger-config.js";
import {type FileWriteSite} from "../entities/file-write-site.js";
import {
  describeCycle,
  findTriggerCycles,
  type AnalyzedTask,
  type AnalyzedTrigger,
} from "./detect-trigger-cycles.js";

const parents: Record<string, string | null> = {eingang: null, ausgang: null, mitte: null, ende: null, unter: "eingang"};
const folderChainOf = (id: string): string[] => {
  const chain: string[] = [];
  for (let current: string | null | undefined = id; current; current = parents[current]) chain.push(current);
  return chain;
};

function site(folderId: string | null, extra: Partial<FileWriteSite> = {}): FileWriteSite {
  return {
    placement: {kind: "folder", folderId}, fileName: "bericht.txt", contentKind: "text",
    contentKindIsCertain: false, ...extra,
  };
}

function task(id: string, ...sites: FileWriteSite[]): AnalyzedTask {
  return {id, title: `Aufgabe ${id}`, sites};
}

function trigger(id: string, taskId: string, config: Record<string, unknown>): AnalyzedTrigger {
  return {id, taskId, config: eventTriggerConfigFrom({source: "fileCreated", ...config})};
}

function watching(folderId: string, includeSubfolders = true) {
  return {target: {kind: "folder", id: folderId, includeSubfolders}};
}

function cyclesOf(tasks: AnalyzedTask[], triggers: AnalyzedTrigger[]) {
  return findTriggerCycles({tasks, triggers, folderChainOf});
}

test("eine Aufgabe, die in ihr eigenes Beobachtungsverzeichnis schreibt, ist eine sichere Selbstschleife", () => {
  const [cycle, ...others] = cyclesOf([task("a", site("eingang"))], [trigger("t1", "a", watching("eingang"))]);

  assert.equal(others.length, 0);
  assert.equal(cycle.selfLoop, true);
  assert.equal(cycle.certain, true);
  assert.deepEqual(cycle.steps.map((step) => step.triggerId), ["t1"]);
});

test("eine Kette ohne Rückweg ist kein Zyklus", () => {
  const cycles = cyclesOf(
    [task("a", site("ausgang")), task("b", site("ende"))],
    [trigger("t1", "a", watching("eingang")), trigger("t2", "b", watching("ausgang"))],
  );

  assert.deepEqual(cycles, []);
});

test("zwei Aufgaben, die sich gegenseitig starten, bilden einen Zyklus", () => {
  const [cycle, ...others] = cyclesOf(
    [task("a", site("ausgang")), task("b", site("eingang"))],
    [trigger("t1", "a", watching("eingang")), trigger("t2", "b", watching("ausgang"))],
  );

  assert.equal(others.length, 0);
  assert.equal(cycle.selfLoop, false);
  assert.equal(cycle.certain, true);
  assert.equal(describeCycle(cycle), "„Aufgabe a“ → „Aufgabe b“ → „Aufgabe a“");
});

test("ein Zyklus über drei Aufgaben wird einmal gemeldet", () => {
  const cycles = cyclesOf(
    [task("a", site("unter")), task("b", site("ausgang")), task("c", site("mitte"))],
    [trigger("t1", "b", watching("eingang")), trigger("t2", "c", watching("ausgang")), trigger("t3", "a", watching("mitte"))],
  );

  assert.equal(cycles.length, 1);
  assert.deepEqual(cycles[0].steps.map((step) => step.taskId), ["a", "b", "c"]);
  assert.deepEqual(cycles[0].steps.map((step) => step.triggerId), ["t1", "t2", "t3"]);
});

test("Unterordner zählen nur mit „Unterordner einbeziehen“", () => {
  const writer = task("a", site("unter"));

  assert.equal(cyclesOf([writer], [trigger("t", "a", watching("eingang", true))]).length, 1);
  assert.equal(cyclesOf([writer], [trigger("t", "a", watching("eingang", false))]).length, 0);
});

test("ohne Ziel gilt jede Schreibstelle als Treffer", () => {
  assert.equal(cyclesOf([task("a", site("ausgang"))], [trigger("t", "a", {})]).length, 1);
});

test("eine neue Version einer bekannten Datei in unbekanntem Verzeichnis ist nur möglich", () => {
  const writer = task("a", site(null, {placement: {kind: "existingFile", fileId: "f1"}}));
  const [cycle] = cyclesOf([writer], [trigger("t", "a", {source: "fileVersionCreated", ...watching("eingang")})]);

  assert.equal(cycle.certain, false);
});

test("eine Datei-Beobachtung trifft die Version genau dieser Datei sicher", () => {
  const writer = task("a", site(null, {placement: {kind: "existingFile", fileId: "f1"}}));
  const match = {source: "fileVersionCreated", target: {kind: "file", id: "f1", label: "x"}};
  const other = {source: "fileVersionCreated", target: {kind: "file", id: "f2", label: "y"}};

  assert.equal(cyclesOf([writer], [trigger("t", "a", match)])[0].certain, true);
  assert.deepEqual(cyclesOf([writer], [trigger("t", "a", other)]), []);
});

test("fileVersionCreated entsteht durch neue Dateien nur in der obersten Ebene", () => {
  const config = {source: "fileVersionCreated"};

  assert.equal(cyclesOf([task("a", site(null))], [trigger("t", "a", config)])[0].certain, false);
  assert.deepEqual(cyclesOf([task("a", site("ausgang"))], [trigger("t", "a", config)]), []);
});

test("Lösch- und Nachrichtenquellen erzeugen keine Kanten", () => {
  const writer = task("a", site("eingang"));

  assert.deepEqual(cyclesOf([writer], [trigger("t", "a", {source: "fileDeleted"})]), []);
  assert.deepEqual(cyclesOf([writer], [trigger("t", "a", {source: "emailReceived"})]), []);
  assert.deepEqual(cyclesOf([writer], [trigger("t", "a", {target: {kind: "channel", id: "c", label: "c"}})]), []);
});

test("ein Textfilter schließt feste Dateinamen aus und lässt Templates offen", () => {
  const filtered = {filter: "rechnung"};

  assert.deepEqual(cyclesOf([task("a", site("eingang"))], [trigger("t", "a", filtered)]), []);
  const templated = task("a", site("eingang", {fileName: "{{kunde}}.txt"}));
  assert.equal(cyclesOf([templated], [trigger("t", "a", filtered)])[0].certain, false);
});

test("Dateitypen: unsichere Typen bleiben möglich, sichere schließen aus", () => {
  const images = {fileKinds: ["image"]};
  const unsure = task("a", site("eingang", {contentKind: "text", contentKindIsCertain: false}));
  const sure = task("a", site("eingang", {contentKind: "text", contentKindIsCertain: true}));

  assert.equal(cyclesOf([unsure], [trigger("t", "a", images)])[0].certain, false);
  assert.deepEqual(cyclesOf([sure], [trigger("t", "a", images)]), []);
});

test("die sichere Kante hat Vorrang vor einer möglichen", () => {
  const writer = task("a", site("eingang", {fileName: null}), site("eingang"));

  const [cycle] = cyclesOf([writer], [trigger("t", "a", {filter: "bericht"})]);

  assert.equal(cycle.certain, true);
});

test("mehrere getrennte Zyklen werden einzeln gemeldet", () => {
  const cycles = cyclesOf(
    [task("a", site("eingang")), task("b", site("ausgang"))],
    [trigger("t1", "a", watching("eingang")), trigger("t2", "b", watching("ausgang"))],
  );

  assert.equal(cycles.length, 2);
  assert.ok(cycles.every((cycle) => cycle.selfLoop));
});
