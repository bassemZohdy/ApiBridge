# ApiBridge — Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added — Phase 6: Model + Validation (Track 0)

- 7 new `Flags` fields: `enableRateLimiter`, `enableTransform`, `apiVersion`, `enableHealthCheck`, `enableSearch`, `enableOfflineSupport`, `enableOpenApi`.
- New `Endpoint` fields: `transforms` (with `HeaderTransform`, `FieldTransform` inner classes), `mockResponse` (with `statusCode`, `body`, `delayMs`).
- New `UiLayout` field: `searchMode` (`"delegate"` | `"local"`).
- `YamlParser` validation: `apiVersion` pattern `v[0-9]+`; `searchMode` enum + List-only guard; `mockResponse.statusCode` 100–599; `mockResponse.delayMs` >= 0.
- 7 new FreeMarker context variables in `ApiBridgeCartridgeEngine`: `enableRateLimiter`, `enableTransform`, `apiVersion`, `enableHealthCheck`, `enableSearch`, `enableOfflineSupport`, `enableOpenApi`.
- 20 new tests (14 parser + 6 engine). Test count: 137 → 157.

### Added — Rate limiting (`flags.enableRateLimiter`)

- New schema flag `flags.enableRateLimiter: true` generates Resilience4j rate limiter wrapping proxy calls. Layer order: `RateLimiter → CircuitBreaker → Retry → HTTP call`.
- Returns `429 {"error":"Too Many Requests","rateLimit":"exceeded"}` when limit exceeded.
- Runtime ENV VARs: `RATE_LIMIT_PERMITS` (default 10), `RATE_LIMIT_PERIOD_SECONDS` (default 1), `RATE_LIMIT_TIMEOUT_MILLIS` (default 5000).
- Both Spring Boot and Quarkus: `resilience4j-ratelimiter` dep, `RateLimiter` init from ENV VARs, `RequestNotPermitted` catch → 429.
- `docker-compose.yml.ftl` + `configmap.yaml.ftl` gain conditional `RATE_LIMIT_*` ENV VAR blocks.
- 8 new tests. Test count: 157 → 165.

### Added — Redis distributed cache (dual cache for `flags.enableResponseCache`)

- Existing `flags.enableResponseCache: true` now supports Redis as an alternative to Caffeine. Runtime `CACHE_REDIS_URL` env var presence selects Redis vs Caffeine at startup — zero breaking change.
- Common `ResponseCache` interface with `CaffeineResponseCache` and `RedisResponseCache` implementations in both Spring Boot and Quarkus `ProxyService`.
- Spring Boot: `spring-boot-starter-data-redis` dep when `enableResponseCache=true` OR `enableAuditLog=true`. `RedisResponseCache` uses `StringRedisTemplate` (only generated when `enableAuditLog=true` since Redis connection factory is shared).
- Quarkus: `quarkus-redis-client` dep when `enableResponseCache=true` OR `enableAuditLog=true`. `RedisResponseCache` uses `RedisClient` (only generated when `enableAuditLog=true`).
- `docker-compose.yml.ftl`: `CACHE_REDIS_URL` env var + conditional `redis` service when cache enabled without audit.
- `configmap.yaml.ftl`: `CACHE_REDIS_URL` entry when cache enabled.
- 2 new tests. Test count: 165 → 167.

### Added — Debug mode (`DEBUG_MODE` runtime ENV VAR)

- New `DebugLoggingFilter.java.ftl` for both Spring Boot (`OncePerRequestFilter`) and Quarkus (`ContainerRequestFilter` + `ContainerResponseFilter`).
- Filter is always generated but inert unless `debug.mode=true` / `DEBUG_MODE=true`.
- Logs full request/response details at DEBUG level: method, URI, headers (authorization masked), status, duration.
- `DEBUG_MODE` env var added to `docker-compose.yml.ftl` and `configmap.yaml.ftl`.
- 4 new tests. Test count: 167 → 171.

### Added — Request/Response Transformation (`flags.enableTransform`)

- New schema flag `flags.enableTransform: true` enables per-endpoint request/response header and JSON field transformation in the proxy layer.
- `ProxyService` gains `applyHeaderTransforms()` (add, remove, rename headers) and `applyFieldTransforms()` (rename, remove JSON body keys using Jackson `ObjectMapper`) static methods in both Spring Boot and Quarkus.
- `forward()` method signature extended with 10 transform map/list parameters (all nullable). Controller/Resource templates pass endpoint-specific transform data from schema at build time.
- Endpoints without transforms pass `null` for all transform args — no runtime overhead.
- `application.properties.ftl` documents transform behavior for both backends.
- 10 new tests (2 parser + 5 Spring Boot engine + 3 Quarkus engine). Test count: 171 → 181.

### Added — Dark Mode / Theme Switcher (always generated)

- Dark mode CSS block (`[data-theme="dark"]`) + `@media (prefers-color-scheme: dark)` fallback added to React `index.css`, Angular `styles.css`, and Vue `App.vue` global `<style>` block.
- Theme initialized from `localStorage.getItem('apib-theme')` on startup; falls back to `prefers-color-scheme` system preference.
- A fixed-position `.apib-theme-toggle` button (☀/☾) always rendered in the app shell. Clicking it toggles `data-theme` on `document.documentElement` and persists to `localStorage`.
- React: `theme` state in `App.tsx` with `useEffect` to apply to DOM; toggle button rendered as `{themeToggle}` fragment in every route return.
- Angular: `theme` field + `initTheme()` / `toggleTheme()` methods in `AppComponent`; toggle button in `app.component.html`.
- Vue: `theme` ref + `applyTheme()` / `toggleTheme()` in `App.vue <script setup>`; toggle button in `<template>`; dark CSS in unscoped `<style>` block.
- Dark mode is not behind a flag — always generated. No schema changes required.
- 3 new engine tests (one per framework). Test count: 203 → 206.

### Added — Search & Filtering (`flags.enableSearch`)

- New schema flag `flags.enableSearch: true` adds a search bar to all List pages across React, Angular, and Vue frontends.
- Per-endpoint `uiLayout.searchMode: "delegate"` passes `?${SEARCH_PARAM}=<term>` to the upstream API; `"local"` fetches all data and filters client-side (substring match across all visible columns).
- URL hash sync: search term written to hash query string (`#/list?q=<term>`) and read on component init.
- `BridgeConfigController` / `BridgeConfigResource` expose `enableSearch` and `searchParam` in `/api/bridge-config`.
- `BridgeConfig` TypeScript interface (React, Angular, Vue) gains `enableSearch: boolean` and `searchParam: string`.
- Runtime ENV VAR `SEARCH_PARAM` (default `q`) overrides the search param name; added to `docker-compose.yml` and `configmap.yaml`.
- 6 new engine tests. Test count: 197 → 203.

### Changed

- Test count: 137 → 206 (69 new tests from Phase 6: Track 0 + F1–F9).

---

## [0.1.0] — 2026-05-26

### Added — Circuit breaker + retry (`flags.enableCircuitBreaker`)

- New schema flag `flags.enableCircuitBreaker: true` generates Resilience4j circuit breaker + retry wrapping every upstream proxy call. No additional infrastructure required.
- **Spring Boot**: `resilience4j-circuitbreaker` + `resilience4j-retry` added to `pom.xml`. `ProxyService` initializes `CircuitBreaker` + `Retry` programmatically from ENV VARs in constructor via static factory methods.
- **Quarkus**: Same dependencies + initialization in `@PostConstruct init()`.
- Circuit opens after `CB_FAILURE_RATE_THRESHOLD`% failures in `CB_SLIDING_WINDOW_SIZE` calls; stays open `CB_WAIT_DURATION_SECONDS`s; then moves to HALF-OPEN. Returns `503 {"error":"Service Unavailable","circuit":"open"}` (`CallNotPermittedException`) when open.
- Retry wraps the upstream call before the CB counts a failure; up to `CB_RETRY_MAX_ATTEMPTS` attempts with fixed `CB_RETRY_WAIT_MS`ms wait.
- `docker-compose.yml.ftl` + `configmap.yaml.ftl` gain conditional `CB_*` ENV VAR blocks.
- 9 new tests: `YamlParserTest` (3) + `ApiBridgeCartridgeEngineTest` (6).

### Added — Response cache (`flags.enableResponseCache`)

- New schema flag `flags.enableResponseCache: true` generates an in-process Caffeine GET response cache in `ProxyService`. No additional infrastructure required.
- **Spring Boot**: `caffeine` added to `pom.xml` (version managed by Spring Boot BOM). Cache built in constructor with TTL + max-size from `CACHE_TTL_SECONDS` / `CACHE_MAX_SIZE` ENV VARs.
- **Quarkus**: `caffeine:3.1.8` added to `pom.xml`. Cache built in `@PostConstruct init()`.
- Cache key = full upstream URL + query string. GET hit → return immediately without upstream call. Non-GET request → `invalidateAll()` for consistency.
- `docker-compose.yml.ftl` + `configmap.yaml.ftl` gain conditional `CACHE_*` ENV VAR blocks.
- 9 new tests: `YamlParserTest` (3) + `ApiBridgeCartridgeEngineTest` (6).
- Test count: 119 → 137.

### Added — Audit log (`flags.enableAuditLog`)

- New schema flag `flags.enableAuditLog: true` generates a decoupled proxy call audit trail using Redis Streams as the event transport and MongoDB as the record store.
- **Event state machine per request**: `SEND` (emitted before upstream call, creates a PENDING `AuditRecord`) → `SUCCESS` (updates record with response status, body, duration) or `FAIL` (updates record with error message, duration). Correlation ID (UUID) links events across the lifecycle.
- **Spring Boot**: `ApplicationEventPublisher` dispatches `ProxySendEvent`, `ProxySuccessEvent`, `ProxyFailEvent` in-process. `@EventListener @Async` `RedisAuditPublisher` forwards each to the Redis Stream `apibridge:audit`. `AuditStreamConsumer` reads via `StreamMessageListenerContainer` (consumer group `apibridge-audit-group`) and writes/updates MongoDB via `MongoTemplate`. `Application.java` gains `@EnableAsync`.
- **Quarkus**: CDI `Event<T>.fireAsync()` dispatches the same three event types. `@ObservesAsync` `RedisAuditPublisher` forwards to Redis using `ReactiveRedisDataSource`. `AuditStreamConsumer` polls via a scheduled XREAD loop and persists via Panache MongoDB.
- **`AuditRecord`** MongoDB document: `correlationId`, `endpoint`, `method`, `requestBody`, `status`, `responseStatus`, `responseBody`, `errorMessage`, `durationMs`, `sentAt`, `completedAt`, `expiresAt` (TTL index — MongoDB handles log rotation automatically via `AUDIT_LOG_TTL_DAYS`, default 30 days).
- Unacknowledged stream entries are redelivered on consumer restart — audit logging never blocks or fails the proxy call.
- `docker-compose.yml.ftl` gains conditional `redis` and `mongo` services + `depends_on` when flag is set.
- `configmap.yaml.ftl` gains conditional audit connection URI env vars.
- New runtime ENV VARs: `AUDIT_REDIS_URI` / `QUARKUS_REDIS_HOSTS`, `AUDIT_MONGO_URI` / `QUARKUS_MONGODB_CONNECTION_STRING`, `AUDIT_MONGO_DATABASE`, `AUDIT_LOG_TTL_DAYS`.
- 3 new `YamlParserTest` cases (`enableAuditLog` default, explicit true, explicit false).
- 4 new `ApiBridgeCartridgeEngineTest` cases (Spring Boot with/without audit, Quarkus with audit, docker-compose with audit).
- Test count: 91 → 98 (7 new).

### Added

- Form field validation driven by schema `field.type` across React, Angular, and Vue Form templates:
  - `email` maps to `<input type="email">` with HTML5 pattern validation; Angular adds `Validators.email`.
  - `date` → `type="date"`, `url` → `type="url"`, `password` → `type="password"`, `number`/`integer` → `type="number"`, `boolean` → checkbox.
  - Previously only `boolean` → checkbox and `number` → number were mapped; all other types fell back to `text`.
- Kubernetes manifest validation E2E suite (`e2e-tests/kubernetes-test/`) — validates Deployment, Service, ConfigMap, Kustomization structure, health probes, security context, and Spring Boot vs Quarkus flavor differences.
- OpenShift manifest validation E2E suite (`e2e-tests/openshift-test/`) — validates Route, TLS edge termination, and kustomization includes route resource.
- React production build E2E suite (`e2e-tests/react-prod-build-test/`) — runs `npm run build` on generated React app and verifies `dist/index.html`.
- Unit tests for generated backend API method names (Spring Boot + Quarkus) — verifies `postLogin`, `getSubmissions`, `putSubmissions`, `deleteSubmissions`, `getUserProfiles` naming patterns.
- Unit tests for DevOps cartridges — Dockerfile (Spring Boot vs Quarkus, with/without frontend, env vars, health checks, non-root user), docker-compose (Spring Boot vs Quarkus, apiKey vs bearer-token, resource limits).
- PUT and DELETE endpoints added to `sample-schema.yaml` — now exercises full CRUD (GET list, GET view, POST, PUT, DELETE).
- CI expanded from 6 to 9 compile-check steps (added Kubernetes, OpenShift, React prod build).
- E2E master suite expanded from 8 to 11 suites.

### Changed

- Test count: 80 → 137 unit tests (Phase 5 added 18 tests on top of the 80→91→119→137 progression).
- `HANDOFF.md` test counts updated to reflect current state.

### Added

- **Engine**: `ApiBridgeRunner` (CLI with repeatable `--cartridge=`, `--be-flavor=`, `--fe-flavor=`, `--deploy-target=`, `--security-level=` overrides), `ApiBridgeCartridgeEngine` (1:1 directory-tree rendering with auto-prefix for `backend/`, `frontend/`, `k8s/` categories), `YamlParser` (YAML → `BridgeSchemaModel` with validation), `BridgeSchemaModel` (full Javadoc on all classes/fields).
- **Backend cartridges**:
  - `backend/spring-boot` — `BridgeController.java` (HTTP method shortcuts, proxy/mock/block), `ProxyService.java` (RestTemplate, header+query forwarding, configurable timeouts), `Application.java`, `pom.xml` (spring-boot-starter-parent 3.2.5), `application.properties`.
  - `backend/quarkus` — `BridgeResource.java` (JAX-RS, `@ConfigProperty`, method-prefix naming), `ProxyService.java` (JAX-RS Client, `@ApplicationScoped`), `pom.xml` (Quarkus BOM 3.9.4), `application.properties`.
- **Frontend cartridges**:
  - `frontend/react` — `ApiBridgeForm.tsx`, `ApiBridgeList.tsx`, `ApiBridgeView.tsx`, `App.tsx`, `bridgeApi.ts`, `bridgeConfig.ts`, Vite + TypeScript + MUI-based.
  - `frontend/angular` — `bridge-form.component`, `bridge-list.component`, `bridge-view.component`, `app.component`, `bridge-api.service`, `app.module`, Angular 17 + ngx-formly.
  - `frontend/vue` — `ApiBridgeForm.vue`, `ApiBridgeList.vue`, `ApiBridgeView.vue`, `App.vue`, `bridgeApi.ts`, Vue 3 Composition API + Vite.
  - `frontend/ui-schema` — `UiLayoutSchema.json` with columns, fields, labels.
- **DevOps cartridges**:
  - `devops/dockerfile` — Multi-stage Dockerfile (optional FE build → BE build → minimal runtime). Non-root user (UID 1001), OCI labels, per-endpoint `BACKEND_URL_*` env vars, pagination/telemetry/security env vars, Spring Boot vs Quarkus health probes.
  - `devops/docker-compose` — Docker Compose with build args, resource limits, health checks, network isolation.
  - `devops/k8s/kubernetes` — Deployment (security context, probes, resource limits), ClusterIP Service, ConfigMap, Kustomization.
  - `devops/k8s/openshift` — Extends Kubernetes with OpenShift Route (TLS edge termination).
- **Security**: `bearer-token` (JWT validation via `AUTH_SERVER_URL`) and `apiKey` (X-API-Key header). All 3 frontends export `getAuthHeaders()`.
- **Telemetry**: OpenTelemetry spans (`http.method`, `http.url`, `StatusCode.ERROR`) on both backends when `enableTelemetry: true`.
- **Schema validation**: HTTP method whitelist, case-insensitive `uiLayout.component`, duplicate endpoint detection (same path + method), required fields enforced.

### Fixed

- Removed duplicate React/Angular View components and stale `bridge-view.component.ts` class.
- Fixed unescaped FreeMarker `${...}` in Angular View, React List, and Angular View (`${token}`) template literals.
- Fixed uninitialized `upstream` in Quarkus `ProxyService` `finally` block (compile error).
- Fixed broken URL construction in Angular `bridge-list.component.ts`.
- Spring Boot error responses now `Content-Type: application/json` (was `text/plain`).
- Auth `RestTemplate` has 5s connect / 10s read timeouts (was unbounded).
- Quarkus auth `Response` properly closed (connection leak).
- CORS includes `exposedHeaders("*")` and `maxAge(3600)` — upstream headers visible to frontend JS.
- Telemetry spans set `StatusCode.ERROR` on exceptions.
- All `flags` accesses null-safe — templates handle missing `flags:` section.
- Frontend API method naming collision resolved: HTTP prefix + path segments + "By" suffix (e.g. `getSubmissions`, `getSubmissionsById`, `postInitiate`).
- Backend method name collision resolved: method prefix added (e.g. `getUsers()`, `postUsers()`).
- `ProxyService` forwards query parameters and all non-hop-by-hop request/response headers in both backends.
- 502 responses return generic `{"error":"Bad Gateway"}` instead of leaking `ex.getMessage()`.
- Angular Form has Back button and `@Output() navigate`.
- Angular Form component reads token from `localStorage` (was hardcoding empty strings).
- Form templates filter GET endpoints via `formEndpoints` — prevents null `field.type` crash on View endpoints.
- GET+body bug fixed in all 3 frontend API layers (React, Angular, Vue).
- `Pagination` auto-initialized in `BridgeSchemaModel.Flags` — `getPagination()` never null when flags present.
- E2E scripts: Vue uses `vue-tsc`, contract symmetry uses portable `while read`, empty-array expansion fixed for bash 3.2, generator built once and shared across suites.

### Changed

- Removed `navigationMode` and `uiPattern` flags from entire codebase (dead code).
- `/api/bridge-config` returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath`, pagination config.
- DevOps templates include all `PAGINATION_*` and `CUSTOM_CSS_PATH` env vars.
- Removed unused imports, dead code (`Vue pathToMethod`, unused `axios` dep).
- Aligned mock-mode method case to uppercase in both backends.
- Quarkus FE static resource config conditional on `feFlavor` with 365d cache headers.
- Angular list/view use `getAuthHeaders()` consistently.
- `UiLayoutSchema.json` includes `columns` array and `field.label`.
- Quarkus `BridgeConfigResource` has `@ApplicationScoped`, `pom.xml.ftl` has `<name>` and `<description>`.
- Angular `styles.css.ftl` has `.apib-spinner--dark`; Vue View has `<style scoped>`.
- Cartridge layout finalised: `frontend/ui-schema`, `devops/k8s/{kubernetes,openshift}`, engine `OUTPUT_PREFIX_CATEGORIES` = `{backend, frontend, k8s}`.
- Composable cartridge architecture: monolithic `fullstack/` cartridge removed; independent cartridges composed via repeatable `--cartridge=`. `feFlavor` defaults to null (detectable via `(feFlavor!"") != ""`).
- `sample-schema.yaml` exercises all three page types (List, View, Form) with columns, labels, and pagination.

### Removed

- Standalone component-only cartridges (`frontend-angular/`, `frontend-react/`, `frontend-vue/`).
- Monolithic `fullstack/` cartridge, old `backend-spring-boot/` and `backend-quarkus/`.
- Old pre-cartridge built-in templates (`src/main/resources/templates/`).
- Committed E2E runtime artifacts (`e2e-tests/*/generated/`).
- Stale per-test `pom.xml`, `package.json`, `tsconfig.json` scaffolding from `e2e-tests/`.
