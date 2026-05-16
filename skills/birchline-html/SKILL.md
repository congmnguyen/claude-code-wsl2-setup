---
name: birchline-html
description: Generate standalone HTML artifacts using the birchline light theme — Lora serif headings, Inter body, JetBrains Mono code, clay/olive/sky accents on warm oat background. Use when user asks for HTML output saved to Desktop, document-style summaries, paper recaps, design proposals, takeaway docs, or any readable single-file HTML artifact.
---

# Birchline HTML Artifacts

Generate clean, document-style HTML files using the birchline design system. Output is a single self-contained `.html` file (only external dep: Google Fonts CDN) saved to the user's Desktop for offline reading.

## When to invoke

- "trả lời dưới dạng HTML rồi để ngoài desktop"
- "structure this as HTML"
- "for me to read later"
- Recap of a paper, long analysis, design proposal, takeaway summary
- Multi-section document where tabs/cards help navigation

Do NOT use for: throwaway prototypes, code-only output, anything the user wants to consume inside the terminal.

## Output convention

- Path: `/mnt/c/Users/cong/Desktop/<descriptive-kebab-name>.html`
- Filename should describe the content (e.g. `paper-schema-linking-takeaways.html`, `migration-plan-v2.html`)
- Single self-contained file — all CSS inline, no JS frameworks, Google Fonts via CDN OK
- Vietnamese content is fine; `<html lang="vi">` if document is Vietnamese

## Workflow

1. Read `template.html` (sibling file) to get the full CSS scaffold
2. Adapt the structure for the specific content:
   - Choose 2-5 tabs based on natural content sections
   - Pick component variants per section (clay/olive/sky cards, before/after grids, stat cards, etc.)
   - Use file references (`<span class="file-ref">path:line</span>`) when discussing code
3. Write the final file to Desktop

## Design tokens

```
clay:       #D97757   primary accent, headings h3, active tab, badges
olive:      #788C5D   secondary accent, success/done states
sky:        #6A8CAF   info, file refs, neutral callouts
oat:        #EDE5D8   background tint
oat-deep:   #DFD3BC   borders
slate:      #141413   body text
slate-soft: #4A4845   muted text
warm-white: #FAF7F1   page background
paper:      #F5EFE3   card background
paper-dim:  #EFE7D5   inline code background
```

Fonts (load via Google Fonts):
- **Lora** (400/500/600/700 + italic) — h1, h2, h3, h4, subtitle, takeaway
- **Inter** (400/500/600) — body text, badges, buttons
- **JetBrains Mono** (400/500/600) — code, pre, file refs

## Component library

All components are pre-defined in `template.html`. Pick what fits:

| Component | Use for |
|---|---|
| `nav.tabs` (sticky) | Top-level navigation, 2-5 sections |
| `.card.clay` | Primary/featured item, P0 priority |
| `.card.olive` | Secondary/medium importance, P1 |
| `.card.sky` | Tertiary/info, P2, low priority |
| `.card` (no variant) | Neutral/blocked status |
| `.compare` (before/after grid) | Hiện tại vs đề xuất, old vs new |
| `.stat-grid` (3-up) | Key metrics, "paper đạt được gì" |
| `.insight-grid` (2-up) | List of insights/principles |
| `.takeaway` (gradient callout) | Key conclusion to highlight |
| `blockquote` | Quote/aside |
| `<table>` | Structured comparison, summary tables |
| `.badge.p0` / `.p1` / `.p2` | Priority labels |
| `.badge.blocked` / `.free` | Status labels |
| `.tag` in `.tag-list` | Inline keyword chips |
| `.file-ref` | Inline file path with line number |

## Tab pattern (default)

```html
<nav class="tabs">
  <button data-tab="overview" class="active">Tổng quan</button>
  <button data-tab="insights">Key insights</button>
  <button data-tab="apply">Áp dụng</button>
  <button data-tab="examples">Ví dụ</button>
</nav>

<main>
  <section id="overview" class="tab-content active">...</section>
  <section id="insights" class="tab-content">...</section>
  ...
</main>
```

The minimal tab-switching JS is in `template.html`.

## Code block syntax classes

Inside `<pre><code>`, wrap tokens manually:
- `<span class="kw">` keywords (def, class, return, if)
- `<span class="str">` strings
- `<span class="com">` comments
- `<span class="fn">` function names
- `<span class="num">` numbers

Example:
```html
<pre><code><span class="kw">def</span> <span class="fn">foo</span>(x):
    <span class="com"># note</span>
    <span class="kw">return</span> x + <span class="num">1</span></code></pre>
```

## Content conventions

- Header: `<h1>` title + `<p class="subtitle">` italic subtitle + `<p class="meta">` source/date
- End every tab with one `.takeaway` summarizing the section
- Footer: source link + date, centered
- Prefer 3-5 cards per tab, not walls of text
- Use tables for comparisons of 3+ items, cards for 1-3 items with detail
- Concrete examples > abstract bullet points — when explaining application to a codebase, show actual file paths and code snippets

## Decisions to make per artifact

Before writing, decide:
1. **Title** + subtitle (italic Lora) + meta line (source/date)
2. **Tab count** (2-5) and labels (Vietnamese OK, short)
3. **Per-tab structure**: how many cards, which variants, where to place stat-grid/compare/insight-grid
4. **Footer**: paper link / source / date

When in doubt, follow the structure of `paper-schema-linking-takeaways.html` on the user's Desktop — that's the canonical reference artifact.
