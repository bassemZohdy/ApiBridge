# ApiBridge — Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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

- Test count: 80 → 91 unit tests (11 new).
- `HANDOFF.md` test counts updated to reflect current state.

---

## [0.1.0] — 2026-05-26

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
