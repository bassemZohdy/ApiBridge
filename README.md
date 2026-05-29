# ApiBridge — Pluggable MDA Code Generation Engine

ApiBridge is a Model-Driven Architecture (MDA) code generator written in Java 21. It reads a unified YAML schema (the **Platform-Independent Model**, or PIM) and processes it through one or more pluggable **cartridges** to emit platform-specific code.

Each cartridge is an independent directory of FreeMarker templates. The engine applies them in sequence to the same output directory — there are no cross-cartridge dependencies. Select exactly the cartridges you need; unused ones are simply not applied.

---

## Project Layout

```
apibridge-generator/              # Java engine — the only Maven module
apibridge-cartridges/             # Pluggable cartridge directories (not Maven modules)
├── backend/
│   ├── spring-boot/              # Spring Boot REST proxy (output: backend/)
│   └── quarkus/                  # Quarkus JAX-RS proxy (output: backend/)
├── frontend/
│   ├── angular/                  # Angular 17 full project (output: frontend/)
│   ├── react/                    # React 18 + Vite full project (output: frontend/)
│   ├── vue/                      # Vue 3 + Vite full project (output: frontend/)
│   └── ui-schema/                # UiLayoutSchema.json for UI-driven forms (output: frontend/)
├── devops/
│   ├── dockerfile/               # Multi-stage Dockerfile (FE stage conditional)
│   ├── docker-compose/           # docker-compose.yml
│   └── k8s/
│       ├── kubernetes/           # K8s Deployment + Service + ConfigMap + Kustomization
│       └── openshift/            # Extends kubernetes with TLS Route
docs/                             # Reference documentation
sample-schema.yaml                # Working example PIM schema
e2e-tests/                        # Integration tests — run on CI, not before every commit
```

---

## Quick Start

```bash
# 1. Build the fat JAR
mvn clean package

# 2. Spring Boot + React, Docker Compose deployment
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/frontend/react \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/docker-compose \
  --output=output/my-app

# 3. Build and run
cd output/my-app
docker compose up --build

# 4. Mock mode — returns canned JSON, no upstream calls
docker compose run --rm -e MOCK_MODE=true my-app

# 5. Backend-only (no FE cartridge)
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/quarkus \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --output=output/quarkus-only
```

---

## CLI Reference

```
java -jar apibridge-generator.jar \
  --schema=<path>           Path to the YAML PIM schema
  --cartridge=<path>        Cartridge to apply (repeatable; applied in order)
  --output=<path>           Destination directory for generated files
  [--be-flavor=<val>]       Override backend: spring-boot | quarkus
  [--fe-flavor=<val>]       Override frontend: angular | react | vue
  [--deploy-target=<val>]   Override deployment: docker-compose | kubernetes | openshift
  [--security-level=<val>]  Override security: bearer-token | apiKey
  [--version | -v]          Print version and exit
  [-h | --help]             Show help
```

`--cartridge` is repeatable. Each cartridge's output merges into the same `--output` directory in the order specified.

---

## Cartridges

### Backend cartridges

| Cartridge | Output |
|---|---|
| `backend/spring-boot` | `backend/` — Spring Boot 3.x proxy with RestTemplate, Actuator, OTel |
| `backend/quarkus` | `backend/` — Quarkus 3.x JAX-RS proxy with JAX-RS Client, Health, OTel |

Both backends:
- Proxy every schema endpoint to its `backendUrl`
- Forward all request/response headers (excluding hop-by-hop) and query parameters
- `MOCK_MODE=true` returns a canned JSON response instead of proxying
- `BLOCK_TRAFFIC=true` returns 503 for every request
- Every config value is overridable at runtime via ENV VAR (see `application.properties`)
- When a `frontend/` cartridge is also applied, the backend serves the compiled FE assets from its static resources directory (`classpath:/static/` for Spring Boot, `META-INF/resources/` for Quarkus)

#### Rate Limiting (`enableRateLimiter`)

Wraps all proxy calls with a Resilience4j rate limiter. Returns `429 {"error":"Too Many Requests","rateLimit":"exceeded"}` when the limit is exceeded.

| ENV VAR | Default | Purpose |
|---|---|---|
| `RATE_LIMIT_PERMITS` | `10` | Max requests per period |
| `RATE_LIMIT_PERIOD_SECONDS` | `1` | Time window in seconds |
| `RATE_LIMIT_TIMEOUT_MILLIS` | `5000` | Max wait for permit before 429 |

Layer order: `RateLimiter → CircuitBreaker → Retry → HTTP call`

#### Distributed Cache (`enableResponseCache`)

When `enableResponseCache` is enabled, the proxy caches GET responses. At runtime, if `CACHE_REDIS_URL` is set, Redis is used as the cache store. If empty/absent, the embedded Caffeine cache is used. Zero breaking change to existing deployments.

#### Request/Response Transformation (`enableTransform`)

Apply header and JSON body transforms per endpoint. Header transforms: add, remove, rename. Field transforms: rename keys, remove keys. Configured per endpoint via the `transforms` schema section.

#### API Versioning (`apiVersion`)

Global version prefix on all proxy endpoints. When `flags.apiVersion: "v1"` is set, routes become `/{apiVersion}{basePath}{path}`. Health and config endpoints remain unversioned.

#### Enhanced Mock Mode

Define per-endpoint mock responses in the schema via `mockResponse` (statusCode, body, delayMs). When `MOCK_MODE=true`, endpoints with a defined mock return the schema-specified response with simulated latency. Endpoints without a mock definition fall back to the generic canned response.

#### Debug Mode (`DEBUG_MODE`)

Runtime-only flag (`DEBUG_MODE=true`). Logs full request/response details (method, path, headers, body preview, duration) as structured JSON. Bodies truncated to 1024 chars; Authorization values masked. Must be off in production.

#### Health Check Aggregation (`enableHealthCheck`)

Periodically probes each endpoint's `backendUrl` and exposes aggregated health at `GET /api/bridge-health`. Returns `UP`, `DEGRADED`, or `DOWN` status with per-endpoint latency and last check time. Integrates with Spring Actuator / Quarkus Health.

| ENV VAR | Default | Purpose |
|---|---|---|
| `HEALTH_CHECK_INTERVAL_SECONDS` | `30` | Probe interval |
| `HEALTH_CHECK_TIMEOUT_MS` | `3000` | Per-probe timeout |

### Frontend cartridges

| Cartridge | Output |
|---|---|
| `frontend/angular` | `frontend/` — Angular 17 + TypeScript, dynamic form engine |
| `frontend/react` | `frontend/` — React 18 + Vite + TypeScript, dynamic form engine |
| `frontend/vue` | `frontend/` — Vue 3 + Vite + TypeScript, dynamic form engine |
| `frontend/ui-schema` | `frontend/UiLayoutSchema.json` — JSON schema for UI-driven form rendering |

Frontend pages are generated from the schema:
- **Form** — dynamic form driven by `uiLayout.fields` for POST/PUT endpoints
- **List** — paginated table driven by `uiLayout.columns` for GET collection endpoints
- **View** — detail view for GET by-ID endpoints, with optional DELETE support
- All pages use a centralized `getAuthHeaders()` helper for security

#### Search & Filtering (`enableSearch`)

Per-endpoint search support on List pages. Set `uiLayout.searchMode: "delegate"` to pass search/filter params through to the upstream API, or `"local"` to filter client-side. Search param name configurable via `SEARCH_PARAM` ENV VAR (default `"q"`).

#### Dark Mode / Theme Switcher

Always available when a frontend is generated. Toggle in topbar, persisted via `localStorage`. Falls back to `prefers-color-scheme` media query. Pure CSS variables — zero bundle cost.

#### Offline Support (`enableOfflineSupport`)

Generates a Service Worker with cache-first for the app shell and stale-while-revalidate for API GET responses. Shows an offline banner when the network is unavailable. Non-GET requests are network-only.

### DevOps cartridges

| Cartridge | Output |
|---|---|
| `devops/dockerfile` | `Dockerfile` — three-stage: FE build (node), BE build + embed (maven), runtime (JRE) |
| `devops/docker-compose` | `docker-compose.yml` — local dev with healthcheck and resource limits |
| `devops/k8s/kubernetes` | `k8s/` — Deployment + Service + ConfigMap + Kustomization |
| `devops/k8s/openshift` | `k8s/route.yaml` + updated `k8s/kustomization.yaml` — apply on top of kubernetes |

The `devops/dockerfile` FE build stage is automatically omitted when no `feFlavor` is set (BE-only output).

For OpenShift: apply both `devops/k8s/kubernetes` and `devops/k8s/openshift` to get the full manifest set including a TLS edge-terminated Route.

### Documentation cartridges

| Cartridge | Output |
|---|---|
| `docs/openapi` | `openapi.yaml` — OpenAPI 3.0.3 spec generated from schema (when `flags.enableOpenApi: true`) |

### Single-JAR deployment

When both a backend and frontend cartridge are applied, the multi-stage Dockerfile builds the FE and copies the compiled dist into the BE's static resources directory before the Maven build, producing a **single runnable JAR** that serves both the API and the frontend:

```
Stage 1  node:20-alpine             — npm build → dist/
Stage 2  maven:3.9-amazoncorretto   — COPY dist → src/main/resources/static/ → mvn package
Stage 3  amazoncorretto:21-alpine   — java -jar app.jar (port 8080)
```

---

## YAML Schema

Full reference: [docs/schema-reference.md](docs/schema-reference.md)

Minimal valid schema:

```yaml
id: "my-service"
basePath: "/api/v1"
endpoints:
  - path: "/run"
    method: "POST"
    backendUrl: "https://upstream.internal/run"
```

Full example with all flags:

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  backendFlavor: "spring-boot"   # spring-boot | quarkus
  feFlavor: "react"              # angular | react | vue  (omit for BE-only)
  securityLevel: "bearer-token"  # bearer-token | apiKey
  enableTelemetry: true
  enableAuditLog: true           # Redis Streams + MongoDB proxy call audit trail
  enableCircuitBreaker: true     # Resilience4j CB + retry; configurable via CB_* ENV VARs
  enableResponseCache: true      # Caffeine (default) or Redis (when CACHE_REDIS_URL set) GET cache
  enableRateLimiter: true        # Resilience4j rate limiter; configurable via RATE_LIMIT_* ENV VARs
  enableTransform: true          # Per-endpoint header/field request/response transformation
  enableHealthCheck: true        # Aggregated upstream health at /api/bridge-health
  enableSearch: true             # Search bar + column filters on List pages
  enableOfflineSupport: true     # Service Worker for offline-capable SPA
  enableOpenApi: true            # Generate OpenAPI 3.0.3 spec
  apiVersion: "v1"               # Global version prefix on proxy routes (v[0-9]+)
  pagination:
    pageParam: "page"            # overrideable via PAGINATION_PAGE_PARAM ENV VAR
    sizeParam: "size"
    defaultPageSize: 20
    sortParam: "sort"
    directionParam: "dir"
endpoints:
  - path: "/submissions"
    method: "GET"
    backendUrl: "https://mesh.internal/customer/submissions"
    mockResponse:
      statusCode: 200
      body: '[{"id":1,"email":"test@example.com","companyName":"Acme","status":"pending"}]'
      delayMs: 200
    transforms:
      responseFields:
        rename: { "upstream_name": "displayName" }
        remove: [ "secret_field" ]
    uiLayout:
      component: "List"          # List | View | Form
      searchMode: "delegate"     # delegate | local  (only when enableSearch=true)
      columns:
        - field: "email"
          label: "Email"
          sortable: true
        - field: "status"
          label: "Status"
          sortable: false

  - path: "/submissions/{id}"
    method: "GET"
    backendUrl: "https://mesh.internal/customer/submissions/1"
    uiLayout:
      component: "View"
      fields:
        - name: "email"
          label: "Email Address"
        - name: "status"
          label: "Status"

  - path: "/initiate"
    method: "POST"
    backendUrl: "https://mesh.internal/customer/create"
    telemetryName: "apibridge_onboarding_initiate"
    transforms:
      requestHeaders:
        add: { "X-Source": "apibridge" }
      requestFields:
        rename: { "upstream_field": "our_field" }
    uiLayout:
      component: "Form"
      fields:
        - name: "email"
          type: "string"
          label: "Email Address"
          required: true
        - name: "companyName"
          type: "string"
          label: "Company Name"
          required: true
```

### SPA routing

Frontend projects use hash-based SPA routing (no router library). The generated `App` component routes:

| Hash | Page |
|---|---|
| `#/` or `#/list` | List page (GET collection endpoint) |
| `#/view/:id` | View page (GET by-ID endpoint) |
| `#/form` | New record form |
| `#/form/:id` | Edit record form |

When `enableSearch` is active, List page URLs support search/filter state: `#/list?q=acme&status=active`.

### White-label CSS

Generated UIs use neutral CSS defaults. Override at runtime without rebuilding:

```bash
docker run -p 8080:8080 \
  -v /path/brand.css:/config/brand.css:ro \
  -e CUSTOM_CSS_PATH=/config/brand.css \
  my-image:latest
```

See [`docs/white-label-style-guide.md`](docs/white-label-style-guide.md) for the full CSS custom properties reference and class inventory.

### Audit log

When `flags.enableAuditLog: true`, every proxy call is tracked through a three-event lifecycle:

| Event | When | MongoDB effect |
|---|---|---|
| `SEND` | Before upstream call | Insert `AuditRecord` with `status: PENDING` |
| `SUCCESS` | Upstream responded | Update: `status: SUCCESS`, response data, `durationMs` |
| `FAIL` | Upstream threw or returned 5xx | Update: `status: FAILED`, error message, `durationMs` |

Events flow through Redis Stream `apibridge:audit` — decoupled from the request thread so audit logging never adds latency or fails the proxy call. Unacknowledged entries are redelivered on restart.

Runtime ENV VARs:

| ENV VAR | Default | Purpose |
|---|---|---|
| `SPRING_DATA_REDIS_URL` / `QUARKUS_REDIS_HOSTS` | `redis://localhost:6379` | Redis connection |
| `SPRING_DATA_MONGODB_URI` / `QUARKUS_MONGODB_CONNECTION_STRING` | `mongodb://localhost:27017` | MongoDB connection |
| `SPRING_DATA_MONGODB_DATABASE` / `QUARKUS_MONGODB_DATABASE` | `{id}-audit` | MongoDB database name |
| `AUDIT_LOG_TTL_DAYS` | `30` | MongoDB TTL index — records auto-expire |

When `enableAuditLog` is set, `docker-compose.yml` automatically includes `redis` and `mongo` services.

---

## Common combinations

```bash
JAR="apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"

# Quarkus + Angular, Kubernetes deployment
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/quarkus \
  --cartridge=apibridge-cartridges/frontend/angular \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/k8s/kubernetes \
  --output=output/quarkus-angular-k8s \
  --be-flavor=quarkus \
  --fe-flavor=angular

# Spring Boot only, OpenShift deployment
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/k8s/kubernetes \
  --cartridge=apibridge-cartridges/devops/k8s/openshift \
  --output=output/spring-openshift

# UI schema only
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/frontend/ui-schema \
  --output=output/ui-schema
```

---

## Development

```bash
# Unit tests (fast — run freely)
mvn test

# Full verify: unit tests + Checkstyle
mvn verify

# E2E tests (slow — run on CI or before shipping)
./e2e-tests/run-all-e2e.sh
```

Checkstyle rules: 4-space indent, no star imports, no unused imports, braces required.

### Adding a cartridge

1. Create a directory anywhere under `apibridge-cartridges/` (the path becomes the `--cartridge=` argument).
2. Add `.ftl` FreeMarker templates. The output filename is the template name with `.ftl` stripped; directory tree is mirrored 1:1 to output.
3. Available template variables:

| Variable | Type | Notes |
|---|---|---|
| `id` | String | Service identifier |
| `basePath` | String | REST base path |
| `flags` | Flags | Schema flags object (may be null if `flags:` key absent) |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | `spring-boot` or `quarkus` (never null) |
| `feFlavor` | String | `react`, `angular`, `vue`, or `""` if unset |
| `deployTarget` | String | `docker-compose`, `kubernetes`, `openshift`, or `""` |
| `flags.pagination` | Pagination | Pagination param names; never null when flags is non-null |
| `flags.enableAuditLog` | boolean | `true` generates Redis Streams + MongoDB audit infrastructure |
| `flags.enableCircuitBreaker` | boolean | `true` wraps all proxy calls with Resilience4j circuit breaker + retry; configurable via `CB_*` ENV VARs |
| `flags.enableResponseCache` | boolean | `true` adds GET response cache (Caffeine by default, Redis when `CACHE_REDIS_URL` set); configurable via `CACHE_*` ENV VARs |
| `flags.enableRateLimiter` | boolean | `true` wraps all proxy calls with Resilience4j rate limiter; configurable via `RATE_LIMIT_*` ENV VARs |
| `flags.enableTransform` | boolean | `true` enables per-endpoint header/field request/response transformation |
| `flags.enableHealthCheck` | boolean | `true` generates periodic upstream health probing + `/api/bridge-health` endpoint |
| `flags.enableSearch` | boolean | `true` adds search bar + column filters to List pages |
| `flags.enableOfflineSupport` | boolean | `true` generates Service Worker for offline-capable SPA |
| `flags.enableOpenApi` | boolean | `true` generates OpenAPI 3.0.3 spec from schema |
| `flags.apiVersion` | String | Global version prefix (e.g. `"v1"`) on proxy routes; null = no prefix |
| `endpoint.uiLayout.component` | String | `Form`, `List`, or `View` |
| `endpoint.uiLayout.columns` | List\<Column\> | Schema-defined list columns (optional; runtime fallback if absent) |
| `endpoint.uiLayout.searchMode` | String | `"delegate"` or `"local"` — search/filter strategy for List endpoints (requires `enableSearch`) |
| `endpoint.transforms` | Transforms | Per-endpoint header/field transforms (requires `enableTransform`) |
| `endpoint.mockResponse` | MockResponse | Per-endpoint mock response for MOCK_MODE (statusCode, body, delayMs) |
| `field.label` | String | Optional display label for form/view fields |

**Filtering form endpoints in templates**: use `endpoints?filter(ep -> ep.method?upper_case != "GET")` to get only mutation endpoints. All Form templates already do this internally via the `formEndpoints` assignment.

Use `(feFlavor!"") != ""` to gate FE-specific content in templates that apply to both FE and BE scenarios (e.g., Dockerfile).

---

## Production best practices applied

**Container / runtime:**
- Non-root user (UID 1001, `chmod g=u` for OpenShift arbitrary-UID policy)
- JVM: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`
- `JAVA_OPTS` passed through for runtime tuning without image rebuild
- Graceful shutdown configured (30 s drain)
- HTTP compression enabled
- Structured JSON logging for EFK / Loki / CloudWatch

**Kubernetes manifests:**
- Startup, liveness, and readiness probes (flavor-conditional paths)
- `readOnlyRootFilesystem: true` + `emptyDir` for `/tmp`
- `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]`
- CPU/memory requests and limits
- `terminationGracePeriodSeconds: 45`
- Kustomization image tag override

---

## CI

GitHub Actions (`.github/workflows/ci.yml`): `build` job (`mvn verify` on JDK 21) → `e2e-compile` (all cartridge compile checks) → `e2e-docker` (fullstack Docker build + runtime) → `e2e-json-server` (live API integration). Triggers on push to `main`/`feature**`/`bugfix**` and PRs to `main`.
