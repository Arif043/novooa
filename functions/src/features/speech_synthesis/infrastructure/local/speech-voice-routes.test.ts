import assert from "node:assert/strict";
import test from "node:test";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {SpeechSynthesisError} from "../../domain/entities/speech.js";
import {type SpeechVoiceCatalog} from "../../domain/repositories/speech-synthesizer.js";
import {speechVoiceRoutes} from "./speech-voice-routes.js";

const url = "/v1/language-models/lm-1/voices";

test("returns the voices of the chosen language model", async () => {
  const requested: string[] = [];
  const voices: SpeechVoiceCatalog = {
    listVoices: async (teamId, languageModelId) => {
      requested.push(`${teamId}/${languageModelId}`);
      return {voices: [{id: "Kore", name: "Kore", description: "Bestimmt"}], defaultVoiceId: "Kore", allowsCustomVoice: false};
    },
  };
  const handler = testingRoutes(speechVoiceRoutes, {voices});

  const response = await handler.handle({body: {}, method: "GET", url});

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {
    voices: [{id: "Kore", name: "Kore", description: "Bestimmt"}], defaultVoiceId: "Kore", allowsCustomVoice: false,
  });
  assert.deepEqual(requested, ["team-1/lm-1"]);
});

test("answers provider problems with a readable 400", async () => {
  const handler = testingRoutes(speechVoiceRoutes, {voices: {
    listVoices: async () => { throw new SpeechSynthesisError("Das ElevenLabs-Konto hat keine Stimmen."); },
  }});

  const response = await handler.handle({body: {}, method: "GET", url});

  assert.equal(response?.statusCode, 400);
  assert.deepEqual(response?.body, {error: "Das ElevenLabs-Konto hat keine Stimmen."});
});
