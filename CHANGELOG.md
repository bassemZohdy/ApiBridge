# ApiBridge — Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added — Phase 7: CLI Packaging & Distribution (P7a)

- Shell wrapper scripts: `bin/apibridge` (Unix) and `bin/apibridge.bat` (Windows) — delegate to `java -jar`.
- Generator Docker image: `Dockerfile.generator` — multi-stage build with bundled cartridges. Supports `VERSION` build-arg.
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) — `mvn verify` on every push/PR.
- GitHub Actions release workflow (`.github/workflows/release.yml`) — builds fat JAR, creates GitHub Release with ZIP archive, pushes Docker image to GHCR on `v*` tag push.
- Version smoke test in `ApiBridgeRunnerTest` — asserts `getVersion()` never returns blank.

### Added — Phase 7: Multi-Schema Composition (P7b)

- `--schema=` is now repeatable — multiple YAML files are merged into one generation run.
- `SchemaComposer` class: merges `BridgeSchemaModel` instances — `id`/`basePath`/`flags` from primary, `endpoints` concatenated, cross-schema duplicates rejected.
- 8 tests in `SchemaComposerTest`: passthrough, id/basePath from primary, endpoint merge order, duplicate detection, same-path-different-methods allowed, empty/null list validation.

### Added — Phase 7: Helm Chart Cartridge (P7c)

- New cartridge `devops/k8s/helm` — generates a complete Helm 3 chart: `Chart.yaml`, `values.yaml`, `templates/deployment.yaml`, `templates/service.yaml`, `templates/configmap.yaml`, `templates/ingress.yaml`, `templates/_helpers.tpl`.
- Helm `{{ }}` expressions survive FreeMarker via `${r"..."}` raw string pattern.
- `values.yaml` conditionally includes ENV VARs for rate limiter, cache, circuit breaker, health check, search based on flags.
- Ingress disabled by default in `values.yaml`; enabled at install time.
- 8 tests in `HelmCartridgeEngineTest`: chart metadata, values, deployment, service, configmap, ingress, flag-gated env vars, Helm expression integrity.

### Added — Phase 7: OIDC Authentication Cartridge (P7d)

- `flags.enableOidc` (boolean, default `false`) + `flags.oidcIssuerUri` (string) — generates JWT resource server config.
- Spring Boot: `SecurityConfig.java` with `SecurityFilterChain` (stateless sessions, OAuth2 resource server, bridge-config/health permitAll). `spring-boot-starter-oauth2-resource-server` dep. `spring.security.oauth2.resourceserver.jwt.issuer-uri` in application.properties.
- Quarkus: `quarkus-oidc` dep. `quarkus.oidc.*` properties in application.properties.
- Runtime override via `OIDC_ISSUER_URI` env var.
- `YamlParser` validates `oidcIssuerUri` non-blank when `enableOidc: true`.
- 7 tests in `OidcEngineTest` + 4 parser tests.

### Added — Phase 7: Web-Based Schema Builder (P7e)

- Browser-based GUI at `apibridge-web-builder/` — Vite + React 18 + TypeScript + js-yaml.
- Three-column layout: flags panel (all toggles + selectors), endpoint list/editor, live YAML preview.
- Download button generates `schema.yaml` via `Blob` download.
- 15 Vitest tests: serializer (8), FlagsPanel (4), EndpointList (3).
- TailwindCSS dark theme.

### Added — Phase 7: Plugin/External Cartridge Registry (P7f)

- `--cartridge=` now accepts three formats: local path, URL (`http://`/`https://`), GitHub shorthand (`github:owner/repo[/subpath][@ref]`).
- `CartridgeCache`: manages `~/.apibridge/cartridges/<sha256>/` — deterministic SHA-256 keying, cache hit = no re-download.
- `CartridgeDownloader`: `java.net.http.HttpClient` fetch, zip-slip-safe extraction via canonical path validation.
- `CartridgeResolver`: parses three reference formats, routes to downloader+cache for remote refs, passes local paths through.
- `ApiBridgeRunner` routes every `--cartridge=` through `CartridgeResolver`.
- 7 tests in `CartridgeCacheTest`, 4 in `CartridgeDownloaderTest`, 6 in `CartridgeResolverTest`.

### Changed

- Test count: 254 → 305 (51 new tests across P7 sub-phases + cleanup).
- `ApiBridgeRunner` updated: multi-schema via `SchemaComposer`, cartridge resolution via `CartridgeResolver`, `InterruptedException` handling.
- FreeMarker context gains `enableOidc` (boolean) and `oidcIssuerUri` (String) variables.
- `YamlParserTest` split into 10 feature-named files (131 tests).
- `ApiBridgeCartridgeEngineTest` split into 18 feature-named classes (170 tests).
- `ApiBridgeRunnerTest` (4 tests). Grand total: 305.

### Fixed — Post-P7 anti-pattern review (H1–H11)

- **H1** Removed 91-line duplicate component definition in `react/ApiBridgeView.tsx.ftl` (lines 160–251 were dead copy of lines 1–158) — generated invalid TypeScript with duplicate exports.
- **H2** Fixed broken JS template literal in `angular/bridge-list.component.ts.ftl` — `${'$'}{r"${basePath}"}` produced undefined `r` at runtime; now uses `${basePath}` (FreeMarker inlines the value).
- **H3** Replaced `HashMap` with `ConcurrentHashMap` in `ApiBridgeCartridgeEngine.CONFIGURATION_CACHE` — thread-safe for concurrent `generate()` calls.
- **H4** Added null guard on `model` parameter in `YamlParser.validate()`.
- **H5** Added null/blank guard on `cartridgeArg` in `CartridgeResolver.resolve()`.
- **H6** Added null guards on `url`/`targetDir` in `CartridgeDownloader.downloadAndExtract()`.
- **H7** Converted `TemplateEntry` inner class to record in `ApiBridgeCartridgeEngine`.
- **H8** Made `validateEnum()` static in `YamlParser` — has no instance dependency.
- **H9** Deduplicated `resolvedBeFlavor`/`resolvedFeFlavor`/`resolvedDeployTarget` to reuse `resolvedString()` helper.
- **H10** Replaced fully-qualified `java.util.Set` refs in `ApiBridgeCartridgeEngine` with proper import.
- **H11** Normalized 17 bare `<#if flags.enableTelemetry>` → `<#if (flags.enableTelemetry)!false>` across 10 templates for consistency with all other boolean flag guards.
- **A1** Extracted `validateEnum()`, `formatEnumValues()`, `requireNonBlankIf()`, `requireFlagForField()` helpers in `YamlParser.java` — replaced 4 repeated flag-level enum validation blocks.
- **A2** Generalized cross-field validation: `requireNonBlankIf()` for OIDC/telemetry, `requireFlagForField()` for searchMode/enableSearch.

### Fixed — Pre-P7 code review round 2 (V6, V7, Q4–Q7)

- **V6** Transform `add` map now validates blank header values — mirrors the `rename` map validation that already checked both keys and values.
- **V7** Transform warning deduplicated — printed once per `validate()` call listing all affected endpoints, instead of once per endpoint.
- **Q4** Removed unused `flags` parameter from `applyOverride()` in `ApiBridgeRunner`.
- **Q5** Documented that `Pagination` is auto-initialized (never null when flags present) — the null guard checks user intent, not null-safety.
- **Q6** Removed dead `flags??` outer guard from `openapi.yaml.ftl` — `flags` is always non-null in the FreeMarker context.
- **Q7** `configurationCache` made `static final` for JVM-wide reuse across multiple `ApiBridgeCartridgeEngine` instances.

### Fixed — Pre-P7 code review (B1, V1–V5, Q2, Q3)

- **B1** React List `${id}` unescaped in backtick string — FreeMarker was substituting the schema `id` at generation time instead of the JavaScript row variable. Now uses `${r"${id}"}` like Angular and Vue.
- **V1** `searchMode` now requires `flags.enableSearch: true` — throws `IllegalArgumentException` when searchMode is set without the flag.
- **V2** `searchMode` validation order fixed — List-component check runs before value check, so Form+badValue reports "only valid on List" instead of "Must be delegate/local".
- **V3** Transforms internals validated when `enableTransform: true` — blank/null keys or values in rename maps and blank entries in remove lists now throw `IllegalArgumentException`.
- **V4** Warning printed when transforms defined but `enableTransform` is false — `System.err.println` warns that transforms will be ignored.
- **V5** Pagination param names validated for blank — `pageParam`, `sizeParam`, `sortParam`, `directionParam` must all be non-blank when pagination object is present.
- **Q1** `buildContext()` top-level enableX flags investigated — NOT dead code; templates actively use `enableOfflineSupport`, `enableOpenApi`, etc. as top-level FreeMarker variables. Kept as-is with clarifying comment.
- **Q2** FreeMarker `Configuration` now cached per cartridge directory — `Map<String, Configuration>` avoids redundant allocation on multi-cartridge runs.
- **Q3** `ApiBridgeRunner` always re-validates after CLI overrides — `parser.validate(model)` called unconditionally; `applyOverride()` helper prevents future misses.

### Added

- Rate limiting (`flags.enableRateLimiter`) — Resilience4j rate limiter wrapping proxy calls. 429 when exceeded. Runtime: `RATE_LIMIT_*` env vars.
- Redis distributed cache (`flags.enableResponseCache`) — Caffeine by default, Redis when `CACHE_REDIS_URL` set. Zero breaking change.
- Request/response transformation (`flags.enableTransform`) — Per-endpoint header add/remove/rename + JSON field rename/remove.
- API versioning (`flags.apiVersion`) — Global prefix on proxy routes. Pattern: `v[0-9]+`.
- Enhanced mock mode — Per-endpoint `mockResponse` (statusCode, body, delayMs) overrides generic mock.
- Debug mode (`DEBUG_MODE` env var) — Runtime-only. Logs full request/response as structured JSON.
- Health check aggregation (`flags.enableHealthCheck`) — Scheduled upstream probes at `/api/bridge-health`. Runtime: `HEALTH_CHECK_*` env vars.
- Search & filtering (`flags.enableSearch`) — Search bar + column filters on List pages. Per-endpoint `searchMode: "delegate" | "local"`.
- Dark mode / theme switcher — Always generated. CSS variables + localStorage + prefers-color-scheme fallback.
- Offline support (`flags.enableOfflineSupport`) — Service Worker: cache-first shell, stale-while-revalidate API, network-only non-GET.
- OpenAPI 3.0 spec (`flags.enableOpenApi`) — New `docs/openapi` cartridge. Generates spec from schema.
- 7 new `Flags` fields, `Transforms`/`MockResponse` model classes, `searchMode` on `UiLayout`.
- 7 new FreeMarker context variables in `ApiBridgeCartridgeEngine`.

### Changed

- Test count: 137 → 254 (117 new tests).
- `YamlParserTest` split into 9 feature-named files (126 tests).
- `ApiBridgeCartridgeEngineTest` split into 16 feature-named classes (128 tests).
- `ApiBridgeRunnerTest` (4 tests). Grand total: 254.

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
