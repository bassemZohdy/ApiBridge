# ApiBridge — Pluggable MDA Code Generation Engine

ApiBridge is a Model-Driven Architecture (MDA) code generator written in Java 21. It reads a unified YAML schema (the **Platform-Independent Model**, or PIM) and processes it through one or more pluggable **cartridges** to emit platform-specific code.

Each cartridge is an independent directory of FreeMarker templates. The engine applies them in sequence to the same output directory — there are no cross-cartridge dependencies. Select exactly the cartridges you need; unused ones are simply not applied.

---

## Project Layout

```
apibridge-generator/              # Java engine — the only Maven module
apibridge-cartridges/             # Pluggable cartridge directories (not Maven modules)
├── backend/
│   ├── spring-boot/              # Spring Boot REST proxy (output: backend/)
│   └── quarkus/                  # Quarkus JAX-RS proxy (output: backend/)
├── frontend/
│   ├── angular/                  # Angular 17 full project (output: frontend/)
│   ├── react/                    # React 18 + Vite full project (output: frontend/)
│   ├── vue/                      # Vue 3 + Vite full project (output: frontend/)
│   └── ui-schema/                # UiLayoutSchema.json for UI-driven forms (output: frontend/)
├── devops/
│   ├── dockerfile/               # Multi-stage Dockerfile (FE stage conditional)
│   ├── docker-compose/           # docker-compose.yml
│   └── k8s/
│       ├── kubernetes/           # K8s Deployment + Service + ConfigMap + Kustomization
│       └── openshift/            # Extends kubernetes with TLS Route
docs/                             # Reference documentation
sample-schema.yaml                # Working example PIM schema
e2e-tests/                        # Integration tests — run on CI, not before every commit
```

---

## Quick Start

```bash
# 1. Build the fat JAR
mvn clean package

# 2. Spring Boot + React, Docker Compose deployment
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/frontend/react \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/docker-compose \
  --output=output/my-app

# 3. Build and run
cd output/my-app
docker compose up --build

# 4. Mock mode — returns canned JSON, no upstream calls
docker compose run --rm -e MOCK_MODE=true my-app

# 5. Backend-only (no FE cartridge)
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/quarkus \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --output=output/quarkus-only
```

---

## CLI Reference

```
java -jar apibridge-generator.jar \
  --schema=<path>           Path to the YAML PIM schema
  --cartridge=<path>        Cartridge to apply (repeatable; applied in order)
  --output=<path>           Destination directory for generated files
  [--be-flavor=<val>]       Override backend: spring-boot | quarkus
  [--fe-flavor=<val>]       Override frontend: angular | react | vue
  [--deploy-target=<val>]   Override deployment: docker-compose | kubernetes | openshift
  [--security-level=<val>]  Override security: bearer-token | apiKey
  [--version | -v]          Print version and exit
  [-h | --help]             Show help
```

`--cartridge` is repeatable. Each cartridge's output merges into the same `--output` directory in the order specified.

---

## Cartridges

### Backend cartridges

| Cartridge | Output |
|---|---|
| `backend/spring-boot` | `backend/` — Spring Boot 3.x proxy with RestTemplate, Actuator, OTel |
| `backend/quarkus` | `backend/` — Quarkus 3.x JAX-RS proxy with JAX-RS Client, Health, OTel |

Both backends:
- Proxy every schema endpoint to its `backendUrl`
- Forward all request/response headers (excluding hop-by-hop) and query parameters
- `MOCK_MODE=true` returns a canned JSON response instead of proxying
- `BLOCK_TRAFFIC=true` returns 503 for every request
- Every config value is overridable at runtime via ENV VAR (see `application.properties`)
- When a `frontend/` cartridge is also applied, the backend serves the compiled FE assets from its static resources directory (`classpath:/static/` for Spring Boot, `META-INF/resources/` for Quarkus)

### Frontend cartridges

| Cartridge | Output |
|---|---|
| `frontend/angular` | `frontend/` — Angular 17 + TypeScript, dynamic form engine |
| `frontend/react` | `frontend/` — React 18 + Vite + TypeScript, dynamic form engine |
| `frontend/vue` | `frontend/` — Vue 3 + Vite + TypeScript, dynamic form engine |
| `frontend/ui-schema` | `frontend/UiLayoutSchema.json` — JSON schema for UI-driven form rendering |

Frontend pages are generated from the schema:
- **Form** — dynamic form driven by `uiLayout.fields` for POST/PUT endpoints
- **List** — paginated table driven by `uiLayout.columns` for GET collection endpoints
- **View** — detail view for GET by-ID endpoints, with optional DELETE support
- All pages use a centralized `getAuthHeaders()` helper for security

### DevOps cartridges

| Cartridge | Output |
|---|---|
| `devops/dockerfile` | `Dockerfile` — three-stage: FE build (node), BE build + embed (maven), runtime (JRE) |
| `devops/docker-compose` | `docker-compose.yml` — local dev with healthcheck and resource limits |
| `devops/k8s/kubernetes` | `k8s/` — Deployment + Service + ConfigMap + Kustomization |
| `devops/k8s/openshift` | `k8s/route.yaml` + updated `k8s/kustomization.yaml` — apply on top of kubernetes |

The `devops/dockerfile` FE build stage is automatically omitted when no `feFlavor` is set (BE-only output).

For OpenShift: apply both `devops/k8s/kubernetes` and `devops/k8s/openshift` to get the full manifest set including a TLS edge-terminated Route.

### Single-JAR deployment

When both a backend and frontend cartridge are applied, the multi-stage Dockerfile builds the FE and copies the compiled dist into the BE's static resources directory before the Maven build, producing a **single runnable JAR** that serves both the API and the frontend:

```
Stage 1  node:20-alpine             — npm build → dist/
Stage 2  maven:3.9-amazoncorretto   — COPY dist → src/main/resources/static/ → mvn package
Stage 3  amazoncorretto:21-alpine   — java -jar app.jar (port 8080)
```

---

## YAML Schema

Full reference: [docs/schema-reference.md](docs/schema-reference.md)

Minimal valid schema:

```yaml
id: "my-service"
basePath: "/api/v1"
endpoints:
  - path: "/run"
    method: "POST"
    backendUrl: "https://upstream.internal/run"
```

Full example with all flags:

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  backendFlavor: "spring-boot"   # spring-boot | quarkus
  feFlavor: "react"              # angular | react | vue  (omit for BE-only)
  securityLevel: "bearer-token"  # bearer-token | apiKey
  enableTelemetry: true
  pagination:
    pageParam: "page"            # overrideable via PAGINATION_PAGE_PARAM ENV VAR
    sizeParam: "size"
    defaultPageSize: 20
    sortParam: "sort"
    directionParam: "dir"
endpoints:
  - path: "/submissions"
    method: "GET"
    backendUrl: "https://mesh.internal/customer/submissions"
    uiLayout:
      component: "List"          # List | View | Form
      columns:
        - field: "email"
          label: "Email"
          sortable: true
        - field: "status"
          label: "Status"
          sortable: false

  - path: "/submissions/{id}"
    method: "GET"
    backendUrl: "https://mesh.internal/customer/submissions/1"
    uiLayout:
      component: "View"
      fields:
        - name: "email"
          label: "Email Address"
        - name: "status"
          label: "Status"

  - path: "/initiate"
    method: "POST"
    backendUrl: "https://mesh.internal/customer/create"
    telemetryName: "apibridge_onboarding_initiate"
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

### SPA routing

Frontend projects use hash-based SPA routing (no router library). The generated `App` component routes:

| Hash | Page |
|---|---|
| `#/` or `#/list` | List page (GET collection endpoint) |
| `#/view/:id` | View page (GET by-ID endpoint) |
| `#/form` | New record form |
| `#/form/:id` | Edit record form |

### White-label CSS

Generated UIs use neutral CSS defaults. Override at runtime without rebuilding:

```bash
docker run -p 8080:8080 \
  -v /path/brand.css:/config/brand.css:ro \
  -e CUSTOM_CSS_PATH=/config/brand.css \
  my-image:latest
```

See [`docs/white-label-style-guide.md`](docs/white-label-style-guide.md) for the full CSS custom properties reference and class inventory.

---

## Common combinations

```bash
JAR="apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar"

# Quarkus + Angular, Kubernetes deployment
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/quarkus \
  --cartridge=apibridge-cartridges/frontend/angular \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/k8s/kubernetes \
  --output=output/quarkus-angular-k8s \
  --be-flavor=quarkus \
  --fe-flavor=angular

# Spring Boot only, OpenShift deployment
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/devops/dockerfile \
  --cartridge=apibridge-cartridges/devops/k8s/kubernetes \
  --cartridge=apibridge-cartridges/devops/k8s/openshift \
  --output=output/spring-openshift

# UI schema only
java -jar "$JAR" \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/frontend/ui-schema \
  --output=output/ui-schema
```

---

## Development

```bash
# Unit tests (fast — run freely)
mvn test

# Full verify: unit tests + Checkstyle
mvn verify

# E2E tests (slow — run on CI or before shipping)
./e2e-tests/run-all-e2e.sh
```

Checkstyle rules: 4-space indent, no star imports, no unused imports, braces required.

### Adding a cartridge

1. Create a directory anywhere under `apibridge-cartridges/` (the path becomes the `--cartridge=` argument).
2. Add `.ftl` FreeMarker templates. The output filename is the template name with `.ftl` stripped; directory tree is mirrored 1:1 to output.
3. Available template variables:

| Variable | Type | Notes |
|---|---|---|
| `id` | String | Service identifier |
| `basePath` | String | REST base path |
| `flags` | Flags | Schema flags object (may be null if `flags:` key absent) |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | `spring-boot` or `quarkus` (never null) |
| `feFlavor` | String | `react`, `angular`, `vue`, or `""` if unset |
| `deployTarget` | String | `docker-compose`, `kubernetes`, `openshift`, or `""` |
| `flags.pagination` | Pagination | Pagination param names; never null when flags is non-null |
| `endpoint.uiLayout.component` | String | `Form`, `List`, or `View` |
| `endpoint.uiLayout.columns` | List\<Column\> | Schema-defined list columns (optional; runtime fallback if absent) |
| `field.label` | String | Optional display label for form/view fields |

**Filtering form endpoints in templates**: use `endpoints?filter(ep -> ep.method?upper_case != "GET")` to get only mutation endpoints. All Form templates already do this internally via the `formEndpoints` assignment.

Use `(feFlavor!"") != ""` to gate FE-specific content in templates that apply to both FE and BE scenarios (e.g., Dockerfile).

---

## Production best practices applied

**Container / runtime:**
- Non-root user (UID 1001, `chmod g=u` for OpenShift arbitrary-UID policy)
- JVM: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`
- `JAVA_OPTS` passed through for runtime tuning without image rebuild
- Graceful shutdown configured (30 s drain)
- HTTP compression enabled
- Structured JSON logging for EFK / Loki / CloudWatch

**Kubernetes manifests:**
- Startup, liveness, and readiness probes (flavor-conditional paths)
- `readOnlyRootFilesystem: true` + `emptyDir` for `/tmp`
- `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]`
- CPU/memory requests and limits
- `terminationGracePeriodSeconds: 45`
- Kustomization image tag override

---

## CI

GitHub Actions (`.github/workflows/ci.yml`): `build` job (`mvn verify` on JDK 21) → `e2e-compile` (all cartridge compile checks) → `e2e-docker` (fullstack Docker build + runtime) → `e2e-json-server` (live API integration). Triggers on push to `main`/`feature**`/`bugfix**` and PRs to `main`.
