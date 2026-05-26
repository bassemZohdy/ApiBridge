# ApiBridge — Backlog

Items are grouped by theme. Each entry describes the gap, its root cause, and the concrete work needed.

---

## Known Gaps

### GAP-6 · Standalone backend cartridges are not self-contained — DONE

Completed: both standalone cartridges (`backend-spring-boot/`, `backend-quarkus/`) fully rewritten with proper directory structure, `ProxyService.java.ftl`, `Application.java.ftl`, `application.properties.ftl`, path param support, OTel support, and all cloud-native ENV VAR overrides (CLOUD-1 through CLOUD-5) applied.

---

### GAP-7 · No `--version` CLI flag — DONE

Completed: `ApiBridgeRunner` now handles `--version` / `-v`; version read from JAR manifest `Implementation-Version`; pom.xml writes manifest entry; 2 unit tests added.

---

## Feature: Cloud-Native Externalized Configuration — DONE

All CLOUD-1 through CLOUD-5 tasks completed. Generated apps fully follow Twelve-Factor App Factor III.

### CLOUD-1 · Backend URL overrides via ENV VARs — DONE

- `pathToEnvKey` FreeMarker function defined in all backend templates; regex fixed to `[{}]` to preserve path param names and avoid key collisions (e.g. `/orders/{orderId}` → `ORDERS_ORDERID` vs `/orders` → `ORDERS`).
- `@Value` (Spring Boot) and `@ConfigProperty` (Quarkus) per-endpoint URL fields in all four backend templates (fullstack + standalone).
- `BACKEND_URL_X` entries added to Dockerfile, docker-compose, k8s ConfigMap.

### CLOUD-2 · Expand ENV VAR surface in generated config files — DONE

- `application.properties.ftl` in both Spring Boot and Quarkus (fullstack + standalone) has full ENV VAR reference block.
- Dockerfile `ENV` block now declares every supported ENV VAR with defaults.
- docker-compose `environment:` block and k8s ConfigMap fully populated.

### CLOUD-3 · Backend-side credential validation from ENV VAR — DONE

- When `securityLevel == "apiKey"`: backend reads `API_KEY` env var; every handler validates `X-API-Key` header and returns 401 on mismatch (both Spring Boot and Quarkus, fullstack + standalone).
- Frontend switched from `process.env.API_KEY` to `import.meta.env.VITE_API_KEY`.
- `VITE_API_KEY` added as Dockerfile build arg.

### CLOUD-4 · Frontend API base URL from ENV VAR — DONE

- React/Vue: `import.meta.env.VITE_API_BASE_URL` prepended to all API calls.
- Angular: `environment.ts.ftl` generated with `apiBaseUrl` reading from `window.__APIBRIDGE_BASE_URL`.
- `VITE_API_BASE_URL` added as Dockerfile `ARG` and docker-compose `build.args`.

### CLOUD-5 · CORS origins from ENV VAR — DONE

- Spring Boot: `CorsConfig.java.ftl` generated in both fullstack and standalone, reads `CORS_ALLOWED_ORIGINS` env var.
- Quarkus: `quarkus.http.cors.origins=${CORS_ALLOWED_ORIGINS:*}` in `application.properties.ftl`.
- `CORS_ALLOWED_ORIGINS=*` added to Dockerfile, docker-compose, k8s ConfigMap.

---

## Prioritisation

```
GAP-6   ✓ standalone cartridges fixed
GAP-7   ✓ --version flag added
CLOUD-1 ✓ backend URL env var overrides
CLOUD-2 ✓ full ENV VAR surface in config files
CLOUD-3 ✓ backend-side API key validation
CLOUD-4 ✓ frontend base URL from env var
CLOUD-5 ✓ CORS origins from env var
```
