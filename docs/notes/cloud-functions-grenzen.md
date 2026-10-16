# Grenzen von Cloud Functions

> Cloud Functions koordinieren, Storage speichert, der Task-Worker orchestriert, spezialisierte Cloud-Run-Dienste rechnen; Functions tragen nie Dateibytes.

Gehört zu: [Architektur](../index/architektur.md)

Entscheidend ist nicht die Zahl der Dateien oder Notizen, sondern wie viele
Bytes, Tokens, CPU-Zeit und parallele Arbeit ein Run gleichzeitig
materialisiert.

| Grenze (2. Generation) | Bedeutung |
| --- | --- |
| HTTP-Request | höchstens 32 MB unkomprimiert |
| HTTP-Response | höchstens 32 MB, nicht streamend |
| Instanzspeicher | höchstens 32 GiB, praktisch niedriger konfigurieren |
| `/tmp` | liegt im RAM, flüchtig |
| Laufzeit | HTTP 60 min, Task-Queue 30 min, Event-Handler 9 min |
| Concurrency | bei 1+ CPU standardmäßig 80 |

Quellen: [Cloud-Run-Functions-Quotas](https://docs.cloud.google.com/functions/quotas),
[Container-Vertrag](https://docs.cloud.google.com/run/docs/container-contract).

**Aufteilung:** Callable authentifiziert, legt den Run an, prüft Referenzen,
stellt einen Cloud Task ein, antwortet sofort. Der Worker führt den Plan aus,
lädt Dateien und Wissen nur bei Bedarf, schreibt große Ergebnisse nach
Storage und gibt nur Referenzen weiter. Der ML-Dienst rechnet.

**Leitlinien (Empfehlung, noch nicht alle umgesetzt):**

- Nur unveränderliche Referenzen (`fileId`, `versionId`, `noteId`,
  Modellversion) weitergeben; Bytes direkt aus Storage.
- Pro Baustein nur benötigte Dateien materialisieren, große streamen,
  Arbeitsverzeichnisse zuverlässig löschen.
- Budgets je Task: Anhänge, Gesamtbytes, Einzelgröße, Laufzeit,
  Modellaufrufe, Kosten.
- Wissensnotizen indexieren und chunken, je Prompt nur die relevantesten
  Chunks mit festem Budget, verwendete Quellen im Run speichern.
- Worker-Concurrency bewusst niedrig (1–4), bis Speicher und Durchsatz
  gemessen sind ([Optionen](https://github.com/firebase/firebase-functions/blob/master/src/v2/options.ts)).

## Siehe auch

- [Lebenszyklus eines Runs in der Cloud](./cloud-run-lebenszyklus.md)
- [Wissensnotizen als Anhang](./wissensnotizen-als-anhang.md)
