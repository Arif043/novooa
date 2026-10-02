import {Type, type FastifyPluginAsyncTypebox} from "@fastify/type-provider-typebox";
import {ErrorResponse} from "../../../../shared/local/local-runtime-http-schemas.js";
import {type SpeechVoiceCatalog} from "../../domain/repositories/speech-synthesizer.js";
import {SpeechSynthesisError} from "../../domain/entities/speech.js";
import {speechVoiceListDto} from "../speech-voice-list-dto.js";

export type SpeechVoiceRoutesOptions = {voices: SpeechVoiceCatalog};

const VoiceList = Type.Object({
  voices: Type.Array(Type.Object({
    id: Type.String(), name: Type.String(),
    description: Type.Optional(Type.String()), language: Type.Optional(Type.String()),
  })),
  defaultVoiceId: Type.String(),
  allowsCustomVoice: Type.Boolean(),
});

/** Stimmen, die ein verbundenes Sprachmodell für „Text vorlesen“ anbietet. */
export const speechVoiceRoutes: FastifyPluginAsyncTypebox<SpeechVoiceRoutesOptions> = async (app, {voices}) => {
  app.get("/v1/language-models/:languageModelId/voices", {
    schema: {
      params: Type.Object({languageModelId: Type.String({minLength: 1, maxLength: 200})}),
      response: {200: VoiceList, 400: ErrorResponse},
    },
  }, async (request, reply) => {
    try {
      const list = await voices.listVoices(request.workspace.teamId, request.params.languageModelId);
      return speechVoiceListDto(list);
    } catch (error) {
      if (!(error instanceof SpeechSynthesisError)) throw error;
      return reply.code(400).send({error: error.message});
    }
  });
};
