• Die wichtigste Grenze ist nicht die Anzahl von Dateien oder Wissensnotizen als solche, sondern wie viele Bytes, Tokens, CPU-Zeit und parallele Arbeit ein einzelner Run gleichzeitig materialisiert.

  Cloud Functions der zweiten Generation sind gut als Steuerungsebene, aber nicht als dauerhafter Dateiverarbeitungs- oder Kontextspeicher.

   Grenze               Bedeutung für novooa
  ━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   HTTP-Request         maximal 32 MB unkomprimiert
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────
   HTTP-Response        maximal 32 MB, nicht streamend
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────
   Instanzspeicher      maximal 32 GiB, praktisch deutlich niedriger konfigurieren
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────
   Temporäre Dateien    /tmp liegt im RAM und ist flüchtig
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────
   Laufzeit             HTTP bis 60 Minuten, Task-Queue bis 30 Minuten, Event-Handler bis 9 Minuten
  ───────────────────  ─────────────────────────────────────────────────────────────────────────────
   Concurrency          bei 1+ CPU standardmäßig 80, falls nicht explizit begrenzt

  Die harten Größen- und Zeitgrenzen sind in den aktuellen Cloud-Run-Functions-Quotas (https://docs.cloud.google.com/functions/quotas) dokumentiert. Temporäre Dateien verbrauchen Instanz-RAM und können bei
  fehlendem Cleanup oder vielen parallelen Runs zum OOM führen. Cloud Run Container Runtime (https://docs.cloud.google.com/run/docs/container-contract)

  Für novooa würde ich die Verantwortung so aufteilen:

  Callable Function
    -> authentifizieren, Run erzeugen, Referenzen validieren
    -> Cloud Task einstellen
    -> sofort antworten

  Task-Worker
    -> Workflow-Plan ausführen
    -> Dateien und Wissensquellen nur bei Bedarf laden
    -> große Ergebnisse in Storage schreiben
    -> nur Referenzen und kleine JSON-Werte weitergeben

  ML-Cloud-Run-Service
    -> Bild-/Tensor-Inferenz
    -> modellnahe Caches und Sessions

  Die Function und der Worker sollten nie Dateibytes im Request tragen. Sie erhalten nur immutable Referenzen wie fileId, versionId, noteId und Modellversion. Die Bytes kommen bei Bedarf direkt aus Storage.

  Für viele Dateien bedeutet das konkret:

  - Keine pauschale Arbeitskopie aller Anhänge in /tmp.
  - Pro Baustein nur die tatsächlich benötigten Dateien materialisieren.
  - Große Dateien streamen statt vollständig in RAM lesen.
  - Arbeitsverzeichnisse nach jedem Baustein zuverlässig löschen.
  - Große Ergebnisse immer als Datei speichern und nur eine file-Referenz weitergeben.
  - Eine Task braucht Budgets: maximale Anzahl Anhänge, Gesamtbytezahl, Einzeldateigröße, Laufzeit, Modellaufrufe und Kosten.

  Für viele Wissensnotizen:

  - Nicht alle Notizen in einen Prompt laden.
  - Notizen indexieren und in Chunks speichern.
  - Pro Prompt nur die relevantesten k Chunks laden, mit festem Token-/Bytebudget.
  - Quellen und verwendete Chunks im Run speichern, damit Ergebnisse nachvollziehbar bleiben.

  Besonders wichtig ist die Function-Concurrency: Der Standard kann bei 1+ CPU bei 80 parallelen Requests liegen. Für Worker, die Dateien nach /tmp laden oder externe Modelle aufrufen, sollte sie bewusst
  niedrig gesetzt werden, etwa 1 bis 4, bis Speicherverbrauch und Durchsatz gemessen sind. Firebase Functions v2 Options (https://github.com/firebase/firebase-functions/blob/master/src/v2/options.ts)

  Kurz: Die Cloud Function koordiniert; Storage speichert; der Task-Worker orchestriert; spezialisierte Cloud-Run-Dienste rechnen.
