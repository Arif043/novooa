import {type SpeechProvider} from "../domain/repositories/speech-provider.js";
import {ElevenLabsSpeechProvider} from "./elevenlabs/elevenlabs-speech-provider.js";
import {GoogleSpeechProvider} from "./google/google-speech-provider.js";
import {OpenAiCompatibleSpeechProvider} from "./openai/openai-compatible-speech-provider.js";

/** Die Anbieter, die Sprachausgabe können; der erste passende gewinnt. */
export function defaultSpeechProviders(): readonly SpeechProvider[] {
  return [new GoogleSpeechProvider(), new ElevenLabsSpeechProvider(), new OpenAiCompatibleSpeechProvider()];
}
