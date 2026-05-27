# ApiBridge — Project Handoff

Current implementation status for the next developer or session.

---

## What ApiBridge is

A Java 21 MDA code generator. It reads a unified YAML schema (PIM) and applies one or more pluggable **cartridge** directories of FreeMarker templates to emit a complete, runnable project. Each cartridge is independent; the engine merges them into the same output directory in order.

**Single deployable output**: FE compiles into the BE JAR via a multi-stage Dockerfile — no separate deployment needed.

---

## Cartridge inventory

```
apibridge-cartridges/
├── backend/spring-boot        Spring Boot 3.x REST proxy + /api/bridge-config
├── backend/quarkus            Quarkus 3.x JAX-RS proxy + /api/bridge-config
├── frontend/react             React 18 + Vite SPA (List / View / Form pages)
├── frontend/angular           Angular 17 SPA (List / View / Form pages)
├── frontend/vue               Vue 3 + Vite SPA (List / View / Form pages)
├── frontend/ui-schema         UiLayoutSchema.json (standalone schema export)
├── devops/dockerfile          Multi-stage Dockerfile (FE stage conditional)
├── devops/docker-compose      docker-compose.yml
├── devops/k8s/kubernetes      k8s Deployment + Service + ConfigMap + Kustomization
└── devops/k8s/openshift       Extends kubernetes with TLS Route
```

---

## Schema features (all implemented, all tested)

### Page types — `endpoints[].uiLayout.component`

| Value | Trigger | Generated component |
|---|---|---|
| `"List"` | `GET` without `{` in path | `ApiBridgeList` — paginated table with sort |
| `"View"` | `GET` with `{id}` in path | `ApiBridgeView` — detail read-only grid, DELETE support |
| `"Form"` | `POST` / `PUT` | `ApiBridgeForm` — submission form, edit pre-population |

All three are wired into an SPA hash router in `App` (`#/list`, `#/view/:id`, `#/form`, `#/form/:id`).

### Security — `flags.securityLevel`

| Value | Behavior |
|---|---|
| `"bearer-token"` | Backend validates `Authorization: Bearer` header. `AUTH_SERVER_URL` env var: if set, calls auth server to validate JWT; if empty, pass-through with non-empty header check. Frontend sends token from `localStorage`. |
| `"apiKey"` | Backend validates `X-API-Key` header against `API_KEY` env var. Frontend reads key from `import.meta.env.VITE_API_KEY` (React/Vue) or `localStorage` (Angular). |
| `""` (absent) | No security — all requests pass through. |

### Pagination — `flags.pagination`

```yaml
flags:
  pagination:
    pageParam: "page"      # default
    sizeParam: "size"      # default
    defaultPageSize: 20    # default
    sortParam: "sort"      # default
    directionParam: "dir"  # default
```

Override **at runtime** (no rebuild) via Docker ENV VARs:

| ENV VAR | Overrides |
|---|---|
| `PAGINATION_PAGE_PARAM` | `pageParam` |
| `PAGINATION_SIZE_PARAM` | `sizeParam` |
| `PAGINATION_DEFAULT_PAGE_SIZE` | `defaultPageSize` |
| `PAGINATION_SORT_PARAM` | `sortParam` |
| `PAGINATION_DIRECTION_PARAM` | `directionParam` |

All 5 env vars are included in Dockerfile.ftl, docker-compose.yml.ftl, and configmap.yaml.ftl.

### Column definition — `endpoints[].uiLayout.columns[]`

```yaml
uiLayout:
  component: "List"
  columns:
    - field: "name"
      label: "Full Name"
      sortable: true
    - field: "status"
      sortable: false
      width: "100px"
```

If `columns` is absent, the frontend detects columns at runtime from the first API response row.

### White-label CSS

Neutral defaults. Override at runtime via mounted CSS file — no rebuild:

```bash
docker run -p 8080:8080 \
  -v /path/brand.css:/config/brand.css:ro \
  -e CUSTOM_CSS_PATH=/config/brand.css \
  my-image:latest
```

Full CSS custom properties reference: [`docs/white-label-style-guide.md`](docs/white-label-style-guide.md)

---

## How the SPA router works (all three FE frameworks)

Each frontend generates a hash-based router — no router library required:

```
#/          → List page (if list endpoint exists)
#/list      → List page
#/view/:id  → View page (if GET /{id} endpoint exists)
#/form      → New record form (if POST/PUT endpoint exists)
#/form/:id  → Edit record form (pre-populates from View endpoint)
```

The `App` component (React: `App.tsx`, Vue: `App.vue`, Angular: `app.component.ts`) listens to `hashchange` events and routes accordingly.

**Important**: `ApiBridgeForm` only processes `POST`/`PUT` endpoints — GET endpoints are filtered out at template generation time via `formEndpoints = endpoints.filter(ep -> method != "GET")`.

---

## Completed work

| ID | Description |
|---|---|
| BUG-1 | Removed duplicate React View component (old View without DELETE) |
| BUG-2 | Removed duplicate Angular View class |
| BUG-3 | Fixed unescaped `${this.recordId}` in Angular View FreeMarker |
| BUG-4 | Fixed uninitialized `upstream` in Quarkus ProxyService `finally` block |
| BUG-5 | Fixed unescaped `${id}` in React List row-click handler |
| BUG-6 | Fixed broken Angular List URL construction |
| BUG-7 | Spring Boot error responses now use `Content-Type: application/json` |
| BUG-8 | Auth RestTemplate now has 5s connect / 10s read timeouts |
| BUG-9 | Quarkus auth Response properly closed (connection leak fix) |
| BUG-10 | Angular Form now has Back button and `@Output() navigate` |
| BUG-11 | CORS now includes `exposedHeaders("*")` and `maxAge(3600)` |
| BUG-12 | Telemetry spans set `StatusCode.ERROR` on exceptions |
| BUG-13 | All `flags` accesses are null-safe (templates handle missing `flags:` section) |
| M1/M2 | Removed `navigationMode` and `uiPattern` from entire codebase |
| M3 | `/api/bridge-config` now returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath` |
| M4 | CORS aligned: `allowCredentials`, `maxAge(3600)`, `exposedHeaders("*")` |
| M5 | DevOps templates now include all `PAGINATION_*` and `CUSTOM_CSS_PATH` env vars |
| M6 | Removed unused imports (Angular HttpHeaders, BridgeApiService; Quarkus List) |
| M7 | Removed dead code (Vue pathToMethod function, unused axios dependency) |
| M8 | Aligned mock-mode method case to uppercase in both backends |
| M9 | Quarkus FE static resource config conditional on feFlavor with 365d cache headers |
| M10 | Angular list/view use `BridgeApiService.getAuthHeaders()` consistently |
| M11 | UiLayoutSchema.json now includes `columns` array and `field.label` |
| M12 | Fixed `feFlavor` default documentation (no default, not `react`) |
| M13 | Quarkus `BridgeConfigResource` has `@ApplicationScoped` |
| M14 | Quarkus `pom.xml` has `<name>` and `<description>` |
| M15 | Angular `styles.css` has `.apib-spinner--dark` variant |
| M16 | Vue `ApiBridgeView` has `<style scoped>` section |
| S1 | HTTP method validation (only GET/POST/PUT/DELETE/PATCH allowed) |
| S2 | Case-insensitive `uiLayout.component` validation |
| S3 | CLI override `--security-level=` added |
| S4 | Duplicate endpoint detection (same path + method rejected) |
| S5 | Proxy timeouts configurable via `PROXY_CONNECT_TIMEOUT`/`PROXY_READ_TIMEOUT` env vars |
| S6 | `BridgeSchemaModel` has full Javadoc |
| L3 | CI wired with `e2e-json-server` job |
| L5 | Vue E2E uses `vue-tsc` instead of `tsc` |
| L6 | Fixed `run-all-e2e.sh` step numbering |
| C1 | Added `getAuthHeaders()` to React/Vue `bridgeApi.ts.ftl` |
| C2 | Fixed GET+body bug in all 3 frontend API layers |
| C3 | Fixed Angular Form empty security credentials |
| C4 | Fixed method name collision in both backends (HTTP prefix) |
| H1 | Forward query parameters in both ProxyService templates |
| H2 | DELETE support in all 3 View components |
| H3 | Edit-mode pre-population in all 3 Form components |
| H4 | Configurable bearer-token security via `AUTH_SERVER_URL` (both backends) |
| H5 | Quarkus OpenTelemetry telemetry spans |
| H6 | Forward upstream response headers (non-hop-by-hop) |
| — | Frontend API method naming: HTTP prefix + By-suffix (e.g. `getSubmissionsById`) |
| — | Angular View FreeMarker `${token}` escaping fix |
| — | Created AGENTS.md, updated CLAUDE.md, README.md, HANDOFF.md |

---

## Backend API endpoints generated

Every generated backend exposes:

| Endpoint | Purpose |
|---|---|
| `GET /api/bridge-config` | Serves `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath`, and pagination config (respects ENV VAR overrides) |
| `GET /custom.css` | Serves mounted brand CSS file |
| `{method} {basePath}{path}` | Proxies each schema endpoint to its `backendUrl` |

All error responses use `Content-Type: application/json`.

---

## Test status

```
mvn test → 80/80 PASS
```

| Test class | Count | Covers |
|---|---|---|
| `YamlParserTest` | 52 | All schema validation paths, HTTP method validation, duplicate endpoint detection, case-insensitive component, pagination, columns, field.label |
| `ApiBridgeCartridgeEngineTest` | 26 | All cartridge generations incl. List/View/Form model |
| `ApiBridgeRunnerTest` | 2 | CLI argument handling |

### Testing gaps (deferred)

- DevOps cartridges (dockerfile, docker-compose, k8s) have zero unit test coverage
- k8s cartridges have zero E2E or CI coverage
- No test verifying generated API method naming convention

---

## E2E test suite

```bash
./e2e-tests/run-all-e2e.sh
```

| Pipeline | What it tests |
|---|---|
| `maven-spring-boot-test` | Generated Spring Boot project compiles with Maven |
| `maven-quarkus-test` | Generated Quarkus project compiles with Maven |
| `typescript-angular-test` | Generated Angular project passes strict `tsc` |
| `typescript-react-test` | Generated React project passes strict `tsc` |
| `typescript-vue-test` | Generated Vue project passes strict `vue-tsc` |
| `verify-contract-symmetry.sh` | Backend and frontend share identical API paths |
| `docker-fullstack-test` | Docker build + MOCK_MODE + BLOCK_TRAFFIC runtime |
| `json-server-test` | Spring+React and Quarkus+Vue live against json-server: pagination, sorting, CRUD, brand CSS, bridge-config ENV overrides |

---

## Sample schema

`sample-schema.yaml` demonstrates all three page types with pagination and column config:

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  securityLevel: "bearer-token"
  enableTelemetry: true
  backendFlavor: "spring-boot"
  feFlavor: "react"
  deployTarget: "docker-compose"
  pagination:
    pageParam: "page"
    sizeParam: "size"
    defaultPageSize: 20
    sortParam: "sort"
    directionParam: "dir"
endpoints:
  - path: "/submissions"          # → ApiBridgeList
    method: "GET"
    ...
  - path: "/submissions/{id}"     # → ApiBridgeView
    method: "GET"
    ...
  - path: "/initiate"             # → ApiBridgeForm
    method: "POST"
    ...
```

---

## Key design invariants

1. **No cross-cartridge dependencies** — each cartridge is self-contained.
2. **FreeMarker `${...}` in JSX/TS template literals** must be escaped as `${r"${...}"}` to avoid FreeMarker interpolation. **Every** `${...}` inside a backtick string must use this escape.
3. **Form templates filter GET endpoints** — `formEndpoints` assigned at template top; do not regress this.
4. **Custom CSS loads after the Vite bundle** — injected dynamically in `main.ts`/`main.tsx` so brand overrides win the cascade.
5. **`Pagination` is auto-initialized** in `BridgeSchemaModel.Flags` — `getPagination()` is never null when flags are present.
6. **Frontend API method names use HTTP prefix + By-suffix** — `getSubmissions()`, `getSubmissionsById(id)`, `postInitiate(body)`. All collision-free.
7. **ProxyService forwards headers and query params** — both backends forward all non-hop-by-hop request/response headers and append query parameters to the upstream URL.
8. **All 3 frontends export `getAuthHeaders()`** — React/Vue from `bridgeApi.ts`, Angular on `BridgeApiService`. New components must use these helpers.
9. **View components support DELETE** — if a DELETE endpoint exists for the same path pattern, the View page renders a delete button.
10. **Form components support edit pre-population** — when `editId` is set (`#/form/:id`), the Form fetches the record from the View GET endpoint and pre-populates fields.
11. **Bearer-token security via `AUTH_SERVER_URL`** — if set, backend validates JWT against auth server; if empty, pass-through with non-empty header check.
12. **Telemetry spans** — both backends generate OpenTelemetry spans with `http.method` and `http.url` attributes when `enableTelemetry: true`. Spans set `StatusCode.ERROR` on exceptions.
13. **CORS includes `exposedHeaders("*")` and `maxAge(3600)`** — upstream headers (e.g. `X-Total-Count`) are visible to frontend JS.
14. **All `flags` accesses are null-safe** — templates handle missing `flags:` section without crashing.
15. **All error responses use `Content-Type: application/json`** — both backends return JSON error bodies.
16. **Auth RestTemplate has timeouts** — 5s connect / 10s read, preventing indefinite hangs.
17. **Proxy timeouts configurable** — `PROXY_CONNECT_TIMEOUT` and `PROXY_READ_TIMEOUT` env vars.
