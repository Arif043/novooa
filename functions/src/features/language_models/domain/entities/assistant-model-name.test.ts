import assert from "node:assert/strict";
import test from "node:test";
import {assistantModelNameFrom} from "./assistant-model-name.js";

test("akzeptiert übliche Google-Modellnamen", () => {
  assert.equal(assistantModelNameFrom("gemini-2.5-flash"), "gemini-2.5-flash");
  assert.equal(assistantModelNameFrom("gemini-3.1-flash-lite"), "gemini-3.1-flash-lite");
});

test("entfernt umgebende Leerzeichen", () => {
  assert.equal(assistantModelNameFrom("  gemini-2.5-pro \n"), "gemini-2.5-pro");
});

test("leer oder ungültig bedeutet nicht gesetzt", () => {
  for (const raw of ["", "   ", "Gemini Flash", "models/gemini", "gemini;rm", "-gemini", "a".repeat(101)]) {
    assert.equal(assistantModelNameFrom(raw), null, raw);
  }
});
