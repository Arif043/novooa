import assert from "node:assert/strict";
import test from "node:test";
import {type FileEvent} from "../../../files/domain/entities/file-event.js";
import {eventTriggerConfigFrom, type EventTriggerConfig} from "../entities/event-trigger-config.js";
import {fileEventMatches, messageTargetMatches} from "./event-trigger-matching.js";

const created: FileEvent = {
  type: "fileCreated", teamId: "t", fileId: "f1", versionId: "v1", displayName: "Bericht.png",
  contentType: "image/png", sizeBytes: 1, folderId: "unterordner", occurredAt: "2026-10-02T10:00:00Z", triggerChain: [],
};
const chain = ["unterordner", "berichte"];

function config(value: Record<string, unknown>): EventTriggerConfig {
  return eventTriggerConfigFrom({source: "fileCreated", ...value});
}

test("ohne Ziel passt jede Datei der Quelle", () => {
  assert.equal(fileEventMatches(config({}), created, chain), true);
});

test("die Quelle muss zum Ereignistyp passen", () => {
  assert.equal(fileEventMatches(config({source: "fileDeleted"}), created, chain), false);
});

test("Verzeichnis-Ziel mit Unterordnern passt auf Eltern in der Kette", () => {
  const target = {kind: "folder", id: "berichte", includeSubfolders: true};
  assert.equal(fileEventMatches(config({target}), created, chain), true);
});

test("Verzeichnis-Ziel ohne Unterordner passt nur auf das direkte Verzeichnis", () => {
  const parent = {kind: "folder", id: "berichte", includeSubfolders: false};
  const direct = {kind: "folder", id: "unterordner", includeSubfolders: false};
  assert.equal(fileEventMatches(config({target: parent}), created, chain), false);
  assert.equal(fileEventMatches(config({target: direct}), created, chain), true);
});

test("Datei-Ziel passt nur auf genau diese Datei", () => {
  assert.equal(fileEventMatches(config({target: {kind: "file", id: "f1"}}), created, chain), true);
  assert.equal(fileEventMatches(config({target: {kind: "file", id: "f2"}}), created, chain), false);
});

test("Kanal-Ziel passt nie auf Datei-Ereignisse", () => {
  assert.equal(fileEventMatches(config({target: {kind: "channel", id: "x"}}), created, chain), false);
});

test("Dateikategorien schränken ein", () => {
  assert.equal(fileEventMatches(config({fileKinds: ["image", "pdf"]}), created, chain), true);
  assert.equal(fileEventMatches(config({fileKinds: ["text"]}), created, chain), false);
});

test("der Filter sucht im Dateinamen, ohne Groß-/Kleinschreibung", () => {
  assert.equal(fileEventMatches(config({filter: "bericht"}), created, chain), true);
  assert.equal(fileEventMatches(config({filter: "rechnung"}), created, chain), false);
});

test("ungültige Ziel-Angaben fallen auf „überall“ zurück", () => {
  assert.deepEqual(eventTriggerConfigFrom({target: {kind: "folder"}}).target, {kind: "any"});
  assert.deepEqual(eventTriggerConfigFrom({target: {kind: "unbekannt", id: "x"}}).target, {kind: "any"});
  assert.deepEqual(eventTriggerConfigFrom({fileKinds: ["image", "quatsch", 3]}).fileKinds, ["image"]);
});

test("der Anzeigename des Ziels bleibt erhalten, ist aber optional", () => {
  const withLabel = eventTriggerConfigFrom({target: {kind: "file", id: "f1", label: " Bericht.pdf "}});
  const withoutLabel = eventTriggerConfigFrom({target: {kind: "file", id: "f1"}});
  assert.deepEqual(withLabel.target, {kind: "file", id: "f1", label: "Bericht.pdf"});
  assert.deepEqual(withoutLabel.target, {kind: "file", id: "f1", label: ""});
});

test("Nachrichten-Ziele unterscheiden Kanal und Connector", () => {
  assert.equal(messageTargetMatches({kind: "any"}, {channelId: "c"}), true);
  assert.equal(messageTargetMatches({kind: "channel", id: "c", label: "Support"}, {channelId: "c"}), true);
  assert.equal(messageTargetMatches({kind: "channel", id: "c", label: "Support"}, {channelId: "c", connectorId: "m"}), false);
  assert.equal(messageTargetMatches({kind: "connector", id: "m", label: "Postfach"}, {channelId: "m", connectorId: "m"}), true);
  assert.equal(messageTargetMatches({kind: "connector", id: "m", label: "Postfach"}, {channelId: "c"}), false);
  assert.equal(messageTargetMatches({kind: "folder", id: "f", label: "Ordner", includeSubfolders: true}, {channelId: "c"}), false);
});
