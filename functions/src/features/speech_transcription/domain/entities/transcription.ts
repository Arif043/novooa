export type AudioInput = {
  bytes: Uint8Array;
  contentType: string;
  displayName: string;
};

/** Ein Fehler mit einer Meldung, die der Nutzer lesen darf. */
export class SpeechTranscriptionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SpeechTranscriptionError";
  }
}
