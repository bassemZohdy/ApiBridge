# ApiBridge — Handoff Notes

For architecture, schema reference, cartridge inventory, CLI usage, and E2E pipeline see **AGENTS.md** and **docs/schema-reference.md**.

For the Phase 6 implementation plan with task-level breakdown, see **[TODO.md](TODO.md)** and **[docs/superpowers/plans/2026-05-28-phase6-feature-expansion.md](docs/superpowers/plans/2026-05-28-phase6-feature-expansion.md)**.

---

## Generated backend endpoints

Every generated backend exposes these built-in endpoints regardless of schema:

| Endpoint | Purpose |
|---|---|
| `GET /api/bridge-config` | Returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath`, `enableHealthCheck`, `enableSearch`, `searchParam`, `apiVersion`, and all pagination config. Respects `PAGINATION_*` ENV VAR overrides at runtime. |
| `GET /custom.css` | Serves the mounted brand CSS file pointed to by `CUSTOM_CSS_PATH`. |
| `GET /api/bridge-health` | _(Phase 6, when `enableHealthCheck: true`)_ Returns aggregated upstream health status with per-endpoint latency and last check time. |
| `{method} {basePath}{path}` | Proxies each schema endpoint to its `backendUrl`. Prefixed with `/{apiVersion}` when `flags.apiVersion` is set. |

All error responses use `Content-Type: application/json`.

---

## Test status

### Current

```
mvn test → 206/206 PASS
```

| Test class | Count | Covers |
|---|---|---|
| `YamlParserTest` | 86 | All schema validation paths; PATCH method; case-normalized duplicate detection; blank column field; pagination boundaries (0 throws, 1 valid); telemetry loop past index 0; empty fields array; enableAuditLog; enableCircuitBreaker; enableResponseCache; enableRateLimiter; apiVersion (v1 valid, v2 valid, x1 invalid, null valid); searchMode (delegate valid, local valid, invalid throws, non-List throws); mockResponse (valid, statusCode 99, statusCode 600, delayMs -1); transforms; enableHealthCheck defaults false |
| `ApiBridgeCartridgeEngineTest` | 118 | All cartridge generations; List/View/Form; API method names; DevOps (Dockerfile Spring/Quarkus+FE static paths); k8s ConfigMap Spring vs Quarkus env vars, telemetry, audit log, circuit breaker, response cache, rate limiter, redis cache; docker-compose audit on/off + Quarkus URIs + cache env vars + redis service; BridgeController bearer-token, apiKey, no-security branches; Spring/Quarkus pom CB+cache+redis+rate-limiter deps; DebugLoggingFilter generation; transform methods + controller args + no-transform + null args; API versioning prefix; schema-defined mock body (Spring Boot + Quarkus); HealthCheckService + BridgeHealthController/Resource generation; enableHealthCheck in BridgeConfig; HEALTH_CHECK_* in docker-compose + configmap; React/Angular/Vue search bar generation; no search when disabled; BridgeConfig enableSearch+searchParam; SEARCH_PARAM in docker-compose; dark mode toggle in React/Angular/Vue App; [data-theme="dark"] CSS block; localStorage theme persistence |
| `ApiBridgeRunnerTest` | 2 | CLI argument handling |

E2E suites (11 total): Spring Boot compile, Quarkus compile, Angular tsc, React tsc, Vue tsc, React prod build, contract symmetry, Kubernetes manifests, OpenShift manifests, fullstack Docker, json-server.

### Phase 6 target

```
mvn test → ~212/212 PASS  (137 existing + ~75 new)
```

| Feature | New Tests | Status |
|---|---|---|
| F1: Rate Limiting | 8 | Done |
| F2: Redis Distributed Cache | 11 | Done |
| F3: Request/Response Transform | 10 | Done |
| F4: API Versioning | 8 | Done |
| F5: Enhanced Mock Mode | 6 | Done |
| F6: Debug Mode | 4 | Done |
| F7: Health Check Aggregation | 8 | Done |
| F8: Search & Filtering | 10 | Done |
| F9: Dark Mode / Theme | 3 | Done |
| F10: Offline Support / SW | 6 | Pending |
| F11: OpenAPI Spec | 6 | Pending |
| **Total** | **~75** | **36/75** |

---

## Key design invariants

### Existing invariants (must be preserved)

1. **No cross-cartridge dependencies** — each cartridge is self-contained.
2. **FreeMarker `${...}` in JSX/TS template literals** must be escaped as `${r"${...}"}`. Every `${...}` inside a backtick string must use this escape.
3. **Form templates filter GET endpoints** — `formEndpoints = endpoints.filter(ep -> method != "GET")` at template top.
4. **Custom CSS loads after the Vite bundle** — injected dynamically in `main.ts`/`main.tsx` so brand overrides win the cascade.
5. **`Pagination` is auto-initialized** — `getPagination()` is never null when flags are present.
6. **Method names are collision-free** — HTTP prefix + path segments + "By" suffix for path params (e.g. `getSubmissions`, `getSubmissionsById`, `postInitiate`).
7. **ProxyService forwards headers and query params** — all non-hop-by-hop request/response headers; query parameters appended to upstream URL.
8. **All 3 frontends export `getAuthHeaders()`** — React/Vue from `bridgeApi.ts`, Angular on `BridgeApiService`.
9. **View components support DELETE** — if a DELETE endpoint exists for the same path pattern, the View page renders a delete button.
10. **Form components support edit pre-population** — `editId` triggers a fetch from the View GET endpoint to fill form state.
11. **Bearer-token security via `AUTH_SERVER_URL`** — if set, backend validates JWT; if empty, pass-through with non-empty header check.
12. **Telemetry spans** — OpenTelemetry spans with `http.method`, `http.url`, `StatusCode.ERROR` on exceptions when `enableTelemetry: true`.
13. **CORS `exposedHeaders("*")` + `maxAge(3600)`** — upstream headers visible to frontend JS.
14. **All `flags` accesses null-safe** — `(flags.field)!default` pattern in all templates.
15. **Error responses are JSON** — both backends return `Content-Type: application/json` error bodies.
16. **Auth RestTemplate has timeouts** — 5s connect / 10s read.
17. **Proxy timeouts configurable** — `PROXY_CONNECT_TIMEOUT` / `PROXY_READ_TIMEOUT` env vars.
18. **Form field type mapping** — `email` → `<input type="email">` + pattern validation; `date`/`url`/`password` → native HTML types; Angular adds `Validators.email` for email fields.
19. **Audit log is fire-and-forget** — `ProxySendEvent`, `ProxySuccessEvent`, `ProxyFailEvent` are published via `@Async`/`fireAsync`. If Redis or MongoDB is down the proxy call still completes; unacknowledged stream entries are redelivered on restart.
20. **Audit Redis Stream** — key `apibridge:audit`, consumer group `apibridge-audit-group`. Three event types: `SEND` (insert PENDING record), `SUCCESS` (update to SUCCESS + response data), `FAIL` (update to FAILED + error). Correlation ID is a UUID generated per request.
21. **Audit MongoDB TTL** — `expiresAt` field indexed with `expireAfterSeconds=0`; value set to `now + AUDIT_LOG_TTL_DAYS * 86400s`. MongoDB handles log rotation automatically.
22. **Circuit breaker wraps retry** — retry fires first (up to `CB_RETRY_MAX_ATTEMPTS`); only after all attempts are exhausted does the failure count against the circuit breaker. `CallNotPermittedException` when open returns `{"error":"Service Unavailable","circuit":"open"}` with 503.
23. **Response cache is GET-only** — `Cache.getIfPresent(urlWithQuery)` before upstream call for GET; `invalidateAll()` on any non-GET request. Cache key = full upstream URL + query string.
24. **Cache is Caffeine by default** — in-process, no infrastructure required. Each replica warms independently. `CACHE_TTL_SECONDS` (default 60) + `CACHE_MAX_SIZE` (default 1000) ENV VARs control TTL and LRU eviction.

### Phase 6 invariants (new, must be maintained once implemented)

25. **Rate limiter wraps outside of circuit breaker** — layer order: `RateLimiter → CircuitBreaker → Retry → HTTP call`. Rate limiter returns 429; circuit breaker returns 503; retry is transparent.
26. **Distributed cache is runtime-determined** — `CACHE_REDIS_URL` presence selects Redis vs Caffeine at startup. No code change needed to switch; zero breaking change to existing deployments.
27. **Transforms are per-endpoint and optional** — if `enableTransform=true` but an endpoint has no `transforms`, the proxy call is unchanged. Header transforms applied before/after HTTP call; field transforms applied to JSON body only.
28. **API versioning is global prefix** — `apiVersion` prepends to `{basePath}`. No per-endpoint versioning. Health and config endpoints are unversioned.
29. **Mock responses are schema-defined** — `mockResponse.body` is a string (JSON). When `MOCK_MODE=true` and endpoint has mockResponse, use it; otherwise fall back to generic mock.
30. **Debug mode is runtime-only** — `DEBUG_MODE=true` activates logging filter. No build-time flag, no model change. Filter is always generated but inert when off.
31. **Health check is scheduled and in-memory** — probes run on a configurable interval; results stored in memory; no external storage.
32. **Search mode is per-endpoint** — `searchMode: "delegate"` passes params through; `"local"` fetches all and filters client-side. Only valid on List endpoints.
33. **Dark mode is always available** — no flag, always generated. CSS variables + localStorage + prefers-color-scheme fallback.
34. **Offline support uses stale-while-revalidate** — app shell is cache-first; API GETs are stale-while-revalidate; non-GET is network-only. No offline write queueing.

---

## Phase 6 — New ENV VARs

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

---

## Phase 6 — New FreeMarker context variables

| Variable | Type | Default | Feature |
|---|---|---|---|
| `enableRateLimiter` | boolean | `false` | Rate Limiting |
| `enableTransform` | boolean | `false` | Transformation |
| `apiVersion` | String | `""` | API Versioning |
| `enableHealthCheck` | boolean | `false` | Health Check |
| `enableSearch` | boolean | `false` | Search & Filtering |
| `enableOfflineSupport` | boolean | `false` | Offline Support |
| `enableOpenApi` | boolean | `false` | OpenAPI |

Access pattern in templates: `(flags.enableRateLimiter)!false`, `(flags.apiVersion)!""`.

---

## Phase 6 — New model classes

```
BridgeSchemaModel.Flags:
  + boolean enableRateLimiter
  + boolean enableTransform
  + String  apiVersion
  + boolean enableHealthCheck
  + boolean enableSearch
  + boolean enableOfflineSupport
  + boolean enableOpenApi

BridgeSchemaModel.Endpoint:
  + Transforms  transforms
  + MockResponse mockResponse

BridgeSchemaModel.UiLayout:
  + String searchMode    // "delegate" | "local" | null

BridgeSchemaModel.Transforms (new):
  + HeaderTransform requestHeaders
  + HeaderTransform responseHeaders
  + FieldTransform  requestFields
  + FieldTransform  responseFields

BridgeSchemaModel.HeaderTransform (new):
  + Map<String, String> add
  + List<String>        remove
  + Map<String, String> rename

BridgeSchemaModel.FieldTransform (new):
  + Map<String, String> rename
  + List<String>        remove

BridgeSchemaModel.MockResponse (new):
  + int    statusCode = 200
  + String body
  + long   delayMs = 0
```

---

## Phase 6 — New cartridge templates

| File | Cartridge | Feature |
|---|---|---|
| `docs/openapi/openapi.yaml.ftl` | `docs/openapi` | OpenAPI 3.0.3 spec |
| `backend/spring-boot/.../DebugLoggingFilter.java.ftl` | `backend/spring-boot` | Debug logging filter |
| `backend/spring-boot/.../HealthCheckService.java.ftl` | `backend/spring-boot` | Health probing |
| `backend/spring-boot/.../BridgeHealthController.java.ftl` | `backend/spring-boot` | Health endpoint |
| `backend/quarkus/.../DebugLoggingFilter.java.ftl` | `backend/quarkus` | Debug logging filter |
| `backend/quarkus/.../HealthCheckService.java.ftl` | `backend/quarkus` | Health probing |
| `backend/quarkus/.../BridgeHealthResource.java.ftl` | `backend/quarkus` | Health endpoint |
| `frontend/react/public/sw.js.ftl` | `frontend/react` | Service Worker |
| `frontend/angular/src/sw.js.ftl` | `frontend/angular` | Service Worker |
| `frontend/vue/public/sw.js.ftl` | `frontend/vue` | Service Worker |
