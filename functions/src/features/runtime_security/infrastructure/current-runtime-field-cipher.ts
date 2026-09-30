import {type RuntimeFieldCipher} from "../domain/repositories/runtime-field-cipher.js";
import {EnvelopeRuntimeFieldCipher} from "./envelope-runtime-field-cipher.js";

export class CurrentRuntimeFieldCipher implements RuntimeFieldCipher {
  private current: RuntimeFieldCipher;

  constructor(keyring: string) {
    this.current = new EnvelopeRuntimeFieldCipher(keyring);
  }

  update(keyring: string): void {
    this.current = new EnvelopeRuntimeFieldCipher(keyring);
  }

  encrypt(value: string, context: readonly string[]): string {
    return this.current.encrypt(value, context);
  }

  decrypt(value: string, context: readonly string[]): string {
    return this.current.decrypt(value, context);
  }

  rewrap(value: string, context: readonly string[]): string {
    return this.current.rewrap(value, context);
  }

  usesActiveKey(value: string): boolean {
    return this.current.usesActiveKey(value);
  }
}
