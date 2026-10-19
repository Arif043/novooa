import {type ConsoleOutput} from "./task.js";
import {type TeamworkConversationEntry} from "./teamwork-conversation.js";

type NodeFailureInput = {
  code: string;
  message: string;
  details?: Record<string, string>;
  console?: ConsoleOutput;
  conversation?: TeamworkConversationEntry[];
};

/**
 * Warum ein Baustein gescheitert ist, als Wert: ein stabiler Code, den der
 * Client übersetzt, ein sprachneutraler technischer Text, die Felder für
 * die Übersetzung (z. B. Operator und erhaltener Wert) und, bei Scripts,
 * die Konsolenausgabe bis zum Fehler, bei der Teamarbeit das Gespräch bis zum Fehler.
 */
export class NodeFailure {
  private constructor(
    readonly code: string,
    readonly message: string,
    readonly details: Readonly<Record<string, string>>,
    readonly console?: ConsoleOutput,
    readonly conversation?: TeamworkConversationEntry[],
  ) {}

  static of(input: NodeFailureInput): NodeFailure {
    return new NodeFailure(input.code, input.message, {...(input.details ?? {})}, input.console, input.conversation);
  }

  /** Dieselbe Failure mit der Konsolenausgabe des Scripts, das sie ausgelöst hat. */
  withConsole(console: ConsoleOutput): NodeFailure {
    return new NodeFailure(this.code, this.message, this.details, console, this.conversation);
  }

  /** Dieselbe Failure mit dem Gespräch der Teamarbeit bis zum Fehler. */
  withConversation(conversation: TeamworkConversationEntry[]): NodeFailure {
    return new NodeFailure(this.code, this.message, this.details, this.console, conversation);
  }

  /** Dieselbe Failure mit einem weiteren Feld, z. B. der Runde einer Schleife. */
  withDetail(name: string, value: string): NodeFailure {
    return new NodeFailure(this.code, this.message, {...this.details, [name]: value}, this.console, this.conversation);
  }
}
