# ApiBridge — Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [0.1.1] — 2026-05-31

Bug-fix release: correctness and safety fixes.

### Generator & Engine Fixes

- **Enum flag normalization** — `validateFlagsSection()` now writes canonical lowercase values back into the model after validation. Mixed-case YAML values (e.g. `"Bearer-Token"`) no longer silently skip template auth branches.
- **Bearer-token fail-closed** — Both Spring Boot and Quarkus `validateBearerToken()` now return 401 when `AUTH_SERVER_URL` is blank. Previously accepted any token unconditionally when no URL was configured.
- **Route-shape duplicate detection** — `YamlParser` and `SchemaComposer` now normalize path variables (`{id}`, `{userId}`) to a stable placeholder `{*}` before checking for duplicates, preventing ambiguous runtime handler mappings.
- **Quarkus `Response` import collision** — Removed `import io.vertx.redis.client.Response;` when `enableResponseCache && enableAuditLog` are both true. Usage now fully-qualified to avoid collision with `jakarta.ws.rs.core.Response`.
- **Atomic cartridge cache** — Downloads now write to a `<hash>.tmp` directory and atomically rename to `<hash>/` on success. Failed downloads no longer leave empty directories that are treated as cached hits.
- **HTTP status code check** — `CartridgeDownloader` now throws `IOException("HTTP <N>")` on non-2xx responses instead of passing 404/500 bodies to the ZIP parser.

### Template Fixes

- **authRestTemplate timeouts** — Spring Boot `BridgeController.ftl` now uses `@Value`-injected `AUTH_CONNECT_TIMEOUT` / `AUTH_READ_TIMEOUT` (defaults 5s/10s) with `SimpleClientHttpRequestFactory`.
- **Quarkus `TimeUnit` import** — Made `import java.util.concurrent.TimeUnit;` unconditional in Quarkus `ProxyService.java.ftl`, fixing compilation failure when `enableResponseCache` was absent.
- **Spring Boot ECS logging** — Removed `logging.structured.format.console=ecs` (property requires Spring Boot 3.4.x, ignored in 3.2.5).
- **Quarkus JSON logging** — Added `quarkus-logging-json` dependency so `quarkus.log.console.json=true` actually produces JSON-formatted logs.

### E2E Reliability

- **json-server pin** — Pinned to `typicode/json-server:0.17` to avoid v1.x breaking changes (`_per_page` vs `_limit`).
- **json-server healthcheck** — Added healthcheck probe with `condition: service_healthy` to prevent Connection Refused races.

### Build & CI

- **Java 21 enforcement** — `maven-enforcer-plugin` requires Java 21+ minimum to prevent JaCoCo instrumentation errors on newer JDKs.

### Tests

- 323 Maven tests (314 → 323), 20 Vitest tests, 19 E2E suites

---

## [0.1.0] — 2026-05-31

Initial public release.

### Engine & CLI

- `ApiBridgeRunner` CLI with repeatable `--schema=` (merged via `SchemaComposer`) and `--cartridge=` (applied in sequence to the same output directory)
- `YamlParser` — full schema validation with descriptive errors at parse time
- `ApiBridgeCartridgeEngine` — 1:1 FreeMarker directory-tree rendering with auto-prefix per category (`backend/`, `frontend/`, `k8s/`)
- `SchemaComposer` — merges multiple schemas: `id`/`basePath`/`flags` from the primary schema, `endpoints` concatenated in order; cross-schema duplicates rejected
- `CartridgeResolver` — three reference formats: local path, URL (`http://`/`https://`), GitHub shorthand (`github:owner/repo[/subpath][@ref]`)
- `CartridgeCache` — deterministic SHA-256 keying under `~/.apibridge/cartridges/`; cache hit skips re-download
- CLI overrides: `--be-flavor=`, `--fe-flavor=`, `--deploy-target=`, `--security-level=` (take precedence over schema flags)
- `--version` / `-v` and `--help` / `-h` flags

### Backend Cartridges

- `backend/spring-boot` — Spring Boot 3.x REST proxy (RestTemplate, Spring Actuator, structured JSON logging)
- `backend/quarkus` — Quarkus 3.x JAX-RS proxy (JAX-RS Client, Quarkus Health, OpenTelemetry)
- Both backends proxy every schema endpoint to its `backendUrl`, forwarding all non-hop-by-hop request/response headers and query parameters
- `MOCK_MODE=true` — returns canned JSON without upstream calls; per-endpoint `mockResponse` (statusCode, body, delayMs) overrides the generic response
- `BLOCK_TRAFFIC=true` — returns 503 for every request
- `DEBUG_MODE=true` — structured request/response logging; bodies truncated to 1024 chars; Authorization values masked
- All config values overridable at runtime via ENV VARs
- Circuit breaker + retry (`enableCircuitBreaker`) — Resilience4j; opens after configurable failure-rate threshold; `CB_*` ENV VARs; returns `503 {"error":"Service Unavailable","circuit":"open"}` when open
- Response cache (`enableResponseCache`) — Caffeine by default; switches to Redis when `CACHE_REDIS_URL` is set; `CACHE_*` ENV VARs; non-GET requests invalidate the cache
- Rate limiter (`enableRateLimiter`) — Resilience4j; layer order: RateLimiter → CircuitBreaker → Retry → HTTP call; `RATE_LIMIT_*` ENV VARs; returns `429 {"error":"Too Many Requests","rateLimit":"exceeded"}`
- Request/response transformation (`enableTransform`) — per-endpoint header add/remove/rename + JSON field rename/remove via `transforms` schema section
- Health check aggregation (`enableHealthCheck`) — scheduled upstream probes at `GET /api/bridge-health`; aggregated UP/DEGRADED/DOWN with per-endpoint latency and last check time; `HEALTH_CHECK_*` ENV VARs
- Audit log (`enableAuditLog`) — Redis Streams + MongoDB proxy call trail; SEND → SUCCESS/FAIL event lifecycle; fire-and-forget (never blocks or fails the proxy call); TTL auto-rotation via `AUDIT_LOG_TTL_DAYS`
- OIDC resource server (`enableOidc`) — JWT validation against `oidcIssuerUri`; Spring Security OAuth2 (Spring Boot) or Quarkus OIDC; bridge config/health endpoints remain unauthenticated; `OIDC_ISSUER_URI` ENV VAR override
- Telemetry (`enableTelemetry`) — OpenTelemetry spans on all proxy calls with `http.method`, `http.url`, `StatusCode.ERROR` on exceptions
- API versioning (`apiVersion`) — global version prefix (`v[0-9]+`) on all proxy routes; health and config endpoints remain unversioned
- `GET /api/bridge-config` — exposes runtime config to frontends (securityLevel, basePath, pagination params, feature flags)
- `GET /custom.css` — serves a runtime-mounted brand CSS file via `CUSTOM_CSS_PATH` ENV VAR

### Frontend Cartridges

- `frontend/react` — React 18 + Vite + TypeScript + MUI (Form, List, View pages)
- `frontend/angular` — Angular 17 + ngx-formly (Form, List, View pages)
- `frontend/vue` — Vue 3 Composition API + Vite (Form, List, View pages)
- `frontend/ui-schema` — `UiLayoutSchema.json` for UI-driven form rendering
- Hash-based SPA routing — `#/list`, `#/view/:id`, `#/form`, `#/form/:id`; no router library dependency
- Form field validation driven by `field.type` — `email`, `date`, `url`, `password`, `number`/`integer`, `boolean` → native HTML input types; Angular adds `Validators.email`
- View components support DELETE — delete button rendered when a DELETE endpoint exists at the same path
- Form components support edit pre-population — `editId` fetches the View GET to fill form state
- `getAuthHeaders()` exported from all three frameworks for centralized token injection
- Search & filtering (`enableSearch`) — search bar + column filters on List pages; `delegate` mode passes params upstream; `local` mode filters client-side; `SEARCH_PARAM` ENV VAR
- Dark mode / theme switcher — always generated; CSS variables + localStorage + `prefers-color-scheme` fallback; zero bundle cost
- Offline support (`enableOfflineSupport`) — Service Worker: cache-first for app shell; stale-while-revalidate for API GET responses; network-only for non-GET; offline banner
- White-label CSS — mount a brand stylesheet at runtime via `CUSTOM_CSS_PATH`; no rebuild needed
- Pagination — page/size/sort/direction param names configurable via `PAGINATION_*` ENV VARs

### DevOps Cartridges

- `devops/dockerfile` — three-stage: FE build (node:20-alpine) → BE build + embed (maven:3.9) → runtime (amazoncorretto:21-alpine); FE stage omitted for BE-only output; non-root user (UID 1001); OCI labels; `JAVA_OPTS` passthrough; graceful shutdown 30 s
- `devops/docker-compose` — resource limits, health checks, network isolation; conditional `redis` and `mongo` services when `enableAuditLog` is set
- `devops/k8s/kubernetes` — Deployment (readiness/liveness/startup probes, security context, resource limits), ClusterIP Service, ConfigMap, Kustomization
- `devops/k8s/openshift` — extends Kubernetes with a TLS edge-terminated Route; apply on top of `kubernetes` cartridge
- `devops/k8s/helm` — Helm 3 chart: `Chart.yaml`, `values.yaml`, `templates/` (Deployment, Service, ConfigMap, Ingress); flag-gated ENV VARs in `values.yaml`; Helm `{{ }}` expressions survive FreeMarker via `${r"..."}` raw-string pattern

### Documentation Cartridge

- `docs/openapi` — generates an OpenAPI 3.0.3 spec from the schema when `flags.enableOpenApi: true`

### Web Schema Builder

- Browser-based GUI (`apibridge-web-builder/`) — Vite + React 18 + TypeScript + js-yaml
- Three-column layout: flags panel (all toggles and selectors), endpoint list/editor, live YAML preview
- Download button generates `schema.yaml` via Blob download
- TailwindCSS dark theme; 20 Vitest tests

### Distribution

- Shell wrapper scripts: `bin/apibridge` (Unix) and `bin/apibridge.bat` (Windows) — delegate to `java -jar`
- Generator Docker image (`Dockerfile.generator`) — multi-stage build with bundled cartridges; `VERSION` build-arg
- GitHub Actions CI (`.github/workflows/ci.yml`) — `mvn verify` on every push/PR to `main`, `feature**`, `bugfix**`
- GitHub Actions release workflow (`.github/workflows/release.yml`) — builds fat JAR, creates GitHub Release with ZIP archive, pushes Docker image to GHCR on `v*` tag push

### Test Coverage

- 323 unit tests (Maven — engine, parser, cartridge, schema composition, cartridge resolver/cache/downloader)
- 20 Vitest tests (web builder — serializer, FlagsPanel, EndpointList)
- ESLint v9 flat config for web builder (lint + typecheck + test in CI)
- JaCoCo coverage threshold: 85% instruction / 80% branch (`mvn verify` fails below)
- 19 E2E suites: Spring Boot compile, Quarkus compile, Angular/React/Vue tsc, React/Vue/Angular prod build, contract symmetry, K8s/OpenShift/Helm manifest validation, OpenAPI spec, UI schema, OIDC SecurityConfig, apiKey security, multi-schema composition, fullstack Docker, json-server integration
- CI pipeline: 5 jobs (`build` → `web-builder`, `e2e-compile`, `e2e-docker`, `e2e-json-server` in parallel) with concurrency groups and npm caching
