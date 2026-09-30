export interface SensitiveFieldCipher {
  encrypt(value: string, context: readonly string[]): string;
  decrypt(value: string, context: readonly string[]): string;
}

export interface RuntimeFieldCipher extends SensitiveFieldCipher {
  rewrap(value: string, context: readonly string[]): string;
  usesActiveKey(value: string): boolean;
}
