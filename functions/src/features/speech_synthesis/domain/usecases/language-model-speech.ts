import {type LanguageModelCatalog} from "../../../language_models/domain/repositories/language-model-catalog.js";
import {SpeechSynthesisError, type SpeechVoiceList, type SynthesizedSpeech} from "../entities/speech.js";
import {type SpeechProvider, type SpeechProviderContext} from "../repositories/speech-provider.js";
import {
  type SpeechSynthesisRequest,
  type SpeechSynthesizer,
  type SpeechVoiceCatalog,
} from "../repositories/speech-synthesizer.js";

/**
 * Sprachausgabe über ein verbundenes Sprachmodell. Der Aufruf kennt nur die ID des
 * Modells; Verbindung und API-Key kommen aus dem Katalog, der passende Adapter aus
 * der Anbieterliste. Ob das Modell tatsächlich sprechen kann, entscheidet der Anbieter
 * — die Auswahl im Baustein ist bewusst nicht gefiltert.
 */
export class LanguageModelSpeech implements SpeechSynthesizer, SpeechVoiceCatalog {
  constructor(
    private readonly catalog: LanguageModelCatalog,
    private readonly providers: readonly SpeechProvider[],
  ) {}

  async synthesize(request: SpeechSynthesisRequest): Promise<SynthesizedSpeech> {
    const text = request.text.trim();
    if (text.length === 0) throw new SpeechSynthesisError("Der Text für die Sprachausgabe ist leer.");
    const {provider, context} = await this.resolve(request.teamId, request.languageModelId);
    if (text.length > provider.maximumTextLength) {
      throw new SpeechSynthesisError(
        `Der Text ist zu lang für die Sprachausgabe (höchstens ${provider.maximumTextLength} Zeichen).`,
      );
    }
    const voiceId = await this.voiceFor(provider, context, request.voiceId);
    return provider.synthesize(context, {text, voiceId});
  }

  async listVoices(teamId: string, languageModelId: string): Promise<SpeechVoiceList> {
    const {provider, context} = await this.resolve(teamId, languageModelId);
    return provider.listVoices(context);
  }

  private async voiceFor(provider: SpeechProvider, context: SpeechProviderContext, requested?: string): Promise<string> {
    const voiceId = requested?.trim();
    if (voiceId) return voiceId;
    return (await provider.listVoices(context)).defaultVoiceId;
  }

  private async resolve(teamId: string, languageModelId: string) {
    const model = await this.catalog.loadModel(teamId, languageModelId);
    const connection = await this.catalog.loadConnection(teamId, model.connectionId);
    const provider = this.providers.find((candidate) => candidate.supports(connection.provider));
    if (provider === undefined) {
      throw new SpeechSynthesisError(`${connection.name} bietet keine Sprachausgabe an.`);
    }
    const apiKey = await this.catalog.loadConnectionApiKey(teamId, connection.id);
    return {provider, context: {connection, model, apiKey}};
  }
}
