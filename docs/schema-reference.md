# ApiBridge Schema Reference

The ApiBridge schema is a YAML Platform-Independent Model (PIM) that drives all code generation. It is parsed and validated by `YamlParser` before being passed to cartridge templates.

---

## Top-level fields

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | Yes | Service identifier (kebab-case recommended, e.g. `user-auth-service`). Used to derive class names in generated code via PascalCase conversion. |
| `basePath` | string | Yes | REST base path (e.g. `/api/v1/auth`). Passed verbatim to templates. |
| `flags` | object | No | Optional feature flags. Defaults apply if omitted (see below). |
| `endpoints` | array | Yes | Non-empty list of REST endpoints. At least one required. |

---

## `flags`

| Field | Type | Default | Valid values | Description |
|---|---|---|---|---|
| `enableTelemetry` | boolean | `false` | `true` \| `false` | When `true`, all endpoints must have `telemetryName`. Conditionally injects OpenTelemetry instrumentation in backend templates. |
| `enableAuditLog` | boolean | `false` | `true` \| `false` | When `true`, generates a Redis Streams + MongoDB audit trail. Every proxy call emits `SEND`, `SUCCESS`, or `FAIL` events via Spring `ApplicationEventPublisher` / Quarkus CDI `fireAsync`. Events are published to a Redis Stream (`apibridge:audit`) and consumed by an in-process listener that writes/updates `AuditRecord` documents in MongoDB. Adds `redis` and `mongo` services to `docker-compose.yml`. Runtime overrides: `AUDIT_REDIS_URI`, `AUDIT_MONGO_URI`, `AUDIT_MONGO_DATABASE`, `AUDIT_LOG_TTL_DAYS` (default 30). |
| `enableCircuitBreaker` | boolean | `false` | `true` \| `false` | When `true`, wraps all proxy calls with a Resilience4j circuit breaker + retry. Circuit opens after `CB_FAILURE_RATE_THRESHOLD`% failures in a `CB_SLIDING_WINDOW_SIZE`-call window; stays open for `CB_WAIT_DURATION_SECONDS`s. Returns `503 {"error":"Service Unavailable","circuit":"open"}` when open. Retry fires before the CB counts a failure; up to `CB_RETRY_MAX_ATTEMPTS` attempts with `CB_RETRY_WAIT_MS`ms wait. No additional infrastructure required. |
| `enableResponseCache` | boolean | `false` | `true` \| `false` | When `true`, caches GET proxy responses. Uses embedded Caffeine by default; switches to Redis when `CACHE_REDIS_URL` is set at runtime. Cache key = full upstream URL + query string. TTL = `CACHE_TTL_SECONDS` (default 60s). Max entries = `CACHE_MAX_SIZE` (default 1000, LRU eviction). Non-GET requests call `invalidateAll()` for consistency. |
| `enableRateLimiter` | boolean | `false` | `true` \| `false` | When `true`, wraps all proxy calls with a Resilience4j rate limiter. Returns `429 {"error":"Too Many Requests","rateLimit":"exceeded"}` when exceeded. Layer order: `RateLimiter → CircuitBreaker → Retry → HTTP call`. Runtime overrides: `RATE_LIMIT_PERMITS` (default 10), `RATE_LIMIT_PERIOD_SECONDS` (default 1), `RATE_LIMIT_TIMEOUT_MILLIS` (default 5000). |
| `enableTransform` | boolean | `false` | `true` \| `false` | When `true`, enables per-endpoint request/response header and JSON field transformation. See `endpoints[].transforms` below. |
| `enableHealthCheck` | boolean | `false` | `true` \| `false` | When `true`, generates a scheduled health probe that checks each endpoint's `backendUrl` and exposes aggregated status at `GET /api/bridge-health`. Runtime overrides: `HEALTH_CHECK_INTERVAL_SECONDS` (default 30), `HEALTH_CHECK_TIMEOUT_MS` (default 3000). |
| `enableSearch` | boolean | `false` | `true` \| `false` | When `true`, adds search bar and column filter dropdowns to List pages. Per-endpoint behavior controlled by `uiLayout.searchMode`. Search param name configurable via `SEARCH_PARAM` ENV VAR (default `"q"`). |
| `enableOfflineSupport` | boolean | `false` | `true` \| `false` | When `true`, generates a Service Worker for the frontend SPA. Cache-first for app shell (HTML, JS, CSS, fonts); stale-while-revalidate for API GET responses; network-only for non-GET. Shows offline banner when network is unavailable. |
| `enableOpenApi` | boolean | `false` | `true` \| `false` | When `true`, generates an OpenAPI 3.0.3 specification from the schema. Use with the `docs/openapi` cartridge. Includes endpoint paths, parameters, request/response schemas, and security schemes. |
| `apiVersion` | string | — | Pattern `v[0-9]+` (e.g. `v1`, `v2`) | Global version prefix prepended to all proxy routes: `/{apiVersion}{basePath}{path}`. Health and config endpoints remain unversioned. Omit for no prefix. |
| `backendFlavor` | string | `spring-boot` | `spring-boot` \| `quarkus` | Selects backend framework for subdirectory-routed cartridges. |
| `feFlavor` | string | — | `angular` \| `react` \| `vue` | Selects frontend framework for subdirectory-routed cartridges. No default — absence means BE-only output. |
| `securityLevel` | string | — | `bearer-token` \| `apiKey` | Controls Authorization header injection in frontend templates. |
| `deployTarget` | string | — | `docker-compose` \| `kubernetes` \| `openshift` | When set, generates deployment configuration files alongside the project code. |
| `pagination` | object | — | — | Configures paging/sorting parameter names dynamically passed to backends. |

---

## `flags.pagination`

| Field | Type | Default | Description |
|---|---|---|---|
| `pageParam` | string | `page` | The URL query parameter name for the page index (overrideable in Docker via `PAGINATION_PAGE_PARAM`). |
| `sizeParam` | string | `size` | The URL query parameter name for the page size limit (overrideable in Docker via `PAGINATION_SIZE_PARAM`). |
| `defaultPageSize` | integer | `20` | The default number of items returned in a page (overrideable in Docker via `PAGINATION_DEFAULT_PAGE_SIZE`). |
| `sortParam` | string | `sort` | The URL query parameter name for the sort property field (overrideable in Docker via `PAGINATION_SORT_PARAM`). |
| `directionParam` | string | `dir` | The URL query parameter name for the sort direction (`asc`/`desc`) (overrideable in Docker via `PAGINATION_DIRECTION_PARAM`). |

---

## `endpoints[]`

Each item in the `endpoints` array:

| Field | Type | Required | Description |
|---|---|---|---|
| `path` | string | Yes | Endpoint path relative to `basePath` (e.g. `/login`). |
| `method` | string | Yes | HTTP method. Must be one of: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`. |
| `backendUrl` | string | Yes | Full URL of the upstream backend service. |
| `telemetryName` | string | Conditional | Required when `flags.enableTelemetry: true`. Used as the OTel span name. |
| `uiLayout` | object | No | Optional UI definition. If present, `component` is required. |
| `transforms` | object | No | Per-endpoint request/response transformation. Requires `flags.enableTransform: true`. |
| `mockResponse` | object | No | Per-endpoint mock response definition used when `MOCK_MODE=true`. |

Duplicate endpoints (same `path` + `method` combination) are rejected.

---

## `endpoints[].uiLayout`

| Field | Type | Required | Description |
|---|---|---|---|
| `component` | string | Yes (if `uiLayout` present) | Layout component type. Must be `Form`, `List`, or `View` (case-insensitive). |
| `fields` | array | No | List of form fields to render (applicable for `Form` and `View` components). |
| `columns` | array | No | Explicit listing of columns (applicable for `List` components). |
| `searchMode` | string | No | Search/filter strategy for `List` components. Must be `delegate` or `local`. Requires `flags.enableSearch: true`. `delegate` passes search params to upstream API; `local` fetches all data and filters client-side. |

---

## `endpoints[].uiLayout.fields[]`

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Field identifier (camelCase, e.g. `companyName`). |
| `label` | string | No | Display label for the field. Defaults to the field name when absent. |
| `type` | string | Conditional | Field type (`string`, `number`, `boolean`). Required for `Form` component; optional for `View` (display-only). |
| `required` | boolean | No | Whether the field is required. Defaults to `false`. Only meaningful for `Form` fields. |

---

## `endpoints[].uiLayout.columns[]`

| Field | Type | Required | Description |
|---|---|---|---|
| `field` | string | Yes | Field path to bind (e.g. `email`). |
| `label` | string | No | Display column header text. Defaults to the field name. |
| `sortable` | boolean | No | Enables sorting on this column. Defaults to `false`. |
| `width` | string | No | Width styling constraints (e.g. `200px`). |

---

## `endpoints[].transforms`

Requires `flags.enableTransform: true`. All sub-objects are optional — include only the transforms you need.

| Field | Type | Required | Description |
|---|---|---|---|
| `requestHeaders` | object | No | Transform headers before proxying to upstream. |
| `responseHeaders` | object | No | Transform headers before returning response to client. |
| `requestFields` | object | No | Transform JSON body keys before proxying to upstream. |
| `responseFields` | object | No | Transform JSON body keys before returning response to client. |

### Header transform object (`requestHeaders` / `responseHeaders`)

| Field | Type | Required | Description |
|---|---|---|---|
| `add` | map (string → string) | No | Inject new headers. Key = header name, value = header value. |
| `remove` | list of strings | No | Remove headers by name. |
| `rename` | map (string → string) | No | Rename headers. Key = old name, value = new name. |

Example:

```yaml
transforms:
  requestHeaders:
    add: { "X-Source": "apibridge" }
    remove: [ "X-Internal-Only" ]
    rename: { "X-Old-Name": "X-New-Name" }
  responseHeaders:
    add: { "X-Proxied-By": "apibridge" }
    remove: [ "Server" ]
```

### Field transform object (`requestFields` / `responseFields`)

| Field | Type | Required | Description |
|---|---|---|---|
| `rename` | map (string → string) | No | Rename JSON keys. Key = old field name, value = new field name. |
| `remove` | list of strings | No | Remove JSON keys by name. |

Example:

```yaml
transforms:
  responseFields:
    rename: { "upstream_name": "displayName" }
    remove: [ "secret_field" ]
```

---

## `endpoints[].mockResponse`

Per-endpoint mock definition used when `MOCK_MODE=true` at runtime. If no `mockResponse` is defined for an endpoint, the generic mock is used: `{"status":"mock","endpoint":"...","method":"..."}`.

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `statusCode` | integer | No | `200` | HTTP status code for the mock response. Must be 100–599. |
| `body` | string | No | — | Response body as a string (typically JSON). |
| `delayMs` | integer | No | `0` | Simulated latency in milliseconds. Must be >= 0. |

Example:

```yaml
mockResponse:
  statusCode: 200
  body: '[{"id":1,"email":"test@example.com","companyName":"Acme","status":"pending"}]'
  delayMs: 200
```

---

## Example (Phase 6 full)

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  enableTelemetry: true
  securityLevel: "bearer-token"
  backendFlavor: "spring-boot"
  feFlavor: "react"
  deployTarget: "docker-compose"
  enableCircuitBreaker: true
  enableResponseCache: true
  enableRateLimiter: true
  enableTransform: true
  enableHealthCheck: true
  enableSearch: true
  enableOfflineSupport: true
  enableOpenApi: true
  apiVersion: "v1"
  pagination:
    pageParam: "page"
    sizeParam: "size"
    defaultPageSize: 20
    sortParam: "sort"
    directionParam: "dir"
endpoints:
  - path: "/submissions"
    method: "GET"
    backendUrl: "https://internal-mesh.local/customer/submissions"
    telemetryName: "apibridge_onboarding_list"
    mockResponse:
      statusCode: 200
      body: '[{"id":1,"email":"test@example.com","companyName":"Acme","status":"pending"}]'
      delayMs: 200
    transforms:
      responseFields:
        rename: { "upstream_name": "displayName" }
        remove: [ "secret_field" ]
    uiLayout:
      component: "List"
      searchMode: "delegate"
      columns:
        - field: "email"
          label: "Email"
          sortable: true
        - field: "companyName"
          label: "Company"
          sortable: true
        - field: "status"
          label: "Status"
          sortable: false

  - path: "/submissions/{id}"
    method: "GET"
    backendUrl: "https://internal-mesh.local/customer/submissions/1"
    telemetryName: "apibridge_onboarding_view"
    uiLayout:
      component: "View"
      fields:
        - name: "email"
          label: "Email Address"
        - name: "companyName"
          label: "Company Name"
        - name: "status"
          label: "Status"

  - path: "/submissions/{id}"
    method: "PUT"
    backendUrl: "https://internal-mesh.local/customer/submissions/1"
    telemetryName: "apibridge_onboarding_update"
    transforms:
      requestHeaders:
        add: { "X-Source": "apibridge" }
      requestFields:
        rename: { "our_field": "upstream_field" }
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
        - name: "status"
          type: "string"
          label: "Status"
          required: false

  - path: "/submissions/{id}"
    method: "DELETE"
    backendUrl: "https://internal-mesh.local/customer/submissions/1"
    telemetryName: "apibridge_onboarding_delete"

  - path: "/initiate"
    method: "POST"
    backendUrl: "https://internal-mesh.local/customer/create"
    telemetryName: "apibridge_onboarding_initiate"
    transforms:
      requestHeaders:
        add: { "X-Source": "apibridge" }
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

---

## Validation summary

The engine (`YamlParser`) enforces these rules at parse time and throws `IllegalArgumentException` for any violation:

- `id` must be non-null and non-blank
- `basePath` must be non-null and non-blank
- `endpoints` must be non-null and non-empty
- `flags.backendFlavor` must be `spring-boot` or `quarkus` (if defined, case-insensitive)
- `flags.feFlavor` must be `angular`, `react`, or `vue` (if defined, case-insensitive)
- `flags.deployTarget` must be `docker-compose`, `kubernetes`, or `openshift` (if defined, case-insensitive)
- `flags.securityLevel` must be `bearer-token` or `apiKey` (if defined, case-insensitive)
- `flags.pagination.defaultPageSize` must be a positive integer (if pagination is defined)
- `flags.apiVersion` must match pattern `v[0-9]+` if defined (e.g. `v1`, `v2`, `v10`)
- Each endpoint must have non-blank `path`, `method`, and `backendUrl`
- Each endpoint `method` must be one of: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`
- Duplicate endpoints (same `path` + `method`) are rejected
- Each endpoint must have non-blank `telemetryName` when `flags.enableTelemetry` is `true`
- If `uiLayout` is present, `component` must be `Form`, `List`, or `View` (case-insensitive)
- Each field in `uiLayout.fields` must have non-blank `name` and `type` (type is mandatory for `Form` components)
- Each column in `uiLayout.columns` must have non-blank `field`
- `uiLayout.searchMode` must be `delegate` or `local` if defined; only valid on `List` components; requires `flags.enableSearch: true`
- `mockResponse.statusCode` must be 100–599 if defined
- `mockResponse.delayMs` must be >= 0 if defined
- `transforms` is ignored at runtime if `flags.enableTransform` is not `true` (warning logged, not an error)
