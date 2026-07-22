import { Language, Parser } from './web-tree-sitter.js';

let parserPromise;

globalThis.novooaPythonParser = {
  analyze(source) {
    return pythonParser().then((parser) => syntaxIssues(parser, source));
  },
};

function pythonParser() {
  parserPromise ??= initializeParser();
  return parserPromise;
}

async function initializeParser() {
  await Parser.init({
    locateFile: (name) => new URL(`./${name}`, import.meta.url).href,
  });
  const language = await Language.load(
    new URL('./tree-sitter-python.wasm', import.meta.url).href,
  );
  return new Parser().setLanguage(language);
}

function syntaxIssues(parser, source) {
  const tree = parser.parse(source);
  const issues = [];
  collectSyntaxIssues(tree.rootNode, issues);
  tree.delete();
  return JSON.stringify(uniqueIssues(issues));
}

function collectSyntaxIssues(node, issues) {
  if (node.isError || node.isMissing) {
    issues.push({
      line: node.startPosition.row,
      message: node.isMissing ? `Erwartet: ${node.type}` : 'Ungültige Python-Syntax.',
    });
    return;
  }
  for (let index = 0; index < node.childCount; index += 1) {
    collectSyntaxIssues(node.child(index), issues);
  }
}

function uniqueIssues(issues) {
  const unique = new Map();
  for (const issue of issues) {
    unique.set(`${issue.line}:${issue.message}`, issue);
  }
  return [...unique.values()];
}
