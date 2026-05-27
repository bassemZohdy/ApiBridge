# ApiBridge White-Label Style Guide

Generated UIs are intentionally neutral — light background, dark text, no brand colors. Mount your CSS file at runtime to apply your brand without rebuilding.

---

## How it works

1. The backend serves your CSS at `/custom.css` via `CUSTOM_CSS_PATH`
2. The frontend injects `<link rel="stylesheet" href="/custom.css">` **after** the bundled CSS at runtime
3. Your CSS overrides the neutral defaults via CSS custom properties (variables)

**Order of precedence** (last wins):
```
bundled index.css (neutral defaults)
  → Google Fonts
    → /custom.css  ← your overrides
```

---

## Docker mount example

```bash
docker run -p 8080:8080 \
  -v /path/to/your/brand.css:/config/brand.css:ro \
  -e CUSTOM_CSS_PATH=/config/brand.css \
  your-image:latest
```

Or in `docker-compose.yml`:

```yaml
services:
  app:
    image: your-image:latest
    ports:
      - "8080:8080"
    environment:
      CUSTOM_CSS_PATH: /config/brand.css
    volumes:
      - ./brand.css:/config/brand.css:ro
```

---

## CSS custom properties reference

All neutral defaults are defined in `:root`. Override any subset.

| Variable | Default | Purpose |
|---|---|---|
| `--bg` | `#f8fafc` | Page background |
| `--card` | `#ffffff` | Card/panel background |
| `--card-border` | `#e2e8f0` | Card border color |
| `--accent` | `#1e293b` | Primary action color (button bg, focus ring, active states) |
| `--accent-dim` | `rgba(30,41,59,0.06)` | Accent tint (hover backgrounds, active tab bg) |
| `--text` | `#1e293b` | Primary text |
| `--text-muted` | `#64748b` | Labels, secondary text, placeholders |
| `--input-bg` | `#ffffff` | Input field background |
| `--input-border` | `#cbd5e1` | Input border |
| `--error` | `#dc2626` | Error states |
| `--success` | `#16a34a` | Success/response states |
| `--font-sans` | `'Outfit', sans-serif` | Body / UI font |
| `--font-mono` | `'Fira Code', monospace` | Labels, code, monospaced fields |
| `--radius` | `10px` | Corner radius for inputs/cards |

### Minimal brand.css example (light)

```css
:root {
  --accent: #0070f3;
  --accent-dim: rgba(0, 112, 243, 0.08);
}
.apib-topbar {
  background: #0070f3;
}
```

### Dark theme example

```css
:root {
  --bg: #0a0a0a;
  --card: #111827;
  --card-border: rgba(255, 255, 255, 0.1);
  --accent: #6366f1;
  --accent-dim: rgba(99, 102, 241, 0.12);
  --text: #f1f5f9;
  --text-muted: #94a3b8;
  --input-bg: #1e293b;
  --input-border: rgba(255, 255, 255, 0.1);
}
.apib-topbar {
  background: linear-gradient(90deg, #6366f1, #8b5cf6);
}
```

---

## CSS class reference

### Layout

| Class | Element | Notes |
|---|---|---|
| `.apib-shell` | Page wrapper | Full-height flex centering |
| `.apib-topbar` | 3px accent bar | Fixed top of viewport |
| `.apib-card` | Content card | Max-width 520px |
| `.apib-card--wide` | Wide card | Max-width 860px (list/view pages) |

### Header / Navigation

| Class | Element | Notes |
|---|---|---|
| `.apib-header` | Title row | Badge + title |
| `.apib-badge` | Service ID chip | Monospace, small |
| `.apib-title` | Page heading | |
| `.apib-title--inline` | Inline heading | Used alongside badge in list header |
| `.apib-view-header` | View/form nav bar | Back button + actions row |
| `.apib-view-actions` | Action buttons group | Right side of view-header |
| `.apib-list-header` | List page header | Title row with New button |
| `.apib-list-actions` | New button container | |

### Buttons

| Class | Variant | Notes |
|---|---|---|
| `.apib-btn` | Base | Neutral bordered button |
| `.apib-btn--primary` | Primary | Accent background, white text |
| `.apib-btn--danger` | Danger | Error background, white text |
| `.apib-btn--ghost` | Ghost | Transparent, muted text |
| `.apib-submit` | Form submit | Full-width, primary accent |

### Form

| Class | Element |
|---|---|
| `.apib-form` | Form container |
| `.apib-field` | Field wrapper |
| `.apib-label` | Field label |
| `.apib-required` | Required asterisk |
| `.apib-input` | Text/number input |
| `.apib-checkbox-wrap` | Checkbox wrapper |
| `.apib-checkbox` | Checkbox input |
| `.apib-error` | Error message |
| `.apib-tabs` | Tab bar |
| `.apib-tab` | Tab button |
| `.apib-tab--active` | Active tab |

### List page

| Class | Element |
|---|---|
| `.apib-table-wrap` | Scrollable table container |
| `.apib-table` | `<table>` |
| `.apib-th` | `<th>` header cell |
| `.apib-th--sortable` | Clickable sort header |
| `.apib-th--sorted` | Currently sorted column header |
| `.apib-th--action` | Action column header (narrow) |
| `.apib-sort-icon` | Sort arrow indicator |
| `.apib-tr` | `<tr>` data row |
| `.apib-td` | `<td>` data cell |
| `.apib-td--empty` | Empty state cell |
| `.apib-td--action` | Action cell (right-aligned) |
| `.apib-row-link` | "View →" hint |
| `.apib-pagination` | Pagination bar |
| `.apib-pagination-info` | Record count label |
| `.apib-pagination-controls` | Prev/Next buttons |
| `.apib-page-btn` | Prev/Next button |
| `.apib-page-num` | "Page N of M" |

### View / detail page

| Class | Element |
|---|---|
| `.apib-detail-grid` | `<dl>` two-column grid |
| `.apib-detail-field` | `<div>` field wrapper |
| `.apib-detail-label` | `<dt>` field label |
| `.apib-detail-value` | `<dd>` field value |

### Response / loading

| Class | Element |
|---|---|
| `.apib-loading` | Centered spinner wrapper |
| `.apib-spinner` | Spinning circle |
| `.apib-response` | Response panel |
| `.apib-response-header` | Response panel header |
| `.apib-response-dot` | Green status dot |
| `.apib-response-body` | Formatted response body |

---

## Pagination ENV VARs

Override the query parameter names used for pagination at runtime (no rebuild needed):

| ENV VAR | Schema default | json-server default |
|---|---|---|
| `PAGINATION_PAGE_PARAM` | `page` | `_page` |
| `PAGINATION_SIZE_PARAM` | `size` | `_limit` |
| `PAGINATION_DEFAULT_PAGE_SIZE` | `20` | any integer |
| `PAGINATION_SORT_PARAM` | `sort` | `_sort` |
| `PAGINATION_DIRECTION_PARAM` | `dir` | `_order` |

Example for a Spring Boot + React image pointed at json-server:

```bash
docker run -p 8080:8080 \
  -e PAGINATION_PAGE_PARAM=_page \
  -e PAGINATION_SIZE_PARAM=_limit \
  -e PAGINATION_SORT_PARAM=_sort \
  -e PAGINATION_DIRECTION_PARAM=_order \
  customer-mgmt-bridge:latest
```

---

## Testing with json-server

The `e2e-tests/json-server-test/` directory contains ready-to-run test fixtures:

```
json-server-test/
  data/db.json              ← Sample customer records
  brand.css                 ← Sample indigo brand override
  schema-spring-react.yaml  ← Spring Boot + React (List/View/Form)
  schema-quarkus-vue.yaml   ← Quarkus + Vue (List/View/Form)
  run-e2e.sh                ← Full E2E: generate → build → test
```

Run the full test:

```bash
cd e2e-tests/json-server-test
./run-e2e.sh
```

The script generates the project, builds the Docker image, starts a `json-server` + app via Docker Compose, and validates all three page types (list, view, form) and the brand CSS mount.
