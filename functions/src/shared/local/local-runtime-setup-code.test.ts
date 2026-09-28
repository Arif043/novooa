import assert from "node:assert/strict";
import test from "node:test";
import {
  LocalRuntimeSetupCode,
  generateSetupCode,
} from "./local-runtime-setup-code.js";

test("erzeugt bei jedem Aufruf einen anderen Code", () => {
  const codes = new Set(Array.from({length: 50}, () => generateSetupCode()));

  assert.equal(codes.size, 50);
});

test("der Code ist hex und kurz genug zum Abtippen", () => {
  assert.match(generateSetupCode(), /^[0-9a-f]{12}$/);
});

test("akzeptiert genau den erzeugten Code", () => {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");

  assert.equal(setupCode.matches("abc123abc123"), true);
});

test("verzeiht Leerzeichen und Grossschreibung beim Abtippen", () => {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");

  assert.equal(setupCode.matches("  ABC123abc123 "), true);
});

test("lehnt einen falschen Code ab", () => {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");

  assert.equal(setupCode.matches("abc123abc124"), false);
  assert.equal(setupCode.matches("zu-kurz"), false);
  assert.equal(setupCode.matches(""), false);
});

test("lehnt alles ab, was kein String ist", () => {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");

  assert.equal(setupCode.matches(undefined), false);
  assert.equal(setupCode.matches(null), false);
  assert.equal(setupCode.matches(42), false);
  assert.equal(setupCode.matches({}), false);
});

test("nach dem Verbrauch passt kein Code mehr — auch nicht der richtige", () => {
  const setupCode = new LocalRuntimeSetupCode(() => "abc123abc123");

  setupCode.consume();

  assert.equal(setupCode.current, null);
  assert.equal(setupCode.matches("abc123abc123"), false);
});
