# Keine Fähigkeitskataloge für Sprachmodelle

> novooa pflegt keine Liste, welches Modell sprechen oder transkribieren kann; die Sprachbausteine zeigen alle Sprachmodelle und melden Fehler des Anbieters im Lauf.

Gehört zu: [Sprachausgabe](../index/sprachausgabe.md)

- Warum: Fähigkeiten ändern sich beim Anbieter schneller, als ein Katalog
  gepflegt werden könnte; die Wahl wird optimistisch angenommen, ein Fehler
  steht in der Aktivität.
- Einziger Komfort (rein clientseitig, auch für gespeicherte Modelle): Die
  Auswahl für Prompt-Bausteine und Standardmodelle blendet Modelle aus, deren
  ID `tts` als eigenen Wortteil enthält (`LanguageModel.isSpeechModel`), sowie
  alle ElevenLabs-Modelle.
- Die Entdeckung nimmt Googles `*-tts`-Modelle auch ohne `generateContent` auf.
- Einzige feste Liste: die ElevenLabs-Scribe-Modelle für Transkription, weil
  `models.list` sie nicht nennt.

## Siehe auch

- [Baustein „Text vorlesen“](./text-vorlesen-baustein.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
