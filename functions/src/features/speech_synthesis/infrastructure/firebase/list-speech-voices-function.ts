import {HttpsError, onCall} from "firebase-functions/v2/https";
import {FirestoreLanguageModelCatalog} from "../../../language_models/infrastructure/firebase/firestore-language-model-catalog.js";
import {
  languageModelCipher,
  languageModelEncryptionKey,
} from "../../../language_models/infrastructure/firebase/language-model-encryption.js";
import {currentTeamIdForUid} from "../../../teams/infrastructure/firebase/firebase-team-context.js";
import {SpeechSynthesisError} from "../../domain/entities/speech.js";
import {LanguageModelSpeech} from "../../domain/usecases/language-model-speech.js";
import {defaultSpeechProviders} from "../default-speech-providers.js";
import {speechVoiceListDto} from "../speech-voice-list-dto.js";

/** Stimmen eines Sprachmodells für „Text vorlesen“; der API-Key bleibt serverseitig. */
export const listSpeechVoices = onCall(
  {secrets: [languageModelEncryptionKey]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Anmeldung erforderlich.");
    const languageModelId = (request.data as {languageModelId?: unknown} | null)?.languageModelId;
    if (typeof languageModelId !== "string" || languageModelId.length === 0 || languageModelId.length > 200) {
      throw new HttpsError("invalid-argument", "languageModelId ist ungültig.");
    }
    const teamId = await currentTeamIdForUid(uid);
    const speech = new LanguageModelSpeech(new FirestoreLanguageModelCatalog(languageModelCipher), defaultSpeechProviders());
    try {
      return speechVoiceListDto(await speech.listVoices(teamId, languageModelId));
    } catch (error) {
      if (error instanceof SpeechSynthesisError) throw new HttpsError("failed-precondition", error.message);
      throw error;
    }
  },
);
