import {type SpeechVoiceList, type SynthesizedSpeech} from "../entities/speech.js";

export type SpeechSynthesisRequest = {
  teamId: string;
  languageModelId: string;
  text: string;
  /** Leer = Standardstimme des Anbieters. */
  voiceId?: string;
};

/** Was ein Workflow-Baustein von der Sprachausgabe braucht. */
export interface SpeechSynthesizer {
  synthesize(request: SpeechSynthesisRequest): Promise<SynthesizedSpeech>;
}

/** Was die Oberfläche braucht, um Stimmen zur Auswahl anzubieten. */
export interface SpeechVoiceCatalog {
  listVoices(teamId: string, languageModelId: string): Promise<SpeechVoiceList>;
}
