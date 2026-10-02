import {type TranscriptionProvider} from "../domain/repositories/transcription-provider.js";
import {ElevenLabsTranscriptionProvider} from "./elevenlabs/elevenlabs-transcription-provider.js";
import {GoogleTranscriptionProvider} from "./google/google-transcription-provider.js";
import {OpenAiCompatibleTranscriptionProvider} from "./openai/openai-compatible-transcription-provider.js";

export function defaultTranscriptionProviders(): readonly TranscriptionProvider[] {
  return [new GoogleTranscriptionProvider(), new ElevenLabsTranscriptionProvider(), new OpenAiCompatibleTranscriptionProvider()];
}
