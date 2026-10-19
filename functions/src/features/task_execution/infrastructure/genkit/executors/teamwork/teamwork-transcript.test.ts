import assert from "node:assert/strict";
import test from "node:test";
import {logger} from "./teamwork-test-support.js";
import {TeamworkTranscript} from "./teamwork-transcript.js";

test("every event becomes a log line and a full conversation entry", () => {
  const log = logger();
  const transcript = new TeamworkTranscript(log, () => new Date("2026-10-19T08:00:00.000Z"));
  const longAnswer = "x".repeat(3000);

  transcript.task("Elektriker", {task: " Prüfe den Plan. ", expectedResult: "Ja/Nein", boundaries: " "});
  transcript.answer("Elektriker", longAnswer, 1500);
  transcript.failure("Ökonom", "Modell lehnt ab");
  transcript.review(1, {approved: false, findings: "Kosten fehlen."}, false);
  transcript.result({korrekt: true});

  assert.deepEqual(transcript.entries().map(({kind, memberName, round}) => [kind, memberName, round]), [
    ["task", "Elektriker", undefined], ["answer", "Elektriker", undefined], ["failure", "Ökonom", undefined],
    ["reviewRejected", undefined, 1], ["result", undefined, undefined],
  ]);
  assert.deepEqual(transcript.entries()[0], {
    kind: "task", memberName: "Elektriker", text: "Prüfe den Plan.", expectedResult: "Ja/Nein", occurredAt: "2026-10-19T08:00:00.000Z",
  });
  assert.equal(transcript.entries()[1].text.length, 3000, "the conversation keeps what the log shortens");
  assert.equal(transcript.entries()[1].durationMs, 1500);
  assert.match(transcript.entries()[4].text, /"korrekt": true/);
  assert.equal(log.lines.length, 4, "the result is no extra log line");
  assert.match(log.lines[1], /weitere Zeichen/);
});
