import {type AudioInput} from "../entities/transcription.js";

export type SpeechTranscriptionRequest = {
  teamId: string;
  languageModelId: string;
  audio: AudioInput;
};

/** Was ein Workflow-Baustein von der Transkription braucht. */
export interface SpeechTranscriber {
  transcribe(request: SpeechTranscriptionRequest): Promise<string>;
}
