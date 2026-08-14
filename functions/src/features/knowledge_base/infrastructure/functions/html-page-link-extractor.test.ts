import assert from "node:assert/strict";
import test from "node:test";
import {extractPageLinks} from "./html-page-link-extractor.js";

test("extracts unique internal page links from HTML", () => {
  const extraction = extractPageLinks(`
    <a href="#services">Services</a>
    <a href="/services/tischdekoration">Tischdekoration</a>
    <a href="/services/tischdekoration">Duplikat</a>
    <a href="https://example.org/contact">Extern</a>
    <a href="mailto:info@example.org">E-Mail</a>
  `, "https://laraevent.de/", false);

  assert.deepEqual(extraction, {
    links: [{url: "https://laraevent.de/services/tischdekoration", text: "Tischdekoration"}],
    truncated: false,
  });
});

test("keeps external HTTP links when requested", () => {
  const extraction = extractPageLinks(
    '<a href="https://example.org/contact">Extern</a>',
    "https://laraevent.de/",
    true,
  );

  assert.deepEqual(extraction.links, [
    {url: "https://example.org/contact", text: "Extern"},
  ]);
});
