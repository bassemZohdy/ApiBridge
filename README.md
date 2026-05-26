# ApiBridge — Pluggable MDA Code Generation Engine

ApiBridge is a Model-Driven Architecture (MDA) code generation engine written in Java 21. It reads a unified YAML schema (the **Platform-Independent Model**, or PIM) and processes it through a pluggable **cartridge** to emit platform-specific code in a single pass.

The engine is framework-agnostic: it knows nothing about Spring Boot, Quarkus, Angular, React, or Vue. All platform knowledge lives in the cartridge templates.

---

## Project Layout

```
apibridge-generator/           # Java engine — the only Maven module
apibridge-cartridges/          # Pluggable cartridge directories (not Maven modules)
├── backend-spring-boot/       # Standalone Spring Boot REST controller
├── backend-quarkus/           # Standalone Quarkus JAX-RS resource
├── frontend-ui-schema/        # UI layout JSON schema cartridge
├── frontend-angular/          # Angular bridge form component
├── frontend-react/            # React bridge form component
├── frontend-vue/              # Vue bridge form component
└── fullstack/                 # Complete containerized app (BE + FE in one Docker image)
    ├── Dockerfile.ftl             # Three-stage multi-stage build
    ├── docker-compose.yml.ftl
    ├── .dockerignore.ftl
    ├── backend-spring-boot/       # Spring Boot backend subtree (selected by backendFlavor)
    ├── backend-quarkus/           # Quarkus backend subtree (selected by backendFlavor)
    ├── frontend-angular/          # Angular frontend subtree (selected by feFlavor)
    ├── frontend-react/            # React frontend subtree (selected by feFlavor)
    └── frontend-vue/              # Vue frontend subtree (selected by feFlavor)
e2e-tests/                     # Integration tests — run on CI, not before every commit
docs/                          # Reference documentation
sample-schema.yaml             # Working example PIM schema
```

---

## Quick Start

```bash
# 1. Build the fat JAR
mvn clean package

# 2. Generate a fullstack containerized app (Spring Boot + React by default)
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/fullstack \
  --output=output/my-app

# 3. Build and run the generated Docker image
cd output/my-app
docker build -t my-app .
docker run -p 8080:8080 my-app

# 4. Run in mock mode (returns canned JSON, no upstream calls)
docker run -p 8080:8080 -e MOCK_MODE=true my-app

# 5. Block all traffic (returns 503 for all endpoints)
docker run -p 8080:8080 -e BLOCK_TRAFFIC=true my-app
```

---

## CLI Reference

```
java -jar apibridge-generator.jar --schema=<path> --cartridge=<path> --output=<path> [options]

Required:
  --schema=<path>      Path to the YAML PIM schema file
  --cartridge=<path>   Path to the cartridge directory (contains *.ftl templates)
  --output=<path>      Destination directory for generated files

Optional overrides (take precedence over schema flags):
  --be-flavor=<val>       Backend framework: spring-boot | quarkus
  --fe-flavor=<val>       Frontend framework: angular | react | vue
  --deploy-target=<val>   Deployment config: docker-compose | kubernetes | openshift
  -h, --help              Show help
```

---

## Cartridges

### Standalone cartridges

These generate a single artifact and are used directly:

| Cartridge | Output |
|---|---|
| `backend-spring-boot` | Spring Boot `@RestController` + `pom.xml` |
| `backend-quarkus` | Quarkus JAX-RS `@Path` resource + `pom.xml` |
| `frontend-ui-schema` | UI layout JSON schema |
| `frontend-angular` | Angular form component (`.ts` + `.html`) |
| `frontend-react` | React form component (`.tsx`) |
| `frontend-vue` | Vue 3 SFC (`.vue`) |

```bash
# Spring Boot controller
java -jar apibridge-generator.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend-spring-boot \
  --output=output/spring-boot

# React component
java -jar apibridge-generator.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/frontend-react \
  --output=output/react
```

### Fullstack cartridge

`apibridge-cartridges/fullstack` generates a complete project with a three-stage multi-stage `Dockerfile`:

```
Stage 1  node:20-alpine          — builds the frontend (Vite or Angular CLI)
Stage 2  maven:3.9-amazoncorretto-21-alpine — builds the backend, embeds FE static files
Stage 3  amazoncorretto:21-alpine           — minimal JRE runtime, exposes port 8080
```

The backend proxies every endpoint defined in the schema to its `backendUrl`. Two environment variables control runtime behaviour:

| Variable | Default | Effect |
|---|---|---|
| `MOCK_MODE` | `false` | Returns a canned JSON response instead of proxying |
| `BLOCK_TRAFFIC` | `false` | Returns 503 for every request |

**Frontend framework** is selected with `flags.feFlavor` (or `--fe-flavor` override):

| `feFlavor` | Framework | Build tool |
|---|---|---|
| `react` (default) | React 18 + TypeScript | Vite |
| `angular` | Angular 17 + TypeScript | Angular CLI |
| `vue` | Vue 3 + TypeScript | Vite |

**Backend framework** is selected with `flags.backendFlavor` (or `--be-flavor` override):

| `backendFlavor` | Framework |
|---|---|
| `spring-boot` (default) | Spring Boot 3.x |
| `quarkus` | Quarkus 3.x (JAX-RS) |

```bash
# Quarkus + Angular fullstack
java -jar apibridge-generator.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/fullstack \
  --output=output/quarkus-angular \
  --be-flavor=quarkus \
  --fe-flavor=angular
```

#### Generated output layout

The core output (always generated):

```
output/
├── Dockerfile               # Three-stage multi-stage build
├── .dockerignore
├── backend/                 # Complete Maven project (Spring Boot or Quarkus)
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/apibridge/generated/
│       │   ├── Application.java       (Spring Boot only)
│       │   ├── BridgeController.java  (Spring Boot) / BridgeResource.java (Quarkus)
│       │   └── ProxyService.java
│       └── resources/
│           └── application.properties
└── frontend/                # Complete Vite/Angular project
    ├── package.json
    ├── vite.config.ts / angular.json
    └── src/
```

Additional deployment configs (only when `flags.deployTarget` is set):

| `deployTarget` | Extra files generated |
|---|---|
| `docker-compose` | `docker-compose.yml` — local dev with healthcheck + resource limits |
| `kubernetes` | `k8s/configmap.yaml`, `k8s/deployment.yaml`, `k8s/service.yaml`, `k8s/kustomization.yaml` |
| `openshift` | Same as `kubernetes` + `k8s/route.yaml` (TLS edge-terminated Route) |

#### Production best practices applied

**Container / runtime:**
- Non-root user (UID 1001, `chmod g=u` for OpenShift arbitrary-UID policy)
- `HEALTHCHECK` instruction in Dockerfile (Docker/Compose)
- JVM flags: `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0` (respects cgroup memory limits)
- `JAVA_OPTS` env var passed through for runtime JVM tuning without image rebuild
- OCI labels on the image (`org.opencontainers.image.*`)

**Backend:**
- RestTemplate (Spring Boot) configured with 10 s connect / 30 s read timeouts
- JAX-RS Client (Quarkus) configured with 10 s connect / 30 s read timeouts + `@PreDestroy` close
- Graceful shutdown (`server.shutdown=graceful` / `quarkus.shutdown.timeout=30S`)
- HTTP compression enabled
- Upstream `Content-Type` propagated back to the caller
- Structured JSON logging for container log aggregators (EFK, Loki, CloudWatch)

**Kubernetes / OpenShift:**
- Startup, liveness, and readiness probes (flavor-conditional paths)
- `readOnlyRootFilesystem: true` + `emptyDir` mount for `/tmp`
- `allowPrivilegeEscalation: false` + `capabilities.drop: [ALL]`
- CPU/memory `requests` and `limits` defined
- `terminationGracePeriodSeconds: 45` (> graceful shutdown timeout)
- Kustomization file for image tag override without editing manifests

**Deployment:**
```bash
# Build the image (Dockerfile always generated)
docker build -t my-registry/my-service:1.0.0 output/my-app
docker push my-registry/my-service:1.0.0

# Local dev (requires flags.deployTarget: docker-compose)
docker compose -f output/my-app/docker-compose.yml up

# Kubernetes (requires flags.deployTarget: kubernetes or openshift)
# Update newTag in k8s/kustomization.yaml, then:
kubectl apply -k output/my-app/k8s/

# OpenShift (requires flags.deployTarget: openshift)
oc apply -k output/my-app/k8s/
```

#### UI rendering modes

Frontend templates support two modes controlled by `flags.uiPattern`:

- **`form-engine`** (default) — renders a dynamic form backed by RJSF (React), ngx-formly (Angular), or Composition API reactive state (Vue), driven by the `uiLayout.fields` definition in the schema.
- **`web-component`** — renders a thin wrapper that registers and drives a pre-built `<api-bridge-form>` custom element.

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

With all flags:

```yaml
id: "customer-onboarding-bridge"
basePath: "/api/v1/onboarding"
flags:
  backendFlavor: "spring-boot"   # spring-boot | quarkus
  feFlavor: "react"              # angular | react | vue
  uiPattern: "form-engine"       # form-engine | web-component
  securityLevel: "bearer-token"  # bearer-token | apiKey
  enableTelemetry: true
endpoints:
  - path: "/initiate"
    method: "POST"
    backendUrl: "https://mesh.internal/customer/create"
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

## Development

```bash
# Unit tests (fast — run freely)
mvn test

# Full verify: unit tests + Checkstyle
mvn verify

# E2E tests (slow — run on CI or before shipping)
./e2e-tests/run-all-e2e.sh
```

Checkstyle rules: 4-space indent, no star imports, no unused imports, braces required on all blocks.

### Adding a cartridge

1. Create a directory under `apibridge-cartridges/`.
2. Add `.ftl` FreeMarker templates. The output filename is the template name with `.ftl` stripped.
3. Use these variables in templates:

| Variable | Type | Description |
|---|---|---|
| `id` | String | Service identifier from schema |
| `basePath` | String | REST base path |
| `flags` | Flags object | All schema flags |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | Resolved BE flavor (`spring-boot` or `quarkus`) |
| `feFlavor` | String | Resolved FE flavor (`react`, `angular`, or `vue`) |

For subdirectory-routed cartridges (like `fullstack`), name subdirectories `backend-{flavor}/` or `frontend-{flavor}/` — the engine selects the matching one and maps its output to `backend/` or `frontend/` in the output directory.

---

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`):

- **build** job: `mvn verify` on JDK 21 — runs on every push and PR
- **e2e** job: full E2E suite including Docker build — runs after `build`
