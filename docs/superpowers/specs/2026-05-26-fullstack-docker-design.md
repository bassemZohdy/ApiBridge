# Fullstack Docker Generation — Design Spec
_Date: 2026-05-26_

## Overview

Extend ApiBridge to generate a complete, Dockerized full-stack application from a single YAML schema. The generated artifact is a `docker build && docker run` ready project combining a Java backend (Spring Boot or Quarkus) with a JavaScript frontend (Angular, React, or Vue), served from a single JVM process on port 8080.

---

## Decisions

| Topic | Decision |
|---|---|
| Container model | Java serves FE static files (Option A — single JVM, no nginx) |
| FE framework selection | `flags.feFlavor` in schema + `--fe-flavor` CLI override |
| Cartridge architecture | Subdirectory-routed single `fullstack` cartridge (Approach A) |
| BE default behavior | Proxy requests to `endpoint.backendUrl` via RestTemplate / Quarkus REST Client |
| Mock mode | `MOCK_MODE=true` env var → return mock JSON instead of proxying |
| Block mode | `BLOCK_TRAFFIC=true` env var → return 503 for all `/api/*` calls |

---

## 1. Schema Extension

Add `feFlavor` to `BridgeSchemaModel.Flags`:

```java
private String feFlavor = "react"; // default
```

Valid values: `angular` | `react` | `vue`

`YamlParser` validates it with the same pattern as `backendFlavor` and `uiPattern` (case-insensitive).

New YAML usage:
```yaml
flags:
  backendFlavor: "spring-boot"
  feFlavor: "angular"         # new field
  uiPattern: "form-engine"
  enableTelemetry: true
```

---

## 2. Engine Changes

### ApiBridgeRunner
- New optional CLI arg: `--fe-flavor=angular|react|vue` (overrides `flags.feFlavor`)
- New optional CLI arg: `--be-flavor=spring-boot|quarkus` (overrides `flags.backendFlavor`)
- Both values injected into FreeMarker context as `feFlavor` and `backendFlavor`

### ApiBridgeCartridgeEngine
1. **Recursive FTL scan** — scan subdirectories, not just cartridge root
2. **Flavor-dir selection** — subdirectories named `backend-{flavor}/` or `frontend-{flavor}/` are only processed if the flavor matches the selected BE/FE flavor; mismatched dirs are skipped entirely
3. **Output path mapping** — `backend-{flavor}/foo/bar.java.ftl` outputs to `backend/foo/bar.java`; `frontend-{flavor}/src/App.tsx.ftl` outputs to `frontend/src/App.tsx`; root-level FTL files output to root
4. **Skip empty output** — after rendering, if the output content is blank, skip writing the file

---

## 3. Fullstack Cartridge Structure

```
apibridge-cartridges/fullstack/
├── Dockerfile.ftl                              → Dockerfile
├── docker-compose.yml.ftl                      → docker-compose.yml
├── .dockerignore.ftl                           → .dockerignore
│
├── backend-spring-boot/
│   ├── pom.xml.ftl                             → backend/pom.xml
│   ├── Application.java.ftl                    → backend/src/main/java/.../Application.java
│   ├── Controller.java.ftl                     → backend/src/main/java/.../Controller.java
│   ├── ProxyService.java.ftl                   → backend/src/main/java/.../ProxyService.java
│   └── application.properties.ftl             → backend/src/main/resources/application.properties
│
├── backend-quarkus/
│   ├── pom.xml.ftl                             → backend/pom.xml
│   ├── Application.java.ftl                    → backend/src/main/java/.../Application.java
│   ├── Resource.java.ftl                       → backend/src/main/java/.../Resource.java
│   ├── ProxyService.java.ftl                   → backend/src/main/java/.../ProxyService.java
│   └── application.properties.ftl             → backend/src/main/resources/application.properties
│
├── frontend-angular/
│   ├── package.json.ftl                        → frontend/package.json
│   ├── angular.json.ftl                        → frontend/angular.json
│   ├── tsconfig.json.ftl                       → frontend/tsconfig.json
│   ├── src/index.html.ftl                      → frontend/src/index.html
│   ├── src/main.ts.ftl                         → frontend/src/main.ts
│   ├── src/app/app.module.ts.ftl               → frontend/src/app/app.module.ts
│   ├── src/app/app.component.ts.ftl            → frontend/src/app/app.component.ts
│   ├── src/app/app.component.html.ftl          → frontend/src/app/app.component.html
│   ├── src/app/bridge-api.service.ts.ftl       → frontend/src/app/bridge-api.service.ts
│   ├── src/app/bridge-form.component.ts.ftl    → frontend/src/app/bridge-form.component.ts
│   └── src/app/bridge-form.component.html.ftl → frontend/src/app/bridge-form.component.html
│
├── frontend-react/
│   ├── package.json.ftl                        → frontend/package.json
│   ├── vite.config.ts.ftl                      → frontend/vite.config.ts
│   ├── tsconfig.json.ftl                       → frontend/tsconfig.json
│   ├── index.html.ftl                          → frontend/index.html
│   ├── src/main.tsx.ftl                        → frontend/src/main.tsx
│   ├── src/api/bridgeApi.ts.ftl                → frontend/src/api/bridgeApi.ts
│   └── src/ApiBridgeForm.tsx.ftl               → frontend/src/ApiBridgeForm.tsx
│
└── frontend-vue/
    ├── package.json.ftl                        → frontend/package.json
    ├── vite.config.ts.ftl                      → frontend/vite.config.ts
    ├── tsconfig.json.ftl                       → frontend/tsconfig.json
    ├── index.html.ftl                          → frontend/index.html
    ├── src/main.ts.ftl                         → frontend/src/main.ts
    ├── src/api/bridgeApi.ts.ftl                → frontend/src/api/bridgeApi.ts
    └── src/ApiBridgeForm.vue.ftl               → frontend/src/ApiBridgeForm.vue
```

---

## 4. Generated Output Structure

For `backendFlavor: spring-boot` + `feFlavor: angular`:
```
output/
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── backend/
│   ├── pom.xml
│   └── src/main/
│       ├── java/com/apibridge/generated/{ServiceName}/
│       │   ├── Application.java
│       │   ├── {ServiceName}Controller.java
│       │   └── ProxyService.java
│       └── resources/
│           ├── application.properties
│           └── static/               ← FE dist/ copied here during Docker build
└── frontend/
    ├── package.json
    ├── angular.json
    ├── tsconfig.json
    └── src/
        ├── index.html
        ├── main.ts
        └── app/
            ├── app.module.ts
            ├── app.component.ts
            ├── app.component.html
            ├── bridge-api.service.ts
            ├── bridge-form.component.ts
            └── bridge-form.component.html
```

---

## 5. Dockerfile Design (multi-stage)

```dockerfile
# Stage 1: Build frontend
FROM node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Build backend + embed FE static files
FROM maven:3.9-amazoncorretto-21-alpine AS backend-build
WORKDIR /app/backend
COPY backend/pom.xml ./
RUN mvn dependency:go-offline -q
COPY backend/src ./src
# Angular 17 outputs to dist/<id>-fe/browser; React/Vue output to dist/
COPY --from=frontend-build /app/frontend/dist/<platform-specific>/ \
     ./src/main/resources/static/       # Spring Boot
     # OR ./src/main/resources/META-INF/resources/  # Quarkus
RUN mvn package -DskipTests -q

# Stage 3: Minimal runtime
FROM amazoncorretto:21-alpine
WORKDIR /app
COPY --from=backend-build /app/backend/target/*.jar app.jar
EXPOSE 8080
ENV MOCK_MODE=false
ENV BLOCK_TRAFFIC=false
ENTRYPOINT ["java", "-jar", "app.jar"]
```

FE dist output paths:
- Angular 17+: `dist/{id}-fe/browser/`
- React (Vite): `dist/`
- Vue (Vite): `dist/`

---

## 6. Backend Proxy + ENV Flags

Both Spring Boot and Quarkus controllers implement the same three-mode behavior:

```
BLOCK_TRAFFIC=true  → HTTP 503 {"error": "Service temporarily unavailable"}
MOCK_MODE=true      → HTTP 200 {"status": "mock", "endpoint": "<path>", "method": "<method>"}
default             → Forward request to endpoint.backendUrl, return upstream response
```

Spring Boot: `ProxyService` uses `RestTemplate` — copies request headers (Authorization, Content-Type, X-*), forwards body, returns upstream status + body.

Quarkus: `ProxyService` uses MicroProfile REST Client (`@RegisterRestClient`) — same semantics.

---

## 7. Frontend API Service

Each FE framework generates a typed API service that calls `window.location.origin + /api/{basePath}/{endpoint.path}`. Same-origin requests, no CORS configuration needed.

- Angular: `BridgeApiService` using `HttpClient`, returns `Observable<any>`
- React: `bridgeApi.ts` using `axios`, returns `Promise<AxiosResponse>`
- Vue: `bridgeApi.ts` using `fetch`, returns `Promise<Response>`

---

## 8. Testing

- `YamlParserTest`: add `feFlavor` validation cases (invalid value, case-insensitive pass)
- `ApiBridgeCartridgeEngineTest`: add subdirectory routing test (verify flavor-dir selection and path mapping)
- `e2e-tests/docker-fullstack-test/run-e2e.sh`: generate fullstack app, run `docker build`, verify image builds successfully
- Add to `run-all-e2e.sh`

---

## 9. Documentation

- `docs/schema-reference.md`: add `feFlavor` field
- `CLAUDE.md`: update cartridge section to mention `fullstack` and new CLI flags
