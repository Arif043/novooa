/**
 * Was ein Baustein über seine Werte hinaus bewirkt hat — die Folgen eines Laufs.
 * Effekte sind historische Fakten an der Node-Aktivität; sie enthalten bewusst keine
 * Inhalte (kein Nachrichtentext, keine HTTP-Bodies, Header oder Query-Parameter).
 */
export type RunEffectDetails =
  | {
    kind: "fileWritten";
    fileId: string;
    versionId: string;
    displayName: string;
    contentType: string;
    sizeBytes: number;
    isNewFile: boolean;
  }
  | {kind: "messageSent"; channel: "email" | "whatsapp" | "sms"; recipient: string; subject?: string}
  | {kind: "notificationSent"; title: string}
  | {
    kind: "recordsChanged";
    collectionId: string;
    operation: "created" | "updated" | "deleted";
    /** Ein einzelner Datensatz; fehlt bei Sammeländerungen. */
    documentId?: string;
    count: number;
  }
  | {
    kind: "httpRequested";
    method: string;
    /** Bei einer Verbindung steht dort die Adresse; ohne Verbindung der Host der URL. */
    host?: string;
    connectionId?: string;
    status: number;
  }
  | {kind: "externalAction"; plugin: string; action: string; label: string};

export type RunEffect = RunEffectDetails & {
  /** Der Baustein, der den Effekt verursacht hat — auch innerhalb von Zweigen und Schleifen. */
  sourceNodeId: string;
  /** Runde der umschließenden Schleife, falls der Effekt in einer Schleife entstand. */
  iteration?: number;
};

export type RunEffectKind = RunEffect["kind"];
