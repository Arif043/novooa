export const obfuscatorOptions = {
  target: "node",
  compact: true,
  controlFlowFlattening: true,
  controlFlowFlatteningThreshold: 0.75,
  deadCodeInjection: true,
  deadCodeInjectionThreshold: 0.2,
  numbersToExpressions: true,
  simplify: true,
  splitStrings: true,
  splitStringsChunkLength: 8,
  stringArray: true,
  stringArrayCallsTransform: true,
  stringArrayEncoding: ["rc4"],
  stringArrayRotate: true,
  stringArrayShuffle: true,
  stringArrayThreshold: 0.8,
  transformObjectKeys: true,
  identifierNamesGenerator: "mangled-shuffled",
  // Nur ausgelieferte Images werden gehärtet; Entwicklung und Firebase nutzen das unveränderte lib/.
  // selfDefending lässt umformatierten Code nicht mehr laufen, debugProtection erschwert einen Debugger.
  // Ohne debugProtectionInterval, damit kein Dauer-Timer den Event-Loop belastet.
  selfDefending: true,
  debugProtection: true,
  disableConsoleOutput: false,
};
