---
name: birchline-html
description: Generate standalone HTML artifacts using the birchline light theme — Lora serif headings, Inter body, JetBrains Mono code, clay/olive/sky accents on warm oat background. Use for document-style summaries, paper recaps, design proposals, takeaway docs, or any readable single-file HTML artifact.
---

# Birchline HTML Artifacts

Generate clean, document-style HTML files using the birchline design system. Output is a single self-contained `.html` file (only external dep: Google Fonts CDN).

## Output convention

- Save to the path the user specifies; otherwise default to the current working directory
- Filename should describe the content (e.g. `paper-schema-linking-takeaways.html`, `migration-plan-v2.html`)
- Single self-contained file — all CSS inline, no JS frameworks, Google Fonts via CDN OK
- Set `<html lang="...">` to match the document's language

## Workflow

1. Start from the full template at the end of this file
2. Adapt the structure for the specific content:
   - Choose 2-5 tabs based on natural content sections
   - Pick component variants per section (clay/olive/sky cards, before/after grids, stat cards, etc.)
   - Use file references (`<span class="file-ref">path:line</span>`) when discussing code
3. Write the final file to the chosen path

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

All components are pre-defined in the template below. Pick what fits:

| Component | Use for |
|---|---|
| `nav.tabs` (sticky) | Top-level navigation, 2-5 sections |
| `.card.clay` | Primary/featured item, P0 priority |
| `.card.olive` | Secondary/medium importance, P1 |
| `.card.sky` | Tertiary/info, P2, low priority |
| `.card` (no variant) | Neutral/blocked status |
| `.compare` (before/after grid) | Old vs new, current vs proposed |
| `.stat-grid` (3-up) | Key metrics |
| `.insight-grid` (2-up) | List of insights/principles |
| `.takeaway` (gradient callout) | Key conclusion to highlight |
| `blockquote` | Quote/aside |
| `<table>` | Structured comparison, summary tables |
| `.badge.p0` / `.p1` / `.p2` | Priority labels |
| `.badge.blocked` / `.free` | Status labels |
| `.tag` in `.tag-list` | Inline keyword chips |
| `.file-ref` | Inline file path with line number |

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
2. **Tab count** (2-5) and labels (short)
3. **Per-tab structure**: how many cards, which variants, where to place stat-grid/compare/insight-grid
4. **Footer**: paper link / source / date

## Full template

Copy this scaffold and adapt the content. The tab-switching JS at the bottom is intentionally minimal — keep it.

```html
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>{{TITLE}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400;0,500;0,600;0,700;1,400&family=JetBrains+Mono:wght@400;500;600&family=Inter:wght@400;500;600&display=swap" rel="stylesheet" />
<style>
  :root {
    --clay: #D97757;
    --clay-soft: #E89B7F;
    --olive: #788C5D;
    --olive-soft: #A4B387;
    --sky: #6A8CAF;
    --sky-soft: #9AB1C9;
    --oat: #EDE5D8;
    --oat-deep: #DFD3BC;
    --slate: #141413;
    --slate-soft: #4A4845;
    --warm-white: #FAF7F1;
    --paper: #F5EFE3;
    --paper-dim: #EFE7D5;
    --shadow: 0 2px 8px rgba(20, 20, 19, 0.06);
    --shadow-strong: 0 4px 16px rgba(20, 20, 19, 0.10);
  }

  * { box-sizing: border-box; }

  html, body {
    margin: 0;
    padding: 0;
    background: var(--warm-white);
    color: var(--slate);
    font-family: 'Inter', -apple-system, sans-serif;
    line-height: 1.65;
    font-size: 15.5px;
  }

  body {
    max-width: 1100px;
    margin: 0 auto;
    padding: 48px 32px 80px 32px;
  }

  h1, h2, h3, h4 {
    font-family: 'Lora', Georgia, serif;
    font-weight: 600;
    color: var(--slate);
    line-height: 1.3;
  }

  h1 { font-size: 2.2em; margin: 0 0 8px 0; }
  h2 { font-size: 1.5em; margin: 32px 0 16px 0; padding-bottom: 6px; border-bottom: 1px solid var(--oat-deep); }
  h3 { font-size: 1.15em; margin: 24px 0 10px 0; color: var(--clay); }
  h4 { font-size: 1em; margin: 18px 0 8px 0; color: var(--olive); font-weight: 600; }

  header { margin-bottom: 36px; }

  .subtitle {
    color: var(--slate-soft);
    font-style: italic;
    font-family: 'Lora', Georgia, serif;
    margin: 0 0 4px 0;
  }

  .meta {
    font-size: 0.85em;
    color: var(--slate-soft);
    margin-top: 6px;
  }

  /* === Tabs === */
  nav.tabs {
    display: flex;
    gap: 4px;
    margin-bottom: 28px;
    border-bottom: 2px solid var(--oat-deep);
    position: sticky;
    top: 0;
    background: var(--warm-white);
    z-index: 10;
    padding: 12px 0 0 0;
  }

  nav.tabs button {
    background: transparent;
    border: none;
    padding: 12px 20px;
    cursor: pointer;
    font-family: 'Lora', Georgia, serif;
    font-size: 1.02em;
    color: var(--slate-soft);
    border-bottom: 3px solid transparent;
    margin-bottom: -2px;
    transition: all 0.15s ease;
    font-weight: 500;
  }

  nav.tabs button:hover {
    color: var(--slate);
    background: var(--paper);
  }

  nav.tabs button.active {
    color: var(--clay);
    border-bottom-color: var(--clay);
    font-weight: 600;
  }

  .tab-content {
    display: none;
    animation: fade 0.2s ease;
  }

  .tab-content.active { display: block; }

  @keyframes fade {
    from { opacity: 0; transform: translateY(4px); }
    to { opacity: 1; transform: translateY(0); }
  }

  /* === Cards === */
  .card {
    background: var(--paper);
    border: 1px solid var(--oat-deep);
    border-radius: 8px;
    padding: 20px 24px;
    margin: 16px 0;
    box-shadow: var(--shadow);
  }

  .card.clay { border-left: 4px solid var(--clay); }
  .card.olive { border-left: 4px solid var(--olive); }
  .card.sky { border-left: 4px solid var(--sky); }

  /* === Badges === */
  .badge {
    display: inline-block;
    padding: 2px 10px;
    border-radius: 12px;
    font-size: 0.78em;
    font-weight: 600;
    font-family: 'Inter', sans-serif;
    margin-right: 6px;
    letter-spacing: 0.02em;
  }

  .badge.p0 { background: var(--clay); color: white; }
  .badge.p1 { background: var(--olive); color: white; }
  .badge.p2 { background: var(--sky); color: white; }
  .badge.blocked { background: var(--oat-deep); color: var(--slate); }
  .badge.free { background: #C9DAB8; color: var(--slate); }

  /* === Code === */
  code, pre {
    font-family: 'JetBrains Mono', 'Courier New', monospace;
    font-size: 0.88em;
  }

  code {
    background: var(--paper-dim);
    padding: 2px 6px;
    border-radius: 4px;
    color: var(--slate);
  }

  pre {
    background: #2A2823;
    color: #E8E2D5;
    padding: 16px 20px;
    border-radius: 6px;
    overflow-x: auto;
    line-height: 1.55;
    margin: 12px 0;
  }

  pre code {
    background: transparent;
    padding: 0;
    color: inherit;
  }

  .kw { color: #E89B7F; }
  .str { color: #A4B387; }
  .com { color: #8A8478; font-style: italic; }
  .fn { color: #9AB1C9; }
  .num { color: #D4A574; }

  /* === Tables === */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    background: var(--paper);
    border-radius: 8px;
    overflow: hidden;
  }

  th, td {
    padding: 10px 14px;
    text-align: left;
    border-bottom: 1px solid var(--oat-deep);
  }

  th {
    background: var(--oat-deep);
    font-weight: 600;
    font-family: 'Lora', Georgia, serif;
  }

  tr:last-child td { border-bottom: none; }

  /* === Before/After compare === */
  .compare {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
    margin: 16px 0;
  }

  .compare .col {
    padding: 16px 18px;
    border-radius: 8px;
    border: 1px solid var(--oat-deep);
  }

  .compare .before {
    background: #F7EBE5;
    border-color: var(--clay-soft);
  }

  .compare .after {
    background: #EDF2E5;
    border-color: var(--olive-soft);
  }

  .compare h4 {
    margin-top: 0;
    text-transform: uppercase;
    font-size: 0.78em;
    letter-spacing: 0.08em;
  }

  .compare .before h4 { color: var(--clay); }
  .compare .after h4 { color: var(--olive); }

  /* === Inline file refs === */
  .file-ref {
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.85em;
    color: var(--sky);
    background: var(--paper-dim);
    padding: 1px 6px;
    border-radius: 3px;
  }

  /* === Blockquote === */
  blockquote {
    margin: 16px 0;
    padding: 12px 18px;
    border-left: 3px solid var(--sky);
    background: var(--paper);
    color: var(--slate-soft);
    font-style: italic;
    border-radius: 0 4px 4px 0;
  }

  ul, ol { padding-left: 22px; }
  li { margin: 6px 0; }

  /* === Tag chips === */
  .tag-list {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    margin: 8px 0;
  }

  .tag {
    background: var(--paper-dim);
    padding: 3px 10px;
    border-radius: 12px;
    font-size: 0.82em;
    font-family: 'JetBrains Mono', monospace;
    color: var(--slate-soft);
  }

  /* === Takeaway callout === */
  .takeaway {
    background: linear-gradient(135deg, #F7EBE5 0%, #EDF2E5 100%);
    border: 1px solid var(--oat-deep);
    border-radius: 8px;
    padding: 16px 20px;
    margin: 20px 0;
    font-family: 'Lora', Georgia, serif;
    font-style: italic;
    color: var(--slate);
  }

  .takeaway::before {
    content: "→ ";
    color: var(--clay);
    font-weight: bold;
    font-style: normal;
  }

  /* === Footer === */
  footer {
    margin-top: 60px;
    padding-top: 24px;
    border-top: 1px solid var(--oat-deep);
    text-align: center;
    color: var(--slate-soft);
    font-size: 0.9em;
  }

  footer a {
    color: var(--clay);
    text-decoration: none;
    border-bottom: 1px dotted var(--clay);
  }

  footer a:hover { background: var(--paper); }

  /* === Stat grid (3-up) === */
  .stat-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
    margin: 16px 0;
  }

  .stat {
    background: var(--paper);
    border: 1px solid var(--oat-deep);
    border-radius: 8px;
    padding: 14px 16px;
    text-align: center;
  }

  .stat .num-big {
    font-family: 'Lora', Georgia, serif;
    font-size: 1.8em;
    font-weight: 700;
    color: var(--clay);
    display: block;
    line-height: 1;
  }

  .stat .label {
    font-size: 0.85em;
    color: var(--slate-soft);
    margin-top: 4px;
    display: block;
  }

  /* === Insight grid (2-up) === */
  .insight-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 14px;
    margin: 20px 0;
  }

  .insight {
    background: var(--paper);
    border-left: 3px solid var(--olive);
    border-radius: 0 6px 6px 0;
    padding: 14px 18px;
  }

  .insight strong {
    color: var(--clay);
    font-family: 'Lora', Georgia, serif;
    display: block;
    margin-bottom: 4px;
  }
</style>
</head>
<body>

<header>
  <h1>{{TITLE}}</h1>
  <p class="subtitle">{{SUBTITLE}}</p>
  <p class="meta">{{META — source / date / author}}</p>
</header>

<nav class="tabs">
  <button data-tab="tab1" class="active">{{Tab 1}}</button>
  <button data-tab="tab2">{{Tab 2}}</button>
  <button data-tab="tab3">{{Tab 3}}</button>
</nav>

<main>

  <!-- =================== TAB 1 =================== -->
  <section id="tab1" class="tab-content active">

    <h2>{{Section heading}}</h2>

    <p>{{Body paragraph...}}</p>

    <!-- Example: stat grid -->
    <div class="stat-grid">
      <div class="stat">
        <span class="num-big">+5.4%</span>
        <span class="label">metric label<br>secondary line</span>
      </div>
      <div class="stat">
        <span class="num-big">~50%</span>
        <span class="label">another metric</span>
      </div>
      <div class="stat">
        <span class="num-big">2.6s</span>
        <span class="label">third metric</span>
      </div>
    </div>

    <!-- Example: before/after -->
    <div class="compare">
      <div class="col before">
        <h4>Hiện tại</h4>
        <p>{{description of current state}}</p>
      </div>
      <div class="col after">
        <h4>Đề xuất</h4>
        <p>{{description of proposed state}}</p>
      </div>
    </div>

    <div class="takeaway">
      {{Key conclusion of this section}}
    </div>

  </section>

  <!-- =================== TAB 2 =================== -->
  <section id="tab2" class="tab-content">

    <h2>{{Section heading}}</h2>

    <!-- Example: insight grid -->
    <div class="insight-grid">
      <div class="insight">
        <strong>1. Insight title</strong>
        {{Insight body...}}
      </div>
      <div class="insight">
        <strong>2. Insight title</strong>
        {{Insight body...}}
      </div>
    </div>

    <!-- Example: code block -->
    <pre><code><span class="kw">def</span> <span class="fn">example</span>(x):
    <span class="com"># comment</span>
    <span class="kw">return</span> x + <span class="num">1</span></code></pre>

    <!-- Example: table -->
    <table>
      <tr><th>Column A</th><th>Column B</th><th>Column C</th></tr>
      <tr><td>val 1</td><td>val 2</td><td>val 3</td></tr>
      <tr><td>val 1</td><td>val 2</td><td>val 3</td></tr>
    </table>

  </section>

  <!-- =================== TAB 3 =================== -->
  <section id="tab3" class="tab-content">

    <h2>{{Section heading}}</h2>

    <!-- Example: priority cards -->
    <div class="card clay">
      <p><span class="badge p0">P0</span> <span class="badge free">No blocker</span></p>
      <h3>High priority item</h3>
      <p>Reference: <span class="file-ref">path/to/file.py:42</span></p>
      <p>{{Description...}}</p>
    </div>

    <div class="card olive">
      <p><span class="badge p1">P1</span></p>
      <h3>Medium priority item</h3>
      <p>{{Description...}}</p>
    </div>

    <div class="card sky">
      <p><span class="badge p2">P2</span></p>
      <h3>Low priority item</h3>
      <p>{{Description...}}</p>
    </div>

    <div class="card">
      <p><span class="badge blocked">Blocked</span></p>
      <h3>Blocked item</h3>
      <p>{{Description of what's blocking...}}</p>
    </div>

  </section>

</main>

<footer>
  <p>{{Source/paper link}} · {{Date}}</p>
</footer>

<script>
  document.querySelectorAll('nav.tabs button').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('nav.tabs button').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(s => s.classList.remove('active'));
      btn.classList.add('active');
      document.getElementById(btn.dataset.tab).classList.add('active');
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  });
</script>

</body>
</html>
```
