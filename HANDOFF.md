# ApiBridge — Handoff Notes

For architecture, schema reference, cartridge inventory, CLI usage, and E2E pipeline see **AGENTS.md** and **docs/schema-reference.md**.

---

## Generated backend endpoints

Every generated backend exposes these built-in endpoints regardless of schema:

| Endpoint | Purpose |
|---|---|
| `GET /api/bridge-config` | Returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath`, `enableHealthCheck`, `enableSearch`, `searchParam`, `apiVersion`, and all pagination config. |
| `GET /custom.css` | Serves the mounted brand CSS file pointed to by `CUSTOM_CSS_PATH`. |
| `GET /api/bridge-health` | When `enableHealthCheck: true` — aggregated upstream health with per-endpoint latency and last check time. |
| `{method} {basePath}{path}` | Proxies each schema endpoint to its `backendUrl`. Prefixed with `/{apiVersion}` when `flags.apiVersion` is set. |

All error responses use `Content-Type: application/json`.

---

## Test status

```
mvn test → 254/254 PASS
```

| Test class | Count | Covers |
|---|---|---|
| `YamlParser*` (9 files) | 119 | Schema validation: HTTP methods, duplicates, feature flags, apiVersion, mockResponse, transforms, uiLayout, pagination |
| `CoreCartridgeEngineTest` | 33 | Cartridge generation, composability, FreeMarker context, method names, security |
| `DevOpsCartridgeEngineTest` | 17 | Dockerfile, Docker Compose, k8s ConfigMap |
| `TransformEngineTest` | 20 | Header + field transforms, controller args, pass-through |
| `DistributedCacheEngineTest` | 10 | Redis dual-cache, CACHE_REDIS_URL switching |
| `SearchFilterEngineTest` | 10 | Search bar (React/Angular/Vue), delegate vs local |
| `AuditLogEngineTest` | 4 | Redis Streams + MongoDB audit trail |
| `CircuitBreakerEngineTest` | 6 | Resilience4j CB + retry |
| `ResponseCacheEngineTest` | 6 | Caffeine cache |
| `RateLimiterEngineTest` | 6 | Resilience4j rate limiter |
| `HealthCheckEngineTest` | 7 | HealthCheckService + endpoint + env vars |
| `OfflineSupportEngineTest` | 6 | Service Worker (React/Angular/Vue) |
| `OpenApiEngineTest` | 6 | openapi.yaml generation + pom deps |
| `ApiVersioningEngineTest` | 4 | API version prefix in routes |
| `DebugModeEngineTest` | 4 | DebugLoggingFilter (Spring + Quarkus) |
| `DarkModeEngineTest` | 3 | Theme toggle (React/Angular/Vue) |
| `MockModeEngineTest` | 2 | Schema-defined mock body/status |
| `ApiBridgeRunnerTest` | 2 | CLI argument handling |

E2E suites (11 total): Spring Boot compile, Quarkus compile, Angular tsc, React tsc, Vue tsc, React prod build, contract symmetry, Kubernetes manifests, OpenShift manifests, fullstack Docker, json-server.

---

## Key design invariants

1. **No cross-cartridge dependencies** — each cartridge is self-contained.
2. **FreeMarker `${...}` in JSX/TS template literals** must be escaped as `${r"${...}"}`.
3. **Form templates filter GET endpoints** — `formEndpoints` filters non-GET at template top.
4. **Custom CSS loads after the Vite bundle** — injected dynamically so brand overrides win.
5. **`Pagination` is auto-initialized** — `getPagination()` never null when flags present.
6. **Method names are collision-free** — HTTP prefix + path segments + "By" suffix.
7. **ProxyService forwards headers and query params** — all non-hop-by-hop headers; query params appended.
8. **All 3 frontends export `getAuthHeaders()`** — React/Vue from `bridgeApi.ts`, Angular on `BridgeApiService`.
9. **View components support DELETE** — delete button rendered when DELETE endpoint exists for same path.
10. **Form components support edit pre-population** — `editId` fetches View GET to fill form state.
11. **Bearer-token security via `AUTH_SERVER_URL`** — validates JWT if set; pass-through otherwise.
12. **Telemetry spans** — OTel spans with `http.method`, `http.url`, `StatusCode.ERROR` on exceptions.
13. **CORS `exposedHeaders("*")` + `maxAge(3600)`** — upstream headers visible to frontend JS.
14. **All `flags` accesses null-safe** — `(flags.field)!default` pattern in all templates.
15. **Error responses are JSON** — both backends return `application/json` error bodies.
16. **Auth RestTemplate has timeouts** — 5s connect / 10s read.
17. **Proxy timeouts configurable** — `PROXY_CONNECT_TIMEOUT` / `PROXY_READ_TIMEOUT` env vars.
18. **Form field type mapping** — `email` → `<input type="email">` + pattern; `date`/`url`/`password` → native HTML types.
19. **Audit log is fire-and-forget** — events via `@Async`/`fireAsync`. Redis/MongoDB down = proxy still works.
20. **Audit Redis Stream** — key `apibridge:audit`, consumer group `apibridge-audit-group`. Events: `SEND` → `SUCCESS`/`FAIL`.
21. **Audit MongoDB TTL** — `expiresAt` field with `expireAfterSeconds=0`; auto-expires via MongoDB.
22. **Circuit breaker wraps retry** — retry first, then CB counts failure. 503 when open.
23. **Response cache is GET-only** — `Cache.getIfPresent(urlWithQuery)` for GET; `invalidateAll()` on non-GET.
24. **Cache is Caffeine by default** — `CACHE_TTL_SECONDS` (60) + `CACHE_MAX_SIZE` (1000). Redis when `CACHE_REDIS_URL` set.
25. **Rate limiter wraps outside CB** — `RateLimiter → CircuitBreaker → Retry → HTTP call`. 429 when exceeded.
26. **Distributed cache is runtime-determined** — `CACHE_REDIS_URL` selects Redis vs Caffeine. Zero breaking change.
27. **Transforms are per-endpoint and optional** — no transforms = unchanged proxy call.
28. **API versioning is global prefix** — `/{apiVersion}{basePath}{path}`. Health/config unversioned.
29. **Mock responses are schema-defined** — per-endpoint `mockResponse` overrides generic mock when `MOCK_MODE=true`.
30. **Debug mode is runtime-only** — `DEBUG_MODE=true` activates filter. Always generated, inert when off.
31. **Health check is scheduled and in-memory** — configurable interval, no external storage.
32. **Search mode is per-endpoint** — `delegate` passes params; `local` filters client-side. List-only.
33. **Dark mode is always available** — CSS variables + localStorage + prefers-color-scheme fallback.
34. **Offline support uses stale-while-revalidate** — cache-first shell, SWR for API GETs, network-only non-GET.
35. **searchMode requires enableSearch** — `searchMode` on any endpoint throws if `flags.enableSearch` is not true. List-only check runs before value check.
36. **Transforms internals validated** — when `enableTransform: true`, rename map keys/values and remove list entries must be non-blank. Warning emitted when transforms present but flag off.
37. **Pagination param names non-blank** — `pageParam`, `sizeParam`, `sortParam`, `directionParam` validated when pagination object present.
38. **CLI overrides always re-validate** — `parser.validate(model)` called unconditionally after applying overrides, preventing invalid models from reaching the engine.
39. **FreeMarker Configuration cached per cartridge** — `Map<String, Configuration>` avoids redundant init on multi-cartridge runs.

---

## Runtime ENV VARs

| ENV VAR | Default | Feature | Scope |
|---|---|---|---|
| `RATE_LIMIT_PERMITS` | `10` | Rate Limiting | Per-instance |
| `RATE_LIMIT_PERIOD_SECONDS` | `1` | Rate Limiting | Per-instance |
| `RATE_LIMIT_TIMEOUT_MILLIS` | `5000` | Rate Limiting | Per-instance |
| `CACHE_REDIS_URL` | _(empty)_ | Distributed Cache | Per-instance |
| `DEBUG_MODE` | `false` | Debug Mode | Per-instance |
| `HEALTH_CHECK_INTERVAL_SECONDS` | `30` | Health Check | Per-instance |
| `HEALTH_CHECK_TIMEOUT_MS` | `3000` | Health Check | Per-instance |
| `SEARCH_PARAM` | `q` | Search & Filtering | Per-instance |

Legacy ENV VARs (see AGENTS.md for full list): `CB_*`, `CACHE_TTL_SECONDS`, `CACHE_MAX_SIZE`, `MOCK_MODE`, `BLOCK_TRAFFIC`, `AUTH_SERVER_URL`, `PAGINATION_*`, `CUSTOM_CSS_PATH`, `AUDIT_*`, `PROXY_*`.

---

## FreeMarker context variables

| Variable | Type | Default | Feature |
|---|---|---|---|
| `enableRateLimiter` | boolean | `false` | Rate Limiting |
| `enableTransform` | boolean | `false` | Transformation |
| `apiVersion` | String | `""` | API Versioning |
| `enableHealthCheck` | boolean | `false` | Health Check |
| `enableSearch` | boolean | `false` | Search & Filtering |
| `enableOfflineSupport` | boolean | `false` | Offline Support |
| `enableOpenApi` | boolean | `false` | OpenAPI |

Access pattern: `(flags.enableRateLimiter)!false`, `(flags.apiVersion)!""`.

Core variables (always available): `id`, `basePath`, `flags`, `endpoints`, `backendFlavor`, `feFlavor`, `deployTarget`.

---

## Model classes

```
BridgeSchemaModel.Flags:
  boolean enableTelemetry
  boolean enableAuditLog
  boolean enableCircuitBreaker
  boolean enableResponseCache
  boolean enableRateLimiter
  boolean enableTransform
  String  apiVersion            // null = no prefix
  boolean enableHealthCheck
  boolean enableSearch
  boolean enableOfflineSupport
  boolean enableOpenApi
  String  backendFlavor         // default "spring-boot"
  String  feFlavor
  String  securityLevel
  String  deployTarget
  Pagination pagination

BridgeSchemaModel.Endpoint:
  String       path
  String       method
  String       backendUrl
  String       telemetryName
  UiLayout     uiLayout
  Transforms   transforms
  MockResponse mockResponse

BridgeSchemaModel.UiLayout:
  String component    // "Form" | "List" | "View"
  List<Field> fields
  List<Column> columns
  String searchMode   // "delegate" | "local" | null

BridgeSchemaModel.Transforms:
  HeaderTransform requestHeaders
  HeaderTransform responseHeaders
  FieldTransform  requestFields
  FieldTransform  responseFields

BridgeSchemaModel.HeaderTransform:
  Map<String, String> add
  List<String>        remove
  Map<String, String> rename

BridgeSchemaModel.FieldTransform:
  Map<String, String> rename
  List<String>        remove

BridgeSchemaModel.MockResponse:
  int    statusCode = 200
  String body
  long   delayMs = 0

BridgeSchemaModel.Pagination:
  String pageParam        // default "page"
  String sizeParam        // default "size"
  int    defaultPageSize  // default 20
  String sortParam        // default "sort"
  String directionParam   // default "dir"
```

---

## Cartridge templates

| File | Cartridge | Purpose |
|---|---|---|
| `backend/spring-boot/**/*.ftl` | `backend/spring-boot` | Spring Boot 3.x REST proxy |
| `backend/quarkus/**/*.ftl` | `backend/quarkus` | Quarkus 3.x JAX-RS proxy |
| `frontend/react/**/*.ftl` | `frontend/react` | React 18 + Vite SPA |
| `frontend/angular/**/*.ftl` | `frontend/angular` | Angular 17 SPA |
| `frontend/vue/**/*.ftl` | `frontend/vue` | Vue 3 + Vite SPA |
| `frontend/ui-schema/**/*.ftl` | `frontend/ui-schema` | UiLayoutSchema.json |
| `devops/dockerfile/**/*.ftl` | `devops/dockerfile` | Multi-stage Dockerfile |
| `devops/docker-compose/**/*.ftl` | `devops/docker-compose` | docker-compose.yml |
| `devops/k8s/kubernetes/**/*.ftl` | `devops/k8s/kubernetes` | K8s Deployment + Service + ConfigMap |
| `devops/k8s/openshift/**/*.ftl` | `devops/k8s/openshift` | OpenShift Route |
| `docs/openapi/**/*.ftl` | `docs/openapi` | OpenAPI 3.0.3 spec |
