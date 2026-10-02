export type SpeechVoice = {
  id: string;
  name: string;
  description?: string;
  /** BCP-47-Sprachkennung oder Klartext, soweit der Anbieter sie liefert. */
  language?: string;
};

export type SpeechVoiceList = {
  voices: SpeechVoice[];
  /** Stimme, die gilt, wenn keine gewählt ist. */
  defaultVoiceId: string;
  /** Der Anbieter nimmt auch Stimmen an, die nicht in der Liste stehen (z. B. eigene Stimmen eines OpenAI-kompatiblen Dienstes). */
  allowsCustomVoice: boolean;
};

export type SynthesizedSpeech = {
  bytes: Uint8Array;
  contentType: string;
  fileExtension: string;
};

/** Ein Fehler mit einer Meldung, die der Nutzer lesen darf. */
export class SpeechSynthesisError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SpeechSynthesisError";
  }
}
