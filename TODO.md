# ApiBridge — Backlog

Items are grouped by theme. Each entry describes the gap, its root cause, and the concrete work needed.

---

## Known Gaps

### GAP-6 · Standalone backend cartridges are not self-contained

**Cartridges affected:** `apibridge-cartridges/backend-spring-boot/`, `apibridge-cartridges/backend-quarkus/`

**Root cause:** Both standalone backend cartridges were created as thin controller-only stubs that assume a phantom runtime library (`com.apibridge:apibridge-enterprise-core:1.0.0`) which does not exist in any public Maven repository. They cannot produce a compilable project.

**Specific problems:**

1. `Controller.java.ftl` and `Resource.java.ftl` both `import com.apibridge.core.IntegrationProxy` — a class that does not exist; the generated project will fail `mvn compile`.
2. `backend-spring-boot/pom.xml.ftl` declares `<artifactId>apibridge-enterprise-core</artifactId>` with no repository; Maven will fail to resolve it.
3. Neither standalone cartridge has an `Application.java`, `ProxyService.java`, or `application.properties` — the three files that the `fullstack/backend-*` sub-cartridges provide.
4. The controller method name is derived from `endpoint.telemetryName` (e.g., `handleApibridgeOnboardingInitiate`) but `telemetryName` is only required when `enableTelemetry=true`. When `enableTelemetry=false`, `telemetryName` is null and FreeMarker will throw at render time.
5. Path parameter support (gap #5) was applied only to fullstack templates; the standalone controllers still have no `@PathVariable` / `@PathParam` support.

**Work needed:**

- [ ] Remove the phantom `apibridge-enterprise-core` dependency from both standalone `pom.xml.ftl` files.
- [ ] Add `ProxyService.java.ftl` to each standalone cartridge, mirroring the implementation in `fullstack/backend-spring-boot/` and `fullstack/backend-quarkus/`.
- [ ] Add `Application.java.ftl` to `backend-spring-boot/` (Spring Boot entry point).
- [ ] Add `application.properties.ftl` to both standalone cartridges (minimal version: port, shutdown, actuator health, structured logging).
- [ ] Fix `telemetryName` null guard: replace the unconditional `endpoint.telemetryName` in method name derivation with `(endpoint.telemetryName!"unknown")?replace(...)` or generate a method name from `endpoint.path` instead.
- [ ] Apply path parameter support (`@PathVariable` / `@PathParam` + URL `.replace()`) to standalone controller templates, matching the fullstack approach.
- [ ] Add a compilation smoke-test for both standalone cartridges in the E2E suite.

---

### GAP-7 · No `--version` CLI flag

**File:** `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeRunner.java`

**Root cause:** `ApiBridgeRunner` parses `--schema`, `--cartridge`, `--output`, `--be-flavor`, `--fe-flavor`, and `--deploy-target` but has no handler for `--version` or `-v`. Running the JAR with `--version` currently falls through to the "missing required args" error path.

**Work needed:**

- [ ] Read the artifact version from the JAR manifest (`Implementation-Version` entry, written by `maven-jar-plugin`). Configure `pom.xml` to write it: add `<addDefaultImplementationEntries>true</addDefaultImplementationEntries>` to `maven-jar-plugin` configuration.
- [ ] In `ApiBridgeRunner.main()`, detect `--version` or `-v` as the sole argument, print `ApiBridge Generator <version>` to stdout, and `System.exit(0)`.
- [ ] Add a unit test: invoke `main(new String[]{"--version"})` and assert exit code 0 + output contains a non-empty version string.

---

## Feature: Cloud-Native Externalized Configuration

Generated apps must follow the Twelve-Factor App principle ([Factor III – Config](https://12factor.net/config)): **everything that varies between deployments (URLs, credentials, feature flags, tuning) must come from environment variables, not from baked-in code or config files.**

### Current state

| What | Current behaviour | Problem |
|------|-------------------|---------|
| Upstream backend URLs | Hardcoded in `proxyService.forward("${endpoint.backendUrl}", ...)` at generation time | Cannot redirect traffic to a different backend without regenerating |
| `MOCK_MODE` / `BLOCK_TRAFFIC` | Already ENV-driven via `@Value` / `@ConfigProperty` | Good — already done |
| `SERVER_PORT` / `QUARKUS_HTTP_PORT` | `application.properties` hardcodes `server.port=8080` | Spring reads `SERVER_PORT` automatically; Quarkus reads `QUARKUS_HTTP_PORT`; not documented anywhere in generated output |
| Log level | Not configurable at all | Must rebuild to change log verbosity |
| CORS allowed origins | Hardcoded (none configured — framework defaults apply) | Cannot restrict/widen origins per deployment without code change |
| API key / bearer token (backend validation) | `apiKey` mode reads `process.env.API_KEY` on the **frontend** only; no backend-side credential env var | Key leaks to browser; backend does not validate it from env |
| Frontend API base URL | Hardcoded relative path `'${basePath}${endpoint.path}'` | Works when FE is co-hosted in the same container; breaks when FE is deployed separately (CDN, separate Nginx) |
| Dockerfile `ENV` block | Only declares `MOCK_MODE`, `BLOCK_TRAFFIC`, `JAVA_OPTS` | All other supported env vars are invisible to operators |
| docker-compose `environment:` | Only lists `MOCK_MODE`, `BLOCK_TRAFFIC` | Incomplete |
| k8s ConfigMap | Only lists `MOCK_MODE`, `BLOCK_TRAFFIC` | Incomplete |

---

### CLOUD-1 · Backend URL overrides via ENV VARs

**Goal:** Every upstream `backendUrl` baked in at generation time must be overridable at runtime through a named ENV VAR.

**Naming convention:** `BACKEND_URL_<SEGMENT>` where `<SEGMENT>` is the endpoint path uppercased and non-alphanumeric chars replaced with `_` (e.g., `/create` → `BACKEND_URL_CREATE`, `/users/{id}` → `BACKEND_URL_USERS_ID`).

**Files to change:**

- [ ] `fullstack/backend-spring-boot/.../BridgeController.java.ftl` — generate a `@Value("${BACKEND_URL_X:https://original-url}")` field per endpoint; use the field in `proxyService.forward()` instead of the hardcoded string literal.
- [ ] `fullstack/backend-quarkus/.../BridgeResource.java.ftl` — generate a `@ConfigProperty(name = "BACKEND_URL_X", defaultValue = "https://original-url")` field per endpoint.
- [ ] `fullstack/docker-compose.yml.ftl` — add commented `BACKEND_URL_X: "https://..."` lines per endpoint under `environment:`.
- [ ] `fullstack/k8s/configmap.yaml.ftl` — add `BACKEND_URL_X: "https://..."` data entries per endpoint.
- [ ] `fullstack/Dockerfile.ftl` — add `BACKEND_URL_X` entries to the `ENV` block with the original URL as the default.
- [ ] Apply the same changes to the standalone `backend-spring-boot/` and `backend-quarkus/` cartridges once GAP-6 is resolved.

**FreeMarker helper needed** (reuse across templates):
```freemarker
<#function pathToEnvKey path>
  <#local s = path?replace("[{][^}]*[}]", "", "r")?replace("[^A-Za-z0-9]", "_", "r")?upper_case />
  <#local s = s?replace("_+", "_", "r")?remove_beginning("_")?remove_ending("_") />
  <#return s />
</#function>
```

---

### CLOUD-2 · Expand ENV VAR surface in generated config files

**Goal:** Every ENV VAR that the generated application reads must appear in the generated `application.properties`, Dockerfile, docker-compose, and k8s ConfigMap — with its default and a one-line comment.

**Spring Boot `application.properties.ftl` additions:**

```properties
# ─── Runtime overrides ────────────────────────────────────────────────────────
# MOCK_MODE / BLOCK_TRAFFIC are already read by BridgeController via @Value.
# The following are read directly by Spring Boot from the environment:
#   SERVER_PORT          — override the listening port (default: 8080)
#   LOGGING_LEVEL_ROOT   — root log level: ERROR | WARN | INFO | DEBUG (default: INFO)
#   LOGGING_LEVEL_COM_APIBRIDGE — package-level log level
```

- [ ] `fullstack/backend-spring-boot/src/main/resources/application.properties.ftl` — add ENV VAR reference block with comments for `SERVER_PORT`, `LOGGING_LEVEL_ROOT`, `LOGGING_LEVEL_COM_APIBRIDGE`, `MANAGEMENT_SERVER_PORT`, and per-endpoint `BACKEND_URL_X` entries (added in CLOUD-1).

**Quarkus `application.properties.ftl` additions:**

```properties
# QUARKUS_HTTP_PORT       — override the listening port (default: 8080)
# QUARKUS_LOG_LEVEL       — root log level (default: INFO)
# QUARKUS_LOG_CATEGORY__COM_APIBRIDGE__LEVEL — package-level log level
```

- [ ] `fullstack/backend-quarkus/src/main/resources/application.properties.ftl` — same treatment.

**Dockerfile `ENV` block:**

- [ ] `fullstack/Dockerfile.ftl` — expand the `ENV` declaration to include all ENV VARs with defaults:
  ```dockerfile
  ENV MOCK_MODE=false \
      BLOCK_TRAFFIC=false \
      JAVA_OPTS="" \
      SERVER_PORT=8080 \
      LOGGING_LEVEL_ROOT=INFO \
  <#list endpoints as endpoint>
      BACKEND_URL_${pathToEnvKey(endpoint.path)}="${endpoint.backendUrl}" \
  </#list>
  ```
  (Quarkus variant uses `QUARKUS_HTTP_PORT` and `QUARKUS_LOG_LEVEL`.)

**docker-compose `environment:` block:**

- [ ] `fullstack/docker-compose.yml.ftl` — add all ENV VARs with their defaults and inline comments explaining each.

**k8s ConfigMap:**

- [ ] `fullstack/k8s/configmap.yaml.ftl` — add all ENV VARs with their defaults and inline comments.

---

### CLOUD-3 · Backend-side credential validation from ENV VAR

**Goal:** When `flags.securityLevel` is `apiKey`, the backend should read the expected key from an ENV VAR (`API_KEY`) and validate incoming requests against it rather than forwarding blindly.

**Current state:** `apiKey` mode only injects `X-API-Key` on the frontend (`process.env.API_KEY` / `import.meta.env.VITE_API_KEY`); the backend does nothing with it.

**Files to change:**

- [ ] `fullstack/backend-spring-boot/.../BridgeController.java.ftl` — when `securityLevel == "apiKey"`: inject `@Value("${API_KEY:}") private String expectedApiKey;`; add a check at the top of each handler that reads the `X-API-Key` request header and returns `401` if it doesn't match `expectedApiKey`.
- [ ] `fullstack/backend-quarkus/.../BridgeResource.java.ftl` — same via `@ConfigProperty(name = "API_KEY", defaultValue = "")` and `@HeaderParam("X-API-Key")`.
- [ ] `fullstack/Dockerfile.ftl` — add `API_KEY=""` to the ENV block (with a comment that an empty value disables validation).
- [ ] `fullstack/docker-compose.yml.ftl` and `fullstack/k8s/configmap.yaml.ftl` — add `API_KEY` entry.
- [ ] Frontend `bridgeApi.ts.ftl` (React, Vue) — switch from `process.env.API_KEY` to `import.meta.env.VITE_API_KEY` (Vite projects). Add `VITE_API_KEY` to `Dockerfile` frontend build arg.
- [ ] Angular equivalent: use `environment.ts` injection (already uses Angular's build system, not Vite).

---

### CLOUD-4 · Frontend API base URL from ENV VAR

**Goal:** The frontend API base URL (`${basePath}`) should be overridable at build time via an env var so the same frontend artifact can point to different backends (useful when FE is deployed to a CDN separately from the backend container).

**Note:** In the standard fullstack container, FE is embedded in the backend and served from the same origin, so relative URLs (`/api/v1/...`) work without this. This task only matters for split-deploy scenarios.

**Files to change:**

- [ ] `fullstack/frontend-react/src/api/bridgeApi.ts.ftl` — replace the literal `'${basePath}${endpoint.path}'` with `` `${r"${import.meta.env.VITE_API_BASE_URL ?? ''}"}${basePath}${endpoint.path}` ``.
- [ ] `fullstack/frontend-vue/src/api/bridgeApi.ts.ftl` — same.
- [ ] `fullstack/frontend-angular/src/app/bridge-api.service.ts.ftl` — inject a config token or read from `environment.ts`; generate `environment.ts.ftl` with `apiBaseUrl: ''` and `environment.prod.ts.ftl` with the override hook.
- [ ] `fullstack/Dockerfile.ftl` — add `ARG VITE_API_BASE_URL=""` before the frontend build stage; pass `--build-arg VITE_API_BASE_URL=$VITE_API_BASE_URL` in the `npm run build` step.
- [ ] `fullstack/docker-compose.yml.ftl` — add `build.args.VITE_API_BASE_URL` entry with a comment.

---

### CLOUD-5 · CORS origins from ENV VAR

**Goal:** Allowed CORS origins must be configurable without code change. In development, `*` is fine; in production, the list of allowed origins must be explicit.

**Files to change:**

- [ ] `fullstack/backend-spring-boot/.../BridgeController.java.ftl` (or a new `CorsConfig.java.ftl`) — generate a `WebMvcConfigurer` that reads `CORS_ALLOWED_ORIGINS` env var (comma-separated); defaults to `*`.
- [ ] `fullstack/backend-quarkus/src/main/resources/application.properties.ftl` — add `quarkus.http.cors=true` and `quarkus.http.cors.origins=${r"${CORS_ALLOWED_ORIGINS:*}"}`.
- [ ] `fullstack/Dockerfile.ftl` — add `CORS_ALLOWED_ORIGINS=*` to `ENV` block.
- [ ] `fullstack/docker-compose.yml.ftl` and `fullstack/k8s/configmap.yaml.ftl` — add `CORS_ALLOWED_ORIGINS` entry.

---

## Prioritisation

```
GAP-6   — standalone cartridges broken (correctness)
GAP-7   — missing --version flag (usability, trivial)
CLOUD-1 — backend URL env var overrides (highest-value cloud-native task)
CLOUD-2 — expand ENV VAR surface in generated config files
CLOUD-3 — backend-side API key validation
CLOUD-4 — frontend base URL from env var (split-deploy only)
CLOUD-5 — CORS origins from env var
```
