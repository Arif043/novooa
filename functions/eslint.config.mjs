// @ts-check
import js from "@eslint/js";
import {defineConfig} from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig(
  {
    ignores: ["lib/**", "dist-protected/**", "node_modules/**", "drizzle/**", "cloudrun/**", "*.config.ts", "*.config.mjs"],
  },
  {
    files: ["src/**/*.ts"],
    extends: [js.configs.recommended, tseslint.configs.recommendedTypeChecked],
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // Adapter und Fakes erfüllen asynchrone Ports oft ohne eigenes await; das ist kein Fehler.
      "@typescript-eslint/require-await": "off",
      // test()/describe() aus node:test liefern Promises, die der Test-Runner selbst verwaltet.
      "@typescript-eslint/no-floating-promises": ["error", {
        allowForKnownSafeCalls: [{from: "package", name: ["test", "describe", "it", "suite"], package: "node:test"}],
      }],
      // Ein führender Unterstrich markiert bewusst ungenutzte Parameter und Bindungen.
      "@typescript-eslint/no-unused-vars": ["error", {
        argsIgnorePattern: "^_",
        varsIgnorePattern: "^_",
        caughtErrorsIgnorePattern: "^_",
        destructuredArrayIgnorePattern: "^_",
      }],
    },
  },
  {
    // Plugins hängen vom Kern ab, nie umgekehrt: Der Kern importiert nichts aus features/integrations
    // (verdrahtet wird nur in src/shared/local).
    files: ["src/features/**/*.ts"],
    ignores: ["src/features/integrations/**"],
    rules: {
      "no-restricted-imports": ["error", {
        patterns: [{
          group: ["**/integrations", "**/integrations/**"],
          message: "Features importieren nichts aus features/integrations; Plugins werden in src/shared/local verdrahtet.",
        }],
      }],
    },
  },
);
