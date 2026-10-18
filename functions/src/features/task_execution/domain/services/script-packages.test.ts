import assert from "node:assert/strict";
import test from "node:test";
import {normalizedScriptPackages} from "./script-packages.js";

test("normalizes names, extras and versions, removes duplicates and sorts", () => {
  assert.deepEqual(
    normalizedScriptPackages([" Pandas == 2.2.3", "requests[SOCKS, security] >=2.31, <3", "opencv_python", "pandas==2.2.3", ""]),
    ["opencv-python", "pandas==2.2.3", "requests[security,socks]>=2.31,<3"],
  );
});
