# Phase 6 — Feature Expansion

> Status: **COMPLETE** — All 11 features done, 218/218 tests pass, BUILD SUCCESS.
> Created: 2026-05-28

---

## Summary

11 new features, all flag-gated, organized into 4 implementation tracks. Estimated **~75 new unit tests** (137 → ~212 total). No new infrastructure required beyond what is already provisioned.

---

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Transform granularity | Simple header/field mapping | Covers 90% of API gateway use cases; no JSONPath/JOLT dependency |
| API versioning scope | Global version prefix | Simple, covers most use cases; migration = change one flag |
| Search/filter detection | Explicit `searchMode` per endpoint | Predictable, testable, no magic auto-detect |
| Dark mode | Always available, no flag | Zero cost when not used (CSS variables only); localStorage persistence |
| Distributed cache | Runtime `CACHE_REDIS_URL` presence | Zero breaking change to existing Caffeine path |
| Debug mode | Runtime ENV VAR only, no build flag | No generated code difference; filter is always present but inert |

---

## Track 1: Backend Proxy Enhancements

### Feature 1: Rate Limiting

**Build-time flag:** `flags.enableRateLimiter` (boolean, default false)

**Runtime ENV VARs:**

| ENV VAR | Default | Purpose |
|---|---|---|
| `RATE_LIMIT_PERMITS` | `10` | Max requests per period |
| `RATE_LIMIT_PERIOD_SECONDS` | `1` | Time window in seconds |
| `RATE_LIMIT_TIMEOUT_MILLIS` | `5000` | Max wait for a permit before 429 |

**Behavior:**
- Wraps the proxy call in Resilience4j `RateLimiter.decorateSupplier()`
- Layer order: `RateLimiter → CircuitBreaker → Retry → HTTP call`
- Returns `429 {"error":"Too Many Requests","rateLimit":"exceeded"}` when limit exceeded
- Uses same Resilience4j 2.2.0 dependency as circuit breaker

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `boolean enableRateLimiter` to `Flags` |
| `YamlParser.java` | No new validation (boolean flag) |
| `ApiBridgeCartridgeEngine.java` | Add `enableRateLimiter` to context |
| `spring-boot/ProxyService.java.ftl` | Add `RateLimiter` field, init from ENV VARs, wrap `forward()` |
| `spring-boot/pom.xml.ftl` | Add `resilience4j-ratelimiter` dep (conditional) |
| `spring-boot/BridgeController.java.ftl` | Catch `RequestNotPermitted` → return 429 |
| `spring-boot/application.properties.ftl` | Document `RATE_LIMIT_*` ENV VARs |
| `quarkus/ProxyService.java.ftl` | Same RateLimiter pattern |
| `quarkus/pom.xml.ftl` | Add `resilience4j-ratelimiter` dep |
| `quarkus/BridgeResource.java.ftl` | Same 429 catch |
| `docker-compose.yml.ftl` | Add `RATE_LIMIT_*` ENV VAR block |
| `kubernetes/configmap.yaml.ftl` | Add `RATE_LIMIT_*` entries |

**Unit tests (6):**
1. YamlParser: `enableRateLimiter` parses correctly
2. YamlParser: default is false when absent
3. Engine: Spring Boot ProxyService contains RateLimiter init
4. Engine: Quarkus ProxyService contains RateLimiter init
5. Engine: Spring Boot pom includes resilience4j-ratelimiter
6. Engine: docker-compose includes RATE_LIMIT_* env vars

**Task breakdown:**
- [x] 1.1 Add `enableRateLimiter` to `Flags` + getter/setter + toString
- [x] 1.2 Add `enableRateLimiter` to FreeMarker context in `ApiBridgeCartridgeEngine`
- [x] 1.3 Update Spring Boot `ProxyService.java.ftl` — RateLimiter field + init + wrap
- [x] 1.4 Update Spring Boot `BridgeController.java.ftl` — catch RequestNotPermitted → 429
- [x] 1.5 Update Spring Boot `pom.xml.ftl` — conditional resilience4j-ratelimiter dep
- [x] 1.6 Update Spring Boot `application.properties.ftl` — RATE_LIMIT_* docs
- [x] 1.7 Update Quarkus `ProxyService.java.ftl` — same pattern
- [x] 1.8 Update Quarkus `BridgeResource.java.ftl` — same 429 catch
- [x] 1.9 Update Quarkus `pom.xml.ftl` — conditional dep
- [x] 1.10 Update `docker-compose.yml.ftl` — RATE_LIMIT_* env vars
- [x] 1.11 Update `configmap.yaml.ftl` — RATE_LIMIT_* entries
- [x] 1.12 Add 6 unit tests
- [x] 1.13 `mvn verify` passes

---

### Feature 2: Redis Distributed Cache (conditional)

**Build-time flag:** reuses `flags.enableResponseCache` (already exists)
**Runtime detection:** `CACHE_REDIS_URL` ENV VAR presence

**Behavior:**
- If `CACHE_REDIS_URL` is non-empty → use Redis as cache store
- If `CACHE_REDIS_URL` is empty/absent → use embedded Caffeine (current behavior)
- **Zero breaking change** — existing deployments work identically
- Common `ResponseCache` interface with `CaffeineResponseCache` and `RedisResponseCache` implementations

**Runtime ENV VARs:**

| ENV VAR | Default | Purpose |
|---|---|---|
| `CACHE_REDIS_URL` | _(empty → Caffeine)_ | Redis URL; non-empty switches to Redis cache |
| `CACHE_TTL_SECONDS` | `60` | TTL for cached GET responses |
| `CACHE_MAX_SIZE` | `1000` | Max entries (Caffeine only; Redis uses TTL) |

**Files to modify:**

| File | Change |
|---|---|
| `spring-boot/ProxyService.java.ftl` | Add `ResponseCache` interface + dual impl. Init path: if `CACHE_REDIS_URL` non-empty → Redis, else Caffeine |
| `spring-boot/pom.xml.ftl` | `spring-boot-starter-data-redis` dep when `enableResponseCache=true` (already conditional for audit; add OR condition) |
| `spring-boot/application.properties.ftl` | Document `CACHE_REDIS_URL` |
| `quarkus/ProxyService.java.ftl` | Same dual-path cache |
| `docker-compose.yml.ftl` | Add `CACHE_REDIS_URL` env var. Conditionally add `redis` service if not already present (audit may add it) |
| `kubernetes/configmap.yaml.ftl` | Add `CACHE_REDIS_URL` entry |

**Unit tests (8):**
1. Engine: Spring Boot ProxyService contains `ResponseCache` interface
2. Engine: Spring Boot ProxyService contains Caffeine path
3. Engine: Spring Boot ProxyService contains Redis path
4. Engine: Quarkus ProxyService contains dual cache path
5. Engine: Spring Boot pom has redis dep when cache enabled without audit
6. Engine: docker-compose has CACHE_REDIS_URL env var
7. Engine: docker-compose does NOT duplicate redis service when both audit and cache enabled
8. Engine: configmap has CACHE_REDIS_URL entry

**Task breakdown:**
- [x] 2.1 Refactor Spring Boot `ProxyService.java.ftl` — extract `ResponseCache` interface + dual impl
- [x] 2.2 Update Spring Boot `pom.xml.ftl` — add redis dep when `enableResponseCache` OR `enableAuditLog`
- [x] 2.3 Update Spring Boot `application.properties.ftl` — CACHE_REDIS_URL docs
- [x] 2.4 Refactor Quarkus `ProxyService.java.ftl` — same dual cache
- [x] 2.5 Update `docker-compose.yml.ftl` — CACHE_REDIS_URL + conditional redis service
- [x] 2.6 Update `configmap.yaml.ftl` — CACHE_REDIS_URL entry
- [x] 2.7 Add 8 unit tests
- [x] 2.8 `mvn verify` passes

---

### Feature 3: Request/Response Transformation

**Build-time flag:** `flags.enableTransform` (boolean, default false)

**Schema section:**

```yaml
endpoints:
  - path: "/orders"
    method: "GET"
    backendUrl: "https://upstream/api/orders"
    transforms:
      requestHeaders:
        add: { "X-Source": "apibridge" }
        remove: [ "X-Internal-Only" ]
        rename: { "X-Old-Name": "X-New-Name" }
      responseHeaders:
        add: { "X-Proxied-By": "apibridge" }
        remove: [ "Server" ]
      requestFields:
        rename: { "upstream_field": "our_field" }
        remove: [ "internal_id" ]
      responseFields:
        rename: { "upstream_name": "displayName" }
        remove: [ "secret_field" ]
```

**Behavior:**
- Header transforms applied in `ProxyService.forward()` before/after HTTP call
- Field transforms applied to JSON request/response body using Jackson `ObjectMapper`
- `rename` = change key names; `remove` = delete keys; `add` (headers only) = inject new headers
- If `enableTransform=false` and transforms are defined in schema → warning (not error)
- Transformation is a no-op if no transforms defined for an endpoint

**Model changes:**

```java
// New inner classes in BridgeSchemaModel
public static class Transforms {
    private HeaderTransform requestHeaders;
    private HeaderTransform responseHeaders;
    private FieldTransform requestFields;
    private FieldTransform responseFields;
}

public static class HeaderTransform {
    private Map<String, String> add;     // name → value
    private List<String> remove;
    private Map<String, String> rename;  // oldName → newName
}

public static class FieldTransform {
    private Map<String, String> rename;  // oldName → newName
    private List<String> remove;
}

// Added to Endpoint
private Transforms transforms;
```

**Validation:**
- `transforms` is optional on endpoints
- If `enableTransform=true` and an endpoint has transforms, all sub-fields are optional
- If `enableTransform=false` and transforms exist → log warning, ignore at runtime

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `Transforms`, `HeaderTransform`, `FieldTransform` inner classes; add `transforms` to `Endpoint` |
| `YamlParser.java` | Add validation: warn if transforms without flag |
| `ApiBridgeCartridgeEngine.java` | No context change needed (transforms accessed via `endpoint.transforms`) |
| `spring-boot/ProxyService.java.ftl` | Add `TransformService` inner class or method. Apply header transforms in `forward()`. Apply field transforms to JSON body |
| `spring-boot/pom.xml.ftl` | No new deps (Jackson already present via spring-boot-starter-web) |
| `quarkus/ProxyService.java.ftl` | Same transform logic |
| `application.properties.ftl` | Document transform behavior |

**Unit tests (10):**
1. YamlParser: parses transforms correctly
2. YamlParser: transforms without enableTransform → no error
3. Engine: Spring Boot ProxyService contains TransformService when flag on
4. Engine: Quarkus ProxyService contains TransformService when flag on
5. Engine: header add/remove/rename generated in Spring Boot
6. Engine: header add/remove/rename generated in Quarkus
7. Engine: field rename/remove generated in Spring Boot
8. Engine: field rename/remove generated in Quarkus
9. Engine: no transform code when flag is off
10. Engine: endpoint without transforms generates no transform call

**Task breakdown:**
- [x] 3.1 Add `Transforms`, `HeaderTransform`, `FieldTransform` to `BridgeSchemaModel`
- [x] 3.2 Add `transforms` field to `Endpoint` with getter/setter
- [x] 3.3 Add YamlParser validation for transforms
- [x] 3.4 Update Spring Boot `ProxyService.java.ftl` — TransformService + header/field transforms
- [x] 3.5 Update Quarkus `ProxyService.java.ftl` — same pattern
- [x] 3.6 Update `application.properties.ftl` — transform docs
- [x] 3.7 Add 10 unit tests
- [x] 3.8 `mvn verify` passes

---

### Feature 4: API Versioning

**Build-time flag:** `flags.apiVersion` (string, e.g. `"v1"`, default null = no prefix)

**Behavior:**
- When set, all proxy endpoints are prefixed: `/{apiVersion}{basePath}{path}` (e.g. `/v1/api/onboarding/submissions`)
- Health and config endpoints remain unversioned: `/api/bridge-config`, `/api/bridge-health`
- Frontend API client uses versioned base path
- `BridgeConfigController` response includes `apiVersion`

**Validation:**
- `apiVersion` must match pattern `v[0-9]+` if non-null (e.g. `v1`, `v2`, `v10`)
- Null/absent = no version prefix (current behavior, zero breaking change)

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `String apiVersion` to `Flags` |
| `YamlParser.java` | Validate `apiVersion` pattern |
| `ApiBridgeCartridgeEngine.java` | Add `apiVersion` to context |
| `spring-boot/BridgeController.java.ftl` | `@RequestMapping("/${apiVersion}${basePath}")` when set |
| `quarkus/BridgeResource.java.ftl` | Same path adjustment |
| `spring-boot/BridgeConfigController.java.ftl` | Add `apiVersion` to config response |
| `quarkus/BridgeConfigResource.java.ftl` | Add `apiVersion` to config response |
| `react/bridgeApi.ts.ftl` | Include version prefix in base URL |
| `angular/bridge-api.service.ts.ftl` | Include version prefix |
| `vue/bridgeApi.ts.ftl` | Include version prefix |
| `react/bridgeConfig.ts.ftl` | Add `apiVersion` to config interface |
| `angular/bridge-api-config.service.ts.ftl` | Add `apiVersion` |
| `vue/bridgeConfig.ts.ftl` | Add `apiVersion` |

**Unit tests (8):**
1. YamlParser: `apiVersion: "v1"` parses correctly
2. YamlParser: `apiVersion: "v2"` parses correctly
3. YamlParser: `apiVersion: "x1"` throws validation error
4. YamlParser: null apiVersion is valid (no prefix)
5. Engine: Spring Boot BridgeController has version prefix when set
6. Engine: Quarkus BridgeResource has version prefix when set
7. Engine: Frontend bridgeApi includes version prefix
8. Engine: BridgeConfig response includes apiVersion field

**Task breakdown:**
- [x] 4.1 Add `apiVersion` to `Flags` + getter/setter/toString
- [x] 4.2 Add `apiVersion` to FreeMarker context
- [x] 4.3 Add YamlParser validation — `v[0-9]+` pattern
- [x] 4.4 Update Spring Boot `BridgeController.java.ftl` — conditional version prefix
- [x] 4.5 Update Quarkus `BridgeResource.java.ftl` — conditional version prefix
- [x] 4.6 Update `BridgeConfigController.java.ftl` — add apiVersion to response
- [x] 4.7 Update Quarkus `BridgeConfigResource.java.ftl` — add apiVersion to response
- [x] 4.8 Update React `bridgeApi.ts.ftl` + `bridgeConfig.ts.ftl`
- [x] 4.9 Update Angular `bridge-api.service.ts.ftl` + `bridge-api-config.service.ts.ftl`
- [x] 4.10 Update Vue `bridgeApi.ts.ftl` + `bridgeConfig.ts.ftl`
- [x] 4.11 Add 8 unit tests
- [x] 4.12 `mvn verify` passes

---

### Feature 5: Enhanced Mock Mode

**Build-time:** generates mock infrastructure from schema. **Runtime:** `MOCK_MODE=true` activates.
**Schema section:** `endpoints[].mockResponse`

```yaml
endpoints:
  - path: "/submissions"
    method: "GET"
    backendUrl: "https://..."
    mockResponse:
      statusCode: 200
      body: '[{"id":1,"email":"test@example.com","companyName":"Acme","status":"pending"}]'
      delayMs: 200
```

**Behavior:**
- When `MOCK_MODE=true` and endpoint has `mockResponse`, return the defined `statusCode`, `body`, and simulate `delayMs` latency
- When `MOCK_MODE=true` but no `mockResponse` defined, fall back to current generic mock: `{"status":"mock","endpoint":"...","method":"..."}`
- `mockResponse.statusCode` defaults to 200 if omitted
- `mockResponse.delayMs` defaults to 0 if omitted

**Model changes:**

```java
public static class MockResponse {
    private int statusCode = 200;
    private String body;
    private long delayMs = 0;
}

// Added to Endpoint
private MockResponse mockResponse;
```

**Validation:**
- `statusCode` must be 100–599 if present
- `delayMs` must be >= 0 if present
- `mockResponse` is entirely optional

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `MockResponse` inner class; add `mockResponse` to `Endpoint` |
| `YamlParser.java` | Validate statusCode range and delayMs >= 0 |
| `spring-boot/BridgeController.java.ftl` | Replace generic mock with schema-defined mock when available |
| `quarkus/BridgeResource.java.ftl` | Same pattern |
| `spring-boot/BridgeConfigController.java.ftl` | No change (mock mode is runtime only) |

**Unit tests (6):**
1. YamlParser: parses mockResponse correctly
2. YamlParser: statusCode 99 throws error
3. YamlParser: statusCode 600 throws error
4. YamlParser: delayMs -1 throws error
5. Engine: Spring Boot BridgeController has schema-defined mock body
6. Engine: Quarkus BridgeResource has schema-defined mock body

**Task breakdown:**
- [x] 5.1 Add `MockResponse` inner class to `BridgeSchemaModel`
- [x] 5.2 Add `mockResponse` to `Endpoint` with getter/setter
- [x] 5.3 Add YamlParser validation for statusCode and delayMs
- [x] 5.4 Update Spring Boot `BridgeController.java.ftl` — schema-defined mock
- [x] 5.5 Update Quarkus `BridgeResource.java.ftl` — schema-defined mock
- [x] 5.6 Add 6 unit tests
- [x] 5.7 `mvn verify` passes

---

### Feature 6: Debug Mode

**Runtime flag only:** `DEBUG_MODE=true` ENV VAR. No build-time flag or model change.

**Behavior:**
- When active, logs full request details (method, path, headers, body preview) and response details (status, headers, body preview, duration)
- Structured JSON log entries at `DEBUG` level under `com.apibridge.generated`
- Body preview truncated to 1024 characters
- Authorization header values masked (`Bearer ***...`)
- Must be off in production (documented)

**Files to modify:**

| File | Change |
|---|---|
| `spring-boot/DebugLoggingFilter.java.ftl` | **New file** — `OncePerRequestFilter` with `@Value("${debug.mode:false}")` guard |
| `quarkus/DebugLoggingFilter.java.ftl` | **New file** — CDI filter with same guard |
| `spring-boot/application.properties.ftl` | Document `DEBUG_MODE` ENV VAR |
| `docker-compose.yml.ftl` | Add commented-out `DEBUG_MODE: "false"` |
| `configmap.yaml.ftl` | Add `DEBUG_MODE` entry |

**Unit tests (4):**
1. Engine: Spring Boot generates DebugLoggingFilter
2. Engine: Quarkus generates DebugLoggingFilter
3. Engine: docker-compose contains DEBUG_MODE env var
4. Engine: configmap contains DEBUG_MODE entry

**Task breakdown:**
- [x] 6.1 Create Spring Boot `DebugLoggingFilter.java.ftl`
- [x] 6.2 Create Quarkus `DebugLoggingFilter.java.ftl`
- [x] 6.3 Update `application.properties.ftl` — DEBUG_MODE docs
- [x] 6.4 Update `docker-compose.yml.ftl` — DEBUG_MODE env var
- [x] 6.5 Update `configmap.yaml.ftl` — DEBUG_MODE entry
- [x] 6.6 Add 4 unit tests
- [x] 6.7 `mvn verify` passes

---

## Track 2: Health & Observability

### Feature 7: Health Check Aggregation

**Build-time flag:** `flags.enableHealthCheck` (boolean, default false)

**New endpoint:** `GET /api/bridge-health`

**Response shape:**

```json
{
  "status": "UP",
  "endpoints": [
    {
      "path": "/submissions",
      "method": "GET",
      "backendUrl": "https://internal-mesh.local/customer/submissions",
      "status": "UP",
      "lastCheck": "2026-05-28T10:00:00Z",
      "latencyMs": 45
    }
  ]
}
```

**Aggregation logic:**
- `UP` — all endpoints UP
- `DEGRADED` — some endpoints DOWN
- `DOWN` — all endpoints DOWN or no endpoints checked yet

**Runtime ENV VARs:**

| ENV VAR | Default | Purpose |
|---|---|---|
| `HEALTH_CHECK_INTERVAL_SECONDS` | `30` | Probe interval |
| `HEALTH_CHECK_TIMEOUT_MS` | `3000` | Per-probe timeout |

**Behavior:**
- `@Scheduled` task probes each endpoint's `backendUrl` with HTTP HEAD (fallback to GET)
- Results stored in in-memory map
- Spring Boot: integrates with Actuator `HealthIndicator` for `/actuator/health`
- Quarkus: integrates with SmallRye Health for `/q/health`

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `boolean enableHealthCheck` to `Flags` |
| `ApiBridgeCartridgeEngine.java` | Add `enableHealthCheck` to context |
| `spring-boot/HealthCheckService.java.ftl` | **New file** — scheduled probe + in-memory map |
| `spring-boot/BridgeHealthController.java.ftl` | **New file** — `GET /api/bridge-health` endpoint |
| `quarkus/HealthCheckService.java.ftl` | **New file** — same logic |
| `quarkus/BridgeHealthResource.java.ftl` | **New file** — JAX-RS endpoint |
| `spring-boot/application.properties.ftl` | Document `HEALTH_CHECK_*` ENV VARs |
| `spring-boot/BridgeConfigController.java.ftl` | Add `enableHealthCheck` to config response |
| `quarkus/BridgeConfigResource.java.ftl` | Add `enableHealthCheck` to config response |
| `docker-compose.yml.ftl` | Add `HEALTH_CHECK_*` env vars |
| `configmap.yaml.ftl` | Add `HEALTH_CHECK_*` entries |

**Unit tests (8):**
1. YamlParser: `enableHealthCheck` parses correctly
2. Engine: Spring Boot generates HealthCheckService
3. Engine: Spring Boot generates BridgeHealthController
4. Engine: Quarkus generates HealthCheckService
5. Engine: Quarkus generates BridgeHealthResource
6. Engine: BridgeConfig response includes `enableHealthCheck`
7. Engine: docker-compose has HEALTH_CHECK_* env vars
8. Engine: configmap has HEALTH_CHECK_* entries

**Task breakdown:**
- [x] 7.1 Add `enableHealthCheck` to `Flags`
- [x] 7.2 Add `enableHealthCheck` to FreeMarker context
- [x] 7.3 Create Spring Boot `HealthCheckService.java.ftl`
- [x] 7.4 Create Spring Boot `BridgeHealthController.java.ftl`
- [x] 7.5 Create Quarkus `HealthCheckService.java.ftl`
- [x] 7.6 Create Quarkus `BridgeHealthResource.java.ftl`
- [x] 7.7 Update `BridgeConfigController.java.ftl` + Quarkus equiv — add enableHealthCheck
- [x] 7.8 Update `application.properties.ftl` — HEALTH_CHECK_* docs
- [x] 7.9 Update `docker-compose.yml.ftl` + `configmap.yaml.ftl` — env vars
- [x] 7.10 Add 8 unit tests
- [x] 7.11 `mvn verify` passes

---

## Track 3: Frontend Enhancements

### Feature 8: Search & Filtering

**Build-time flags:**
- `flags.enableSearch` (boolean, default false) — global on/off
- `endpoints[].uiLayout.searchMode` — `"delegate"` or `"local"` per List endpoint

**Delegate mode:**
- Search bar sends `?q=<term>` to upstream (proxy pass-through, no backend change)
- Filter pills send `?<field>=<value>` per column
- Search param name configurable via `SEARCH_PARAM` ENV VAR (default `"q"`)

**Local mode:**
- Proxy fetches all data (no pagination params)
- Frontend filters client-side: substring match across all visible columns
- Works with in-memory pagination

**Frontend changes (all 3 frameworks):**
- New `SearchBar` component in List page
- `FilterDropdown` per sortable column
- URL hash sync: `#/list?q=acme&status=active`

**Model changes:**
- Add `String searchMode` to `UiLayout`
- Add `boolean enableSearch` to `Flags`

**Validation:**
- `searchMode` must be `"delegate"` or `"local"` if present
- `searchMode` only valid on List endpoints (component = "List")

**Files to modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `searchMode` to `UiLayout`, `enableSearch` to `Flags` |
| `YamlParser.java` | Validate searchMode enum + List-only constraint |
| `ApiBridgeCartridgeEngine.java` | Add `enableSearch` to context |
| `react/ApiBridgeList.tsx.ftl` | Add SearchBar + FilterDropdown |
| `angular/bridge-list.component.ts/html.ftl` | Same components |
| `vue/ApiBridgeList.vue.ftl` | Same components |
| `react/bridgeConfig.ts.ftl` | Add `searchParam` to config |
| `angular/bridge-api-config.service.ts.ftl` | Add `searchParam` |
| `vue/bridgeConfig.ts.ftl` | Add `searchParam` |
| `BridgeConfigController.java.ftl` | Add `enableSearch` + `searchParam` to config |
| `BridgeConfigResource.java.ftl` | Same |
| `application.properties.ftl` | Document `SEARCH_PARAM` |
| `docker-compose.yml.ftl` | Add `SEARCH_PARAM` env var |
| `configmap.yaml.ftl` | Add `SEARCH_PARAM` entry |

**Unit tests (10):**
1. YamlParser: `searchMode: "delegate"` parses correctly
2. YamlParser: `searchMode: "local"` parses correctly
3. YamlParser: `searchMode: "invalid"` throws error
4. YamlParser: searchMode on non-List endpoint throws error
5. Engine: React List contains SearchBar when enableSearch=true
6. Engine: Angular List contains search when enableSearch=true
7. Engine: Vue List contains search when enableSearch=true
8. Engine: no search UI when enableSearch=false
9. Engine: BridgeConfig response includes enableSearch + searchParam
10. Engine: docker-compose has SEARCH_PARAM env var

**Task breakdown:**
- [x] 8.1 Add `searchMode` to `UiLayout` + `enableSearch` to `Flags`
- [x] 8.2 Add `enableSearch` to FreeMarker context
- [x] 8.3 Add YamlParser validation — searchMode enum + List-only
- [x] 8.4 Update React `ApiBridgeList.tsx.ftl` — SearchBar + URL hash sync
- [x] 8.5 Update Angular `bridge-list.component.ts/html.ftl` — same
- [x] 8.6 Update Vue `ApiBridgeList.vue.ftl` — same
- [x] 8.7 Update `bridgeConfig.ts.ftl` / service files — add searchParam (all 3 frameworks)
- [x] 8.8 Update `BridgeConfigController.java.ftl` + Quarkus equiv — enableSearch + searchParam
- [x] 8.9 Update `application.properties.ftl` + `docker-compose.yml.ftl` + `configmap.yaml.ftl`
- [x] 8.10 Add 10 unit tests (parser ×4 already in 197 baseline; 6 new engine tests added)
- [x] 8.11 `mvn verify` passes — 203/203

---

### Feature 9: Dark Mode / Theme Switcher

**No build-time flag** — always available when a frontend is generated.

**Behavior:**
- Dark theme defined via `[data-theme="dark"]` CSS selector block with inverted color palette
- Toggle button in topbar: moon/sun icon
- On click: `document.documentElement.setAttribute('data-theme', 'dark'|'light')`
- Persists to `localStorage.setItem('apib-theme', 'dark'|'light')`
- On load: read `localStorage`, fallback to `prefers-color-scheme: dark` media query
- Zero cost when not used — just CSS variables, no bundle increase

**Dark palette:**

```css
[data-theme="dark"] {
  --bg: #0f172a;
  --card: #1e293b;
  --card-border: #334155;
  --accent: #38bdf8;
  --accent-dim: rgba(56, 189, 248, 0.08);
  --text: #f1f5f9;
  --text-muted: #94a3b8;
  --input-bg: #1e293b;
  --input-border: #475569;
  --error: #f87171;
  --success: #4ade80;
}
```

**Files to modify:**

| File | Change |
|---|---|
| `react/index.css.ftl` | Add `[data-theme="dark"]` block |
| `angular/styles.css.ftl` | Add dark block |
| `vue/src/index.css` equivalent | Add dark block |
| `react/App.tsx.ftl` | Add theme toggle button + localStorage init |
| `angular/app.component.ts/html.ftl` | Same |
| `vue/App.vue.ftl` | Same |

**Unit tests (3):**
1. Engine: React CSS contains `[data-theme="dark"]`
2. Engine: Angular CSS contains `[data-theme="dark"]`
3. Engine: Vue CSS contains `[data-theme="dark"]`

**Task breakdown:**
- [x] 9.1 Update React `index.css.ftl` — dark theme CSS block
- [x] 9.2 Update React `App.tsx.ftl` — theme toggle + localStorage + prefers-color-scheme
- [x] 9.3 Update Angular `styles.css.ftl` — dark theme CSS block
- [x] 9.4 Update Angular `app.component.ts/html.ftl` — theme toggle
- [x] 9.5 Update Vue CSS — dark theme CSS block
- [x] 9.6 Update Vue `App.vue.ftl` — theme toggle
- [x] 9.7 Add 3 unit tests
- [x] 9.8 `mvn verify` passes

---

### Feature 10: Offline Support / Service Worker

**Build-time flag:** `flags.enableOfflineSupport` (boolean, default false)

**Behavior:**
- Generates `sw.js` Service Worker with:
  - App shell: cache-first strategy (HTML, JS, CSS, fonts)
  - API GET responses: stale-while-revalidate
  - Non-GET: network-only (no offline form submission)
- Shows offline banner when network unavailable
- Online status hook: `useOnlineStatus()` in React, equivalent in Angular/Vue

**Files to create/modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `boolean enableOfflineSupport` to `Flags` |
| `ApiBridgeCartridgeEngine.java` | Add `enableOfflineSupport` to context |
| `react/public/sw.js.ftl` | **New file** — Service Worker |
| `react/main.tsx.ftl` | Register SW + add offline banner |
| `react/App.tsx.ftl` | Add `useOnlineStatus()` hook |
| `angular/src/sw.js.ftl` | **New file** — Service Worker |
| `angular/main.ts.ftl` | Register SW |
| `angular/app.component.ts/html.ftl` | Offline banner |
| `vue/public/sw.js.ftl` | **New file** — Service Worker |
| `vue/main.ts.ftl` | Register SW |
| `vue/App.vue.ftl` | Offline banner |
| `react/index.html.ftl` | Add `<link rel="manifest">` if needed |
| `angular/index.html.ftl` | Same |
| `vue/index.html.ftl` | Same |

**Unit tests (6):**
1. Engine: React generates sw.js when flag on
2. Engine: Angular generates sw.js when flag on
3. Engine: Vue generates sw.js when flag on
4. Engine: no sw.js when flag off
5. Engine: React main.tsx registers SW when flag on
6. Engine: React App contains useOnlineStatus hook when flag on

**Task breakdown:**
- [x] 10.1 Add `enableOfflineSupport` to `Flags`
- [x] 10.2 Add `enableOfflineSupport` to FreeMarker context
- [x] 10.3 Create React `sw.js.ftl` + register in `main.tsx.ftl` + `useOnlineStatus` hook + offline banner
- [x] 10.4 Create Angular `sw.js.ftl` + register in `main.ts.ftl` + offline banner
- [x] 10.5 Create Vue `sw.js.ftl` + register in `main.ts.ftl` + offline banner
- [x] 10.6 Add 6 unit tests
- [x] 10.7 `mvn verify` passes

---

## Track 4: Documentation

### Feature 11: OpenAPI 3.0 Spec Generation

**Build-time flag:** `flags.enableOpenApi` (boolean, default false)
**New cartridge:** `apibridge-cartridges/docs/openapi`

**Behavior:**
- Generates `openapi.yaml` from the schema model
- `info.title` = `id`, `info.version` = `apiVersion` or `"1.0.0"`
- Each endpoint generates a path+operation with:
  - HTTP method, summary (from telemetryName or path)
  - Parameters: path params + pagination params
  - Request body schema (for Form endpoints, derived from fields)
  - Response schema (inferred from fields/columns)
  - Security scheme (from securityLevel)
- Spring Boot: serve `openapi.yaml` as static resource
- Quarkus: add `quarkus-smallrye-openapi` dep + annotations

**Files to create/modify:**

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `boolean enableOpenApi` to `Flags` |
| `YamlParser.java` | No new validation |
| `ApiBridgeCartridgeEngine.java` | Add `enableOpenApi` to context |
| `docs/openapi/openapi.yaml.ftl` | **New file** — OpenAPI 3.0.3 spec template |
| `spring-boot/pom.xml.ftl` | Add `springdoc-openapi` dep when flag on |
| `quarkus/pom.xml.ftl` | Add `quarkus-smallrye-openapi` dep when flag on |

**Unit tests (6):**
1. YamlParser: `enableOpenApi` parses correctly
2. Engine: openapi.yaml generated when flag on
3. Engine: openapi.yaml valid YAML structure
4. Engine: openapi.yaml contains all endpoints
5. Engine: Spring Boot pom has springdoc dep when flag on
6. Engine: Quarkus pom has smallrye dep when flag on

**Task breakdown:**
- [x] 11.1 Add `enableOpenApi` to `Flags`
- [x] 11.2 Add `enableOpenApi` to FreeMarker context
- [x] 11.3 Create `docs/openapi/` cartridge directory
- [x] 11.4 Create `openapi.yaml.ftl` template
- [x] 11.5 Update Spring Boot `pom.xml.ftl` — conditional springdoc dep
- [x] 11.6 Update Quarkus `pom.xml.ftl` — conditional smallrye dep
- [x] 11.7 Add 6 unit tests
- [x] 11.8 `mvn verify` passes

---

## Model Changes Summary

### `BridgeSchemaModel.java` — new fields

```
Flags:
  + boolean enableRateLimiter
  + boolean enableTransform
  + String  apiVersion            // null = no prefix
  + boolean enableHealthCheck
  + boolean enableSearch
  + boolean enableOfflineSupport
  + boolean enableOpenApi

Endpoint:
  + Transforms  transforms
  + MockResponse mockResponse

UiLayout:
  + String searchMode             // "delegate" | "local" | null
```

### New inner classes

```
Transforms:
  + HeaderTransform requestHeaders
  + HeaderTransform responseHeaders
  + FieldTransform  requestFields
  + FieldTransform  responseFields

HeaderTransform:
  + Map<String, String> add       // name → value
  + List<String>        remove
  + Map<String, String> rename    // old → new

FieldTransform:
  + Map<String, String> rename    // old → new
  + List<String>        remove

MockResponse:
  + int    statusCode = 200
  + String body
  + long   delayMs = 0
```

---

## Validation Changes Summary

| Rule | Feature |
|---|---|
| `apiVersion` matches `v[0-9]+` if non-null | API Versioning |
| `searchMode` must be `delegate` or `local` if present | Search & Filtering |
| `searchMode` only valid on List endpoints | Search & Filtering |
| `mockResponse.statusCode` must be 100–599 | Enhanced Mock |
| `mockResponse.delayMs` must be >= 0 | Enhanced Mock |
| `enableTransform=false` + transforms present → warning | Transformation |

---

## New FreeMarker Context Variables

| Variable | Type | Default | Feature |
|---|---|---|---|
| `enableRateLimiter` | boolean | `false` | Rate Limiting |
| `enableTransform` | boolean | `false` | Transformation |
| `apiVersion` | String | `""` | API Versioning |
| `enableHealthCheck` | boolean | `false` | Health Check |
| `enableSearch` | boolean | `false` | Search & Filtering |
| `enableOfflineSupport` | boolean | `false` | Offline Support |
| `enableOpenApi` | boolean | `false` | OpenAPI |

---

## New ENV VARs Summary

| ENV VAR | Default | Feature |
|---|---|---|
| `RATE_LIMIT_PERMITS` | `10` | Rate Limiting |
| `RATE_LIMIT_PERIOD_SECONDS` | `1` | Rate Limiting |
| `RATE_LIMIT_TIMEOUT_MILLIS` | `5000` | Rate Limiting |
| `CACHE_REDIS_URL` | _(empty)_ | Distributed Cache |
| `DEBUG_MODE` | `false` | Debug Mode |
| `HEALTH_CHECK_INTERVAL_SECONDS` | `30` | Health Check |
| `HEALTH_CHECK_TIMEOUT_MS` | `3000` | Health Check |
| `SEARCH_PARAM` | `q` | Search & Filtering |

---

## Estimated Test Summary

| Feature | New Tests |
|---|---|
| 1. Rate Limiting | 6 |
| 2. Redis Cache | 8 |
| 3. Transformation | 10 |
| 4. API Versioning | 8 |
| 5. Enhanced Mock | 6 |
| 6. Debug Mode | 4 |
| 7. Health Check | 8 |
| 8. Search & Filtering | 10 |
| 9. Dark Mode | 3 |
| 10. Offline Support | 6 |
| 11. OpenAPI | 6 |
| **Total** | **~75** |

Current: **137** → Phase 6 target: **~212**

---

## Execution Order

Phase 6 should be implemented in dependency order:

1. **Model + Validation batch** — add all new Flags/inner classes/validation at once
2. **Track 1 (Backend)** — Features 1–6 in order
3. **Track 2 (Health)** — Feature 7
4. **Track 3 (Frontend)** — Features 8–10
5. **Track 4 (Docs)** — Feature 11
6. **Final** — Update TODO.md, HANDOFF.md, README.md, schema-reference.md, sample-schema.yaml, CHANGELOG.md
