import {type SpeechVoiceList} from "../domain/entities/speech.js";

/** Wire-Format der Stimmenliste — identisch für lokale Runtime und Cloud-Funktion. */
export function speechVoiceListDto(list: SpeechVoiceList) {
  return {
    voices: list.voices.map((voice) => ({
      id: voice.id,
      name: voice.name,
      ...(voice.description ? {description: voice.description} : {}),
      ...(voice.language ? {language: voice.language} : {}),
    })),
    defaultVoiceId: list.defaultVoiceId,
    allowsCustomVoice: list.allowsCustomVoice,
  };
}
