# ApiBridge — Handoff Notes

For architecture, schema reference, cartridge inventory, CLI usage, and E2E pipeline see **AGENTS.md** and **docs/schema-reference.md**.

---

## Generated backend endpoints

Every generated backend exposes these built-in endpoints regardless of schema:

| Endpoint | Purpose |
|---|---|
| `GET /api/bridge-config` | Returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath`, and all pagination config. Respects `PAGINATION_*` ENV VAR overrides at runtime. |
| `GET /custom.css` | Serves the mounted brand CSS file pointed to by `CUSTOM_CSS_PATH`. |
| `{method} {basePath}{path}` | Proxies each schema endpoint to its `backendUrl`. |

All error responses use `Content-Type: application/json`.

---

## Test status

```
mvn test → 137/137 PASS
```

| Test class | Count | Covers |
|---|---|---|
| `YamlParserTest` | 69 | All schema validation paths; PATCH method; case-normalized duplicate detection; blank column field; pagination boundaries (0 throws, 1 valid); telemetry loop past index 0; empty fields array; enableAuditLog; enableCircuitBreaker; enableResponseCache |
| `ApiBridgeCartridgeEngineTest` | 66 | All cartridge generations; List/View/Form; API method names; DevOps (Dockerfile Spring/Quarkus+FE static paths); k8s ConfigMap Spring vs Quarkus env vars, telemetry, audit log, circuit breaker, response cache; docker-compose audit on/off + Quarkus URIs + cache env vars; BridgeController bearer-token, apiKey, no-security branches; Spring/Quarkus pom CB+cache deps |
| `ApiBridgeRunnerTest` | 2 | CLI argument handling |

E2E suites (11 total): Spring Boot compile, Quarkus compile, Angular tsc, React tsc, Vue tsc, React prod build, contract symmetry, Kubernetes manifests, OpenShift manifests, fullstack Docker, json-server.

---

## Key design invariants

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
24. **Cache is in-process (Caffeine)** — no Redis required. Each replica warms independently. `CACHE_TTL_SECONDS` (default 60) + `CACHE_MAX_SIZE` (default 1000) ENV VARs control TTL and LRU eviction.
