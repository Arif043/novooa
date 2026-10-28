import assert from "node:assert/strict";
import test from "node:test";
import {RunEffectRecorder} from "./run-effect-recorder.js";

const notification = {kind: "notificationSent", title: "Fertig"} as const;

test("an effect names the node that caused it and reaches the enclosing node", () => {
  const loop = RunEffectRecorder.root().child("schleife");
  const inner = loop.child("datei-schreiben", 2);

  inner.record(notification);

  assert.deepEqual(inner.effects, [{...notification, sourceNodeId: "datei-schreiben", iteration: 2}]);
  assert.deepEqual(loop.effects, inner.effects, "the loop sees the effect of its inner node");
});

test("a branch inside a loop round keeps the round of the loop", () => {
  const round = RunEffectRecorder.root().child("schleife").child("bedingung", 4);

  round.child("senden").record(notification);

  assert.equal(round.effects[0]?.iteration, 4);
  assert.equal(round.effects[0]?.sourceNodeId, "senden");
});

test("siblings do not see each other's effects", () => {
  const root = RunEffectRecorder.root();
  const first = root.child("a");
  const second = root.child("b");

  first.record(notification);

  assert.equal(second.effects.length, 0);
});

test("the root itself cannot record, because no node caused the effect", () => {
  assert.throws(() => RunEffectRecorder.root().record(notification));
});
