import assert from "node:assert/strict";
import test from "node:test";
import {mediaInputNodeExecutor} from "./media-input-node-executor.js";

test("pauses a run and preserves the media interaction", async () => {
  const result = await mediaInputNodeExecutor.execute({
    node: {
      id: "media",
      primitive: "mediaInput",
      config: {
        primitive: "mediaInput",
        instruction: "Foto von {{object}} aufnehmen.",
        source: "camera",
      },
    },
  } as never, {
    resolveTemplates: (value: string) => value.replace("{{object}}", "Beleg"),
  } as never);

  assert.equal(result.status, "waitingForApproval");
  assert.deepEqual(result.interaction, {
    kind: "mediaInput",
    instruction: "Foto von Beleg aufnehmen.",
    source: "camera",
  });
});
