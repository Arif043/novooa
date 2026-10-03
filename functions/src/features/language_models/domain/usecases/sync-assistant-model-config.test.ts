import assert from "node:assert/strict";
import test from "node:test";
import {syncAssistantModelConfig} from "./sync-assistant-model-config.js";

function ports(current: string | null, published: string | null | undefined) {
  const written: (string | null)[] = [];
  return {
    written,
    ports: {
      readCurrent: async () => current,
      readPublished: async () => published,
      publish: async (name: string | null) => { written.push(name); },
    },
  };
}

test("veröffentlicht einen neuen Namen", async () => {
  const {ports: p, written} = ports("gemini-2.5-pro", "gemini-2.5-flash");

  assert.equal(await syncAssistantModelConfig(p), "published");
  assert.deepEqual(written, ["gemini-2.5-pro"]);
});

test("veröffentlicht beim allerersten Mal, auch wenn kein Name gesetzt ist", async () => {
  const {ports: p, written} = ports(null, undefined);

  assert.equal(await syncAssistantModelConfig(p), "published");
  assert.deepEqual(written, [null]);
});

test("ein unveränderter Name weckt die Runtimes nicht", async () => {
  const {ports: p, written} = ports("gemini-2.5-flash", "gemini-2.5-flash");

  assert.equal(await syncAssistantModelConfig(p), "unchanged");
  assert.deepEqual(written, []);
});

test("das Zurücksetzen auf keinen Namen wird veröffentlicht", async () => {
  const {ports: p, written} = ports(null, "gemini-2.5-flash");

  assert.equal(await syncAssistantModelConfig(p), "published");
  assert.deepEqual(written, [null]);
});
