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
| `"View"` | `GET` with `{id}` in path | `ApiBridgeView` — detail read-only grid |
| `"Form"` | `POST` / `PUT` | `ApiBridgeForm` — submission form |

All three are wired into an SPA hash router in `App` (`#/list`, `#/view/:id`, `#/form`, `#/form/:id`).

### SPA/MPA flag — `flags.navigationMode`

- `"spa"` (default): client-side hash routing, no page refreshes
- `"mpa"`: multi-page layout mode

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

The backend `/api/bridge-config` endpoint serves the live values. The frontend fetches it at boot and falls back to schema-baked defaults if the endpoint is unreachable.

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
#/form/:id  → Edit record form
```

The `App` component (React: `App.tsx`, Vue: `App.vue`, Angular: `app.component.ts`) listens to `hashchange` events and routes accordingly.

**Important**: `ApiBridgeForm` only processes `POST`/`PUT` endpoints — GET endpoints are filtered out at template generation time via `formEndpoints = endpoints.filter(ep -> method != "GET")`.

---

## Backend API endpoints generated

Every generated backend exposes:

| Endpoint | Purpose |
|---|---|
| `GET /api/bridge-config` | Serves pagination config (respects ENV VAR overrides) |
| `GET /custom.css` | Serves mounted brand CSS file |
| `{method} {basePath}{path}` | Proxies each schema endpoint to its `backendUrl` |

---

## Test status

```
mvn test → 85/85 PASS
```

| Test class | Count | Covers |
|---|---|---|
| `YamlParserTest` | 57 | All schema validation paths, new fields (navigationMode, pagination, columns, field.label) |
| `ApiBridgeCartridgeEngineTest` | 26 | All cartridge generations incl. List/View/Form model |
| `ApiBridgeRunnerTest` | 2 | CLI argument handling |

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
| `typescript-vue-test` | Generated Vue project passes strict `tsc` |
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
  navigationMode: "spa"
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
2. **FreeMarker `${...}` in JSX/TS template literals** must be escaped as `${r"${...}"}` to avoid FreeMarker interpolation.
3. **Form templates filter GET endpoints** — `formEndpoints` assigned at template top; do not regress this.
4. **Custom CSS loads after the Vite bundle** — injected dynamically in `main.ts`/`main.tsx` so brand overrides win the cascade.
5. **`Pagination` is auto-initialized** in `BridgeSchemaModel.Flags` — `getPagination()` is never null when flags are present.
