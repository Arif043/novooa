import {z, type Genkit} from "genkit";
import {extractPageLinks} from "./html-page-link-extractor.js";
import {PublicPageHtmlFetcher} from "./public-page-html-fetcher.js";

const extractedPageLinkSchema = z.object({
  url: z.string().url(),
  text: z.string(),
});

export type ExtractPageLinksToolDependencies = {
  pageFetcher: PublicPageHtmlFetcher;
};

export function defineExtractPageLinksTool(
  ai: Genkit,
  dependencies: ExtractPageLinksToolDependencies,
) {
  return ai.defineTool(
    {
      name: "extractPageLinks",
      description: "Liest die HTML-Links einer einzelnen öffentlichen Webseite strukturiert aus. Nutze das Tool für Fragen zu Links, Navigation, Unterseiten oder deren URLs.",
      inputSchema: z.object({
        url: z.string().min(1).max(2048),
        includeExternal: z.boolean().default(false),
      }),
      outputSchema: z.object({
        pageUrl: z.string().url(),
        links: z.array(extractedPageLinkSchema),
        truncated: z.boolean(),
      }),
    },
    async ({url, includeExternal}) =>
      pageLinksFor(url, includeExternal, dependencies.pageFetcher),
  );
}

async function pageLinksFor(
  url: string,
  includeExternal: boolean,
  pageFetcher: PublicPageHtmlFetcher,
) {
  const page = await pageFetcher.fetchPage(url);
  const extraction = extractPageLinks(page.html, page.responseUrl, includeExternal);
  return {pageUrl: page.responseUrl, ...extraction};
}
