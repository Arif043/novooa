/** Die Anfrage selbst ist fehlerhaft (z. B. unbekannte Kategorie). */
export class InvalidTransferRequestError extends Error {}

/** Das hochgeladene Archiv ist kein gültiger novooa-Export. */
export class InvalidTransferArchiveError extends Error {}
