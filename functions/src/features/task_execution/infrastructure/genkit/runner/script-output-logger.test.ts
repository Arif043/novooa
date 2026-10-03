import assert from "node:assert/strict";
import test from "node:test";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {scriptOutputLogger, scriptStderrEvent, scriptStdoutEvent} from "./script-output-logger.js";

function recordingLogger() {
  const readable: {level: string; message: string; event: string | undefined}[] = [];
  const logger: ApplicationLogger = {
    info() {}, error() {}, exception() {},
    readableInfo: (message, event) => { readable.push({level: "info", message, event}); },
    readableError: (message, event) => { readable.push({level: "error", message, event}); },
  };
  return {logger, readable};
}

test("stdout wird als Information mit eigenem Ereignis protokolliert", () => {
  const {logger, readable} = recordingLogger();

  scriptOutputLogger(logger)({printed: "eins\nzwei\n", errorOutput: ""});

  assert.deepEqual(readable, [{level: "info", message: "[Script-Log]\neins\nzwei", event: scriptStdoutEvent}]);
});

test("stderr wird als eigener Fehlereintrag protokolliert", () => {
  const {logger, readable} = recordingLogger();

  scriptOutputLogger(logger)({printed: "", errorOutput: "UserWarning: veraltet\n"});

  assert.deepEqual(readable, [{level: "error", message: "[Script-Fehlerausgabe]\nUserWarning: veraltet", event: scriptStderrEvent}]);
});

test("stdout und stderr erscheinen getrennt, leere Ausgaben gar nicht", () => {
  const {logger, readable} = recordingLogger();
  const log = scriptOutputLogger(logger);

  log({printed: "a", errorOutput: "b"});
  log({printed: "  \n", errorOutput: ""});

  assert.deepEqual(readable.map((entry) => entry.event), [scriptStdoutEvent, scriptStderrEvent]);
});
