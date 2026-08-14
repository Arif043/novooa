import assert from "node:assert/strict";
import test from "node:test";
import {pageUrlFrom} from "./public-page-url.js";

test("normalizes a naked public domain to HTTPS", () => {
  assert.equal(pageUrlFrom("laraevent.de").href, "https://laraevent.de/");
});

test("rejects local and non HTTP URLs", () => {
  assert.throws(() => pageUrlFrom("http://127.0.0.1:8080"));
  assert.throws(() => pageUrlFrom("file:///etc/passwd"));
});
