// @ts-check
import js from "@eslint/js";
import {defineConfig} from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig(
  {
    ignores: ["lib/**", "node_modules/**", "drizzle/**", "cloudrun/**", "*.config.ts", "*.config.mjs"],
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
);
