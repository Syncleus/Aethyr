/* --------------------------------------------------------------------------
 * Custom Remark plugin that converts any fenced code block written in a
 * Kroki-compatible diagram language (e.g. mermaid, plantuml, graphviz, etc.)
 * into an <img> tag that embeds the SVG output *inline* via a Base64-encoded
 * data URI. This ensures the final static site has **zero** external runtime
 * dependencies and therefore works flawlessly when viewed offline.
 * -------------------------------------------------------------------------- */

// We purposefully stick to CommonJS because Docusaurus' MDX pipeline relies on
// Node's require() semantics during bundle-time evaluation.

const fetch = require('node-fetch');
// The package switched to ESM default-export in newer versions; to maintain
// compatibility with both import signatures we gracefully fall back to the
// `.visit` named export when present.
const visitPackage = require('unist-util-visit');
const visit = typeof visitPackage === 'function' ? visitPackage : visitPackage.visit;

// ---------------------------------------------------------------------------
// Configuration – centralised here for easy extension.
// ---------------------------------------------------------------------------
/**
 * A curated list of diagram languages supported by the public Kroki instance
 * at https://kroki.qoto.org. Feel free to append additional languages as they
 * become available upstream.
 */
const SUPPORTED_DIAGRAM_LANGS = new Set([
  'mermaid',
  'plantuml',
  'dot', // Alias for GraphViz
  'graphviz',
  'bpmn',
  'c4plantuml',
  'ditaa',
  'erd',
  'excalidraw',
  'bytefield',
  'nomnoml',
  'pikchr',
  'svgbob',
  'umlet',
  'wavedrom',
  'blockdiag',
  'seqdiag',
  'actdiag',
  'nwdiag',
  'packetdiag',
  'rackdiag',
]);

// The public, rate-limited Kroki endpoint. This is only used at *build* time
// and therefore does not impact the runtime performance of the generated
// site.
const KROKI_ENDPOINT = 'https://kroki.qoto.org';

module.exports = function remarkKrokiInline() {
  // The transformer can be asynchronous because Docusaurus calls remark inside
  // an async/await control-flow.
  return async function transformer(tree) {
    const tasks = [];

    visit(tree, 'code', (node) => {
      if (!SUPPORTED_DIAGRAM_LANGS.has(node.lang)) return;

      const task = (async () => {
        try {
          // First attempt: use HTTP POST which is preferred but sometimes
          // disabled on hardened endpoints. Fall back to the encoded GET
          // variant if we receive a non-successful response.

          async function fetchViaPOST() {
            return fetch(`${KROKI_ENDPOINT}/${node.lang}/svg`, {
              method: 'POST',
              headers: { 'Content-Type': 'text/plain' },
              body: node.value,
            });
          }

          // Auxiliary: Kroki also offers a stateless GET API that expects the
          // diagram text to be DEFLATE-compressed and base64url-encoded.
          function encodeForGET(text) {
            const zlib = require('zlib');
            const deflated = zlib.deflateRawSync(Buffer.from(text, 'utf-8'));
            // Convert to base64url (RFC 4648 §5).
            return deflated
              .toString('base64')
              .replace(/\+/g, '-')
              .replace(/\//g, '_')
              .replace(/=+$/, '');
          }

          async function fetchViaGET() {
            const encoded = encodeForGET(node.value);
            return fetch(`${KROKI_ENDPOINT}/${node.lang}/svg/${encoded}`);
          }

          let response = await fetchViaPOST();
          if (!response.ok) {
            // Retry once with GET fallback.
            response = await fetchViaGET();
          }

          if (!response.ok) {
            throw new Error(`Kroki server responded with HTTP ${response.status}`);
          }

          const svgText = await response.text();
          const base64 = Buffer.from(svgText).toString('base64');

          // Swap the original <pre><code>…</code></pre> node with raw HTML.
          node.type = 'html';
          node.value = `<img alt="${node.lang} diagram" src="data:image/svg+xml;base64,${base64}" />`;
          node.lang = undefined;
        } catch (error) {
          /* eslint-disable no-console */
          console.error('[remark-kroki-inline] Failed to render diagram:', error);
          /* eslint-enable  no-console */
        }
      })();

      tasks.push(task);
    });

    // Wait for all replacements to finish before continuing down the pipeline.
    await Promise.all(tasks);
  };
}; 