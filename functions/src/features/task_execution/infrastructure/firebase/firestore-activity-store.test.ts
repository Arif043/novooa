import assert from "node:assert/strict";
import test from "node:test";
import {activityOutputsFor} from "./firestore-activity-store.js";

test("replaces media data URLs with persistable metadata", () => {
  const outputs = activityOutputsFor({
    dataUrl: {type: "string", value: "data:image/png;base64,aW1hZ2U="},
  });

  assert.deepEqual(outputs, {
    dataUrl: {
      type: "json",
      value: {contentType: "image/png", sizeBytes: 5},
    },
  });
});

test("preserves ordinary outputs", () => {
  const outputs = activityOutputsFor({
    text: {type: "string", value: "Hallo"},
  });

  assert.deepEqual(outputs, {text: {type: "string", value: "Hallo"}});
});
