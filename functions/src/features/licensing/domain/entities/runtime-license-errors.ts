/** Der eingegebene Token hat nicht das Format eines Lizenz-Tokens. */
export class InvalidActivationTokenError extends Error {
  constructor() {
    super("Der Lizenzschlüssel ist ungültig.");
  }
}

/** Das Lizenz-Gateway lehnt den Token ab: unbekannt, abgelaufen oder bereits verwendet. */
export class LicenseActivationRejectedError extends Error {
  constructor() {
    super("Die Lizenzanfrage wurde abgelehnt.");
  }
}

/** Das Lizenz-Gateway ist nicht erreichbar oder antwortet mit einem Serverfehler. */
export class LicenseGatewayUnavailableError extends Error {
  constructor(readonly causeDetail: string) {
    super("Das Lizenz-Gateway ist nicht erreichbar.");
  }
}

/** Die Runtime ist bereits mit einer Lizenz aktiviert, zu der der Token nicht gehört. */
export class RuntimeAlreadyActivatedError extends Error {
  constructor() {
    super("Diese Runtime ist bereits mit einer anderen Lizenz aktiviert.");
  }
}
