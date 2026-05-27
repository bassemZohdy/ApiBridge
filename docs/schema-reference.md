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
| `backendFlavor` | string | `spring-boot` | `spring-boot` \| `quarkus` | Selects backend framework for subdirectory-routed cartridges. |
| `feFlavor` | string | `react` | `angular` \| `react` \| `vue` | Selects frontend framework for subdirectory-routed cartridges. |
| `uiPattern` | string | `form-engine` | `form-engine` \| `web-component` | Selects frontend rendering pattern. |
| `securityLevel` | string | — | `bearer-token` \| `apiKey` | Controls Authorization header injection in frontend templates. |
| `deployTarget` | string | — | `docker-compose` \| `kubernetes` \| `openshift` | When set, generates deployment configuration files alongside the project code. |
| `navigationMode` | string | `spa` | `spa` \| `mpa` | Navigation architecture. `spa` enables client-side virtual routing; `mpa` separates them into page structures. |
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
| `method` | string | Yes | HTTP method (e.g. `POST`, `GET`). |
| `backendUrl` | string | Yes | Full URL of the upstream backend service. |
| `telemetryName` | string | Conditional | Required when `flags.enableTelemetry: true`. Used as the OTel span name. |
| `uiLayout` | object | No | Optional UI definition. If present, `component` is required. |

---

## `endpoints[].uiLayout`

| Field | Type | Required | Description |
|---|---|---|---|
| `component` | string | Yes (if `uiLayout` present) | Layout component type. Must be `Form`, `List`, or `View`. |
| `fields` | array | No | List of form fields to render (applicable for `Form` and `View` components). |
| `columns` | array | No | Explicit listing of columns (applicable for `List` components). |

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

## Example

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  enableTelemetry: true
  securityLevel: "bearer-token"
  backendFlavor: "spring-boot"
  feFlavor: "react"
  uiPattern: "form-engine"
  deployTarget: "docker-compose"
  navigationMode: "spa"
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
    uiLayout:
      component: "List"
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
          label: "Email Address"    # type is optional for View
        - name: "companyName"
          label: "Company Name"
        - name: "status"
          label: "Status"

  - path: "/initiate"
    method: "POST"
    backendUrl: "https://internal-mesh.local/customer/create"
    telemetryName: "apibridge_onboarding_initiate"
    uiLayout:
      component: "Form"
      fields:
        - name: "email"
          type: "string"            # type is required for Form
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
- `flags.uiPattern` must be `form-engine` or `web-component` (if defined, case-insensitive)
- `flags.deployTarget` must be `docker-compose`, `kubernetes`, or `openshift` (if defined, case-insensitive)
- `flags.securityLevel` must be `bearer-token` or `apiKey` (if defined, case-insensitive)
- `flags.navigationMode` must be `spa` or `mpa` (if defined, case-insensitive)
- `flags.pagination.defaultPageSize` must be a positive integer (if pagination is defined)
- Each endpoint must have non-blank `path`, `method`, and `backendUrl`
- Each endpoint must have non-blank `telemetryName` when `flags.enableTelemetry` is `true`
- If `uiLayout` is present, `component` must be `Form`, `List`, or `View`
- Each field in `uiLayout.fields` must have non-blank `name` and `type` (type is mandatory for `Form` components)
- Each column in `uiLayout.columns` must have non-blank `field`
