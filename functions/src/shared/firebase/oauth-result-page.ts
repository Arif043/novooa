import {type Response} from "express";

/** Abschlussseite einer Anmeldung im Browser; die App erfährt das Ergebnis über ihr Wake-up, nicht über diese Seite. */
export function sendOAuthResultPage(response: Response, result: {ok: boolean; title: string; message: string}): void {
  response.type("html").status(result.ok ? 200 : 400)
    .send(`<main><h1>${escapeHtml(result.title)}</h1><p>${escapeHtml(result.message)}</p></main>`);
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>'"]/g, (character) => htmlEntities[character] ?? character);
}

const htmlEntities: Record<string, string> = {
  "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;",
};
