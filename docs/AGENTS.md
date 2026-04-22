# AGENTS.md - AI Agent Instructions for sarif.cr Docs

This document provides instructions for AI agents working on the sarif.cr documentation site.

## Project Overview

This is the documentation site for [sarif.cr](https://github.com/hahwul/sarif.cr), a Crystal implementation of the SARIF 2.1.0 specification. The site is built with [Hwaro](https://github.com/hahwul/hwaro), a static site generator written in Crystal.

## Site Structure

```
docs/
├── config.toml              # Site configuration
├── content/
│   ├── index.md             # Home page
│   ├── user-guide/
│   │   ├── _index.md        # Section index
│   │   ├── getting-started.md
│   │   ├── basic-usage.md
│   │   ├── builder.md
│   │   └── parsing-and-validation.md
│   └── api-reference/
│       ├── _index.md        # Section index
│       ├── sarif-log.md
│       ├── run.md
│       ├── result.md
│       ├── tool.md
│       ├── location.md
│       └── enums.md
├── templates/
│   ├── header.html
│   ├── footer.html
│   ├── page.html
│   ├── section.html
│   ├── 404.html
│   ├── taxonomy.html
│   ├── taxonomy_term.html
│   └── shortcodes/
│       └── alert.html
└── static/
    └── css/style.css
```

## Content Conventions

- **Two main sections:** User Guide (how-to) and API Reference (type documentation)
- **Front matter:** TOML format with `title`, `description`, `weight` (for ordering)
- **Code examples:** Crystal code blocks with realistic SARIF usage
- **Tables:** For property/parameter documentation in API reference
- **No emojis** in content
- **Em-dash pattern** for link lists: `**[Link](/path/)** -- Description`
- **camelCase** when referring to SARIF JSON keys, **snake_case** for Crystal properties

## Hwaro Commands

| Command | Description |
|---------|-------------|
| `hwaro build` | Build to `public/` |
| `hwaro serve` | Dev server at localhost:3000 |
| `hwaro serve --open` | Dev server + open browser |

## Notes for AI Agents

1. **Always preserve front matter** when editing content files.
2. **Update sidebar navigation** in both `page.html` and `section.html` when adding/removing pages.
3. **Use `weight`** in front matter to control page ordering within sections.
4. **Keep code examples working** -- they should match the actual sarif.cr API in `src/`.
5. **Validate TOML syntax** in config.toml after edits.
6. **Keep URLs relative** using `{{ base_url }}` prefix in templates.
