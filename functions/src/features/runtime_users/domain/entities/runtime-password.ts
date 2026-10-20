import {RuntimeUserError} from "./runtime-user-error.js";

export const runtimePasswordLimits = {minimumLength: 6, maximumLength: 1000};

/** Ein neues Passwort; Leerzeichen bleiben erhalten. */
export class RuntimePassword {
  private constructor(readonly value: string) {}

  static from(raw: string): RuntimePassword {
    const {minimumLength, maximumLength} = runtimePasswordLimits;
    if (raw.length < minimumLength || raw.length > maximumLength) {
      throw new RuntimeUserError("invalid_input", `Das Passwort braucht ${minimumLength} bis ${maximumLength} Zeichen.`);
    }
    return new RuntimePassword(raw);
  }
}
