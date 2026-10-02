import {type LanguageModelCatalog} from "../../../language_models/domain/repositories/language-model-catalog.js";
import {SpeechTranscriptionError} from "../entities/transcription.js";
import {type TranscriptionProvider} from "../repositories/transcription-provider.js";
import {type SpeechTranscriptionRequest, type SpeechTranscriber} from "../repositories/speech-transcriber.js";

/**
 * Transkription über ein verbundenes Sprachmodell. Wie bei der Sprachausgabe wird
 * optimistisch angenommen, dass das gewählte Modell Audio versteht; lehnt der
 * Anbieter ab, steht seine Meldung in der Aktivität.
 */
export class LanguageModelTranscription implements SpeechTranscriber {
  constructor(
    private readonly catalog: LanguageModelCatalog,
    private readonly providers: readonly TranscriptionProvider[],
  ) {}

  async transcribe(request: SpeechTranscriptionRequest): Promise<string> {
    const {audio} = request;
    if (!audio.contentType.startsWith("audio/")) {
      throw new SpeechTranscriptionError(`„${audio.displayName}“ ist keine Audiodatei.`);
    }
    const model = await this.catalog.loadModel(request.teamId, request.languageModelId);
    const connection = await this.catalog.loadConnection(request.teamId, model.connectionId);
    const provider = this.providers.find((candidate) => candidate.supports(connection.provider));
    if (provider === undefined) {
      throw new SpeechTranscriptionError(`${connection.name} bietet keine Transkription an.`);
    }
    if (audio.bytes.length > provider.maximumAudioBytes) {
      const megabytes = Math.floor(provider.maximumAudioBytes / (1024 * 1024));
      throw new SpeechTranscriptionError(`Die Audiodatei ist zu groß für ${connection.name} (höchstens ${megabytes} MB).`);
    }
    const apiKey = await this.catalog.loadConnectionApiKey(request.teamId, connection.id);
    return provider.transcribe({connection, model, apiKey}, audio);
  }
}
