module.exports = {
  title: 'Aethyr Documentation',
  tagline: 'Comprehensive reference and guides',
  url: 'https://example.com',
  baseUrl: '/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'aethyr',
  projectName: 'aethyr-docs',
  // Preset configuration — the *classic* preset bundles the Docs & Theme
  // plugins and therefore offers the most straightforward bootstrap.
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          path: 'docs',
          routeBasePath: '/',
          sidebarPath: require.resolve('./sidebars.js'),
          // Custom remark plugin – converts Kroki‐compatible fenced code blocks
          // into *inline* <img> tags whose `src` is a data URI containing the
          // SVG. This guarantees fully offline documentation once the static
          // site is generated.
          remarkPlugins: [require('./docs/plugins/remark-kroki-inline')],
          editUrl: undefined, // We do not expose an "Edit this page" link.
        },
        blog: false, // Disable the blog plugin — not required for now.
        pages: false,
        theme: {},
      },
    ],
  ],
}; 