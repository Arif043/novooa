import assert from "node:assert/strict";
import test from "node:test";
import {mediaInputNodeExecutor} from "./media-input-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

const runContext = {
  templateExpressionResolver: {
    resolveText: (value: string) => value.replace("{{object}}", "Beleg"),
  },
} as never;

test("pauses a run and preserves the media interaction", async () => {
  const result = succeeded(await mediaInputNodeExecutor.execute({
      id: "media",
      primitive: "mediaInput",
      config: {
        primitive: "mediaInput",
        instruction: "Foto von {{object}} aufnehmen.",
        documentScanEnabled: false,
      },
  } as never, runContext));

  assert.equal(result.status, "waitingForApproval");
  assert.deepEqual(result.interaction, {
    kind: "mediaInput",
    instruction: "Foto von Beleg aufnehmen.",
    documentScanEnabled: false,
  });
});

test("passes documentScanEnabled through to the interaction", async () => {
  const result = succeeded(await mediaInputNodeExecutor.execute({
      id: "media",
      primitive: "mediaInput",
      config: {
        primitive: "mediaInput",
        instruction: "Beleg fotografieren.",
        documentScanEnabled: true,
      },
  } as never, runContext));

  assert.deepEqual(result.interaction, {
    kind: "mediaInput",
    instruction: "Beleg fotografieren.",
    documentScanEnabled: true,
  });
});

test("defaults documentScanEnabled to false for legacy configs without the field", async () => {
  const result = succeeded(await mediaInputNodeExecutor.execute({
      id: "media",
      primitive: "mediaInput",
      config: {
        primitive: "mediaInput",
        instruction: "Beleg fotografieren.",
      },
  } as never, runContext));

  assert.deepEqual(result.interaction, {
    kind: "mediaInput",
    instruction: "Beleg fotografieren.",
    documentScanEnabled: false,
  });
});
