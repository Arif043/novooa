import {type ConsoleOutput} from "./task.js";

type NodeFailureInput = {
  code: string;
  message: string;
  details?: Record<string, string>;
  console?: ConsoleOutput;
};

/**
 * Warum ein Baustein gescheitert ist, als Wert: ein stabiler Code, den der
 * Client übersetzt, ein sprachneutraler technischer Text, die Felder für
 * die Übersetzung (z. B. Operator und erhaltener Wert) und, bei Scripts,
 * die Konsolenausgabe bis zum Fehler.
 */
export class NodeFailure {
  private constructor(
    readonly code: string,
    readonly message: string,
    readonly details: Readonly<Record<string, string>>,
    readonly console?: ConsoleOutput,
  ) {}

  static of(input: NodeFailureInput): NodeFailure {
    return new NodeFailure(input.code, input.message, {...(input.details ?? {})}, input.console);
  }

  /** Dieselbe Failure mit der Konsolenausgabe des Scripts, das sie ausgelöst hat. */
  withConsole(console: ConsoleOutput): NodeFailure {
    return new NodeFailure(this.code, this.message, this.details, console);
  }

  /** Dieselbe Failure mit einem weiteren Feld, z. B. der Runde einer Schleife. */
  withDetail(name: string, value: string): NodeFailure {
    return new NodeFailure(this.code, this.message, {...this.details, [name]: value}, this.console);
  }
}
