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
| `backendFlavor` | string | `spring-boot` | `spring-boot` \| `quarkus` | Selects backend framework for subdirectory-routed cartridges (validated, case-insensitive). |
| `feFlavor` | string | `react` | `angular` \| `react` \| `vue` | Selects frontend framework for subdirectory-routed cartridges (validated, case-insensitive). |
| `uiPattern` | string | `form-engine` | `form-engine` \| `web-component` | Selects frontend rendering pattern (validated, case-insensitive). |
| `securityLevel` | string | — | `bearer-token` \| `apiKey` | Controls Authorization header injection in frontend templates. Validated by the engine when present (case-insensitive). |
| `deployTarget` | string | — | `docker-compose` \| `kubernetes` \| `openshift` | When set, generates deployment configuration files alongside the project code. Omit (or leave `flags` absent) to produce code + Dockerfile only. |

> Note: `flags` defaults (`backendFlavor: spring-boot`, `feFlavor: react`, `uiPattern: form-engine`) apply when the `flags` key is present but the sub-field is absent. If `flags` itself is omitted, no flag validation runs. CLI overrides (`--be-flavor`, `--fe-flavor`, `--deploy-target`) take precedence over schema flags.

---

## `endpoints[]`

Each item in the `endpoints` array:

| Field | Type | Required | Description |
|---|---|---|---|
| `path` | string | Yes | Endpoint path relative to `basePath` (e.g. `/login`). |
| `method` | string | Yes | HTTP method (e.g. `POST`, `GET`). |
| `backendUrl` | string | Yes | Full URL of the upstream backend service. |
| `telemetryName` | string | Conditional | Required when `flags.enableTelemetry: true`. Used as the OTel span name. |
| `uiLayout` | object | No | Optional UI form definition. If present, `component` is required. |

---

## `endpoints[].uiLayout`

| Field | Type | Required | Description |
|---|---|---|---|
| `component` | string | Yes (if `uiLayout` present) | Layout component type (e.g. `Form`). |
| `fields` | array | No | List of form fields to render. |

---

## `endpoints[].uiLayout.fields[]`

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Field identifier (camelCase, e.g. `companyName`). |
| `type` | string | Yes | Field type (e.g. `string`, `number`, `boolean`). |
| `required` | boolean | No | Whether the field is required. Defaults to `false`. |

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
endpoints:
  - path: "/initiate"
    method: "POST"
    backendUrl: "https://internal-mesh.local/customer/create"
    telemetryName: "apibridge_onboarding_initiate"
    uiLayout:
      component: "Form"
      fields:
        - name: "email"
          type: "string"
          required: true
        - name: "companyName"
          type: "string"
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
- Each endpoint must have non-blank `path`, `method`, and `backendUrl`
- Each endpoint must have non-blank `telemetryName` when `flags.enableTelemetry` is `true`
- If `uiLayout` is present, `component` must be non-blank
- Each field in `uiLayout.fields` must have non-blank `name` and `type`
