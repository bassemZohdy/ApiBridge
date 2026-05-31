# AGENTS.md

## Build

- Java 21 (JDK 21 required — `maven.compiler.release=21`).
- Single Maven module: `apibridge-generator/`. Cartridges under `apibridge-cartridges/` are **not** Maven modules — they are plain directories of `.ftl` FreeMarker templates.
- Web schema builder: `apibridge-web-builder/` — separate Vite+React+TypeScript module (not a Maven module).
- Fat JAR via `maven-shade-plugin`; main class: `com.apibridge.engine.ApiBridgeRunner`.
- Output JAR: `apibridge-generator/target/apibridge-generator-0.1.0.jar`.
- Shell wrappers: `bin/apibridge` (Unix) and `bin/apibridge.bat` (Windows) delegate to `java -jar`.
- Generator Docker image: `Dockerfile.generator` — multi-stage build with bundled cartridges.

```bash
mvn clean package            # build fat JAR (skips tests)
mvn test                     # unit tests only (fast)
mvn verify                   # unit tests + Checkstyle + JaCoCo report + coverage threshold (85% instruction / 80% branch)
```

## Verify before committing

```bash
mvn verify
```

This runs Checkstyle and unit tests. Do not skip this before pushing.

## Checkstyle (fails build on violation)

Config: `apibridge-generator/checkstyle.xml`. Key rules:
- 4-space indent
- No star imports, no unused imports, no redundant imports
- Braces required (`NeedBraces`)
- Newline at end of file
- Empty catch blocks must name variable `expected` or `ignore`

## Architecture

- **Engine entry point**: `ApiBridgeRunner.main()` — CLI arg parser, parses schemas via `YamlParser.parse()`, composes multiple schemas via `SchemaComposer`, resolves cartridge references via `CartridgeResolver`, then calls `ApiBridgeCartridgeEngine.generate()` per cartridge.
- **Model**: `BridgeSchemaModel` (in `.model` subpackage) — Jackson-deserialized from YAML. Contains `Flags` (with defaults: `backendFlavor="spring-boot"`), `Pagination`, `Endpoint`, `UiLayout`, `Field`, `Column`. Full Javadoc on all classes and fields.
- **Schema composition**: `SchemaComposer` merges multiple `BridgeSchemaModel` instances — `id`/`basePath`/`flags` from primary schema, `endpoints` concatenated in order, cross-schema duplicates rejected.
- **Cartridge resolution**: `CartridgeResolver` handles three reference formats (local path, URL, `github:` shorthand). Downloads are cached at `~/.apibridge/cartridges/<sha256>/` via `CartridgeCache`. ZIP extraction uses `CartridgeDownloader` with zip-slip protection.
- **Template engine**: FreeMarker 2.3.32. Cartridge dir = template root. `.ftl` suffix stripped for output filenames.
- **Output prefixing**: cartridges nested under `backend/`, `frontend/`, or `k8s/` auto-prefix their output with that directory name (e.g. `backend/spring-boot/BridgeController.java.ftl` → `<output>/backend/BridgeController.java`). Other cartridges (e.g. `devops/dockerfile`) emit directly to output root.
- **Empty template output**: if a template renders to blank, it is skipped (no file written). Use this for conditional files.
- **JaCoCo excludes** `ApiBridgeRunner.class` (calls `System.exit`).
- **Backend method naming**: generated Java methods include HTTP method prefix (e.g. `postInitiate()`, `getSubmissions()`) to avoid collision when endpoints share paths with different verbs.
- **ProxyService forwarding**: both backends forward all request/response headers (excluding standard hop-by-hop set) and append query parameters to the upstream URL.

## FreeMarker template context

Available variables in all `.ftl` templates:

| Variable | Type | Notes |
|---|---|---|
| `id` | String | Service identifier |
| `basePath` | String | REST base path |
| `flags` | Flags | Always non-null — `ApiBridgeRunner` synthesises `new Flags()` when absent. Use field-level guards (`flags.securityLevel??`), not `flags??`. |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | `spring-boot` or `quarkus` (never null, defaults to `spring-boot`) |
| `feFlavor` | String | `react`, `angular`, `vue`, or `""` if unset |
| `deployTarget` | String | `docker-compose`, `kubernetes`, `openshift`, or `""` |
| `enableRateLimiter` | boolean | `false` when flag off. Top-level convenience variable. |
| `enableTransform` | boolean | `false` when flag off. Top-level convenience variable. |
| `apiVersion` | String | `""` when unset. Top-level convenience variable. |
| `enableHealthCheck` | boolean | `false` when flag off. Top-level convenience variable. |
| `enableSearch` | boolean | `false` when flag off. Top-level convenience variable. |
| `enableOfflineSupport` | boolean | `false` when flag off. Top-level convenience variable. |
| `enableOpenApi` | boolean | `false` when flag off. Top-level convenience variable. |
| `enableOidc` | boolean | `false` when flag off. Gates `SecurityConfig.java` generation. |
| `oidcIssuerUri` | String | OIDC issuer URL. Only meaningful when `enableOidc` is true. |

Gate FE-specific content with: `(feFlavor!"") != ""`.

## Running the generator

```bash
java -jar apibridge-generator/target/apibridge-generator-0.1.0.jar \
  --schema=users-service.yaml \
  --schema=orders-service.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/frontend/react \
  --cartridge=github:my-org/custom-cartridges/backend/spring-boot@v1 \
  --output=output/my-app
```

`--schema=` is repeatable — schemas are merged by `SchemaComposer` (id/basePath/flags from first schema, endpoints concatenated, cross-schema duplicates rejected).

CLI overrides take precedence over schema `flags`: `--be-flavor=`, `--fe-flavor=`, `--deploy-target=`, `--security-level=`.

**Cartridge reference formats** (`--cartridge=` accepts three forms):
- Local path: `./my-cartridge` or `/abs/path` — passed directly to engine
- URL: `https://host/file.zip` — downloaded, extracted, cached at `~/.apibridge/cartridges/<sha256>/`
- GitHub shorthand: `github:owner/repo[/subpath][@ref]` — downloads GitHub archive ZIP, default ref is `main`

## Web Schema Builder

Browser-based GUI at `apibridge-web-builder/` for building `schema.yaml` without writing YAML. Vite + React 18 + TypeScript + js-yaml. Live YAML preview, download button, flag toggles, endpoint editor. 20 tests (Vitest).

```bash
cd apibridge-web-builder && npm install && npm run dev   # http://localhost:5173
cd apibridge-web-builder && npm run lint                  # ESLint
cd apibridge-web-builder && npm test                      # 20 Vitest tests
```

## E2E tests

- Script: `./e2e-tests/run-all-e2e.sh` (bash — requires Linux/macOS or WSL).
- Set `SKIP_GENERATOR_BUILD=true` to skip rebuilding the JAR (used in CI).
- Suites: Spring Boot compile, Quarkus compile, Angular/React/Vue strict TypeScript compile, React/Vue/Angular production build, contract symmetry, Kubernetes manifest validation, OpenShift manifest validation, Helm chart validation, OpenAPI spec validation, UI schema validation, OIDC SecurityConfig, apiKey security, multi-schema composition, fullstack Docker, json-server integration (19 suites total).
- **Slow** — run on CI/PR only, not before every local commit.
- Individual suite: e.g. `./e2e-tests/maven-spring-boot-test/run-e2e.sh`.

## Adding a cartridge

1. Create a directory under `apibridge-cartridges/`. Its path is the `--cartridge=` value.
2. Add `.ftl` files. Directory tree mirrors 1:1 to output; `.ftl` suffix is stripped.
3. Add unit tests in an engine test class to verify generation.
4. Add an E2E suite under `e2e-tests/` and wire it into `run-all-e2e.sh` and `.github/workflows/ci.yml`.

## Schema quick reference

Required fields: `id`, `basePath`, `endpoints` (non-empty list, each with `path`, `method`, `backendUrl`).

Valid `flags` enums:
- `backendFlavor`: `spring-boot` | `quarkus`
- `feFlavor`: `angular` | `react` | `vue`
- `securityLevel`: `bearer-token` | `apiKey`
- `deployTarget`: `docker-compose` | `kubernetes` | `openshift`
- `enableOidc`: `true` | `false` (default `false`) — requires `oidcIssuerUri`
- `oidcIssuerUri`: any URI string — required when `enableOidc: true`, overrideable at runtime via `OIDC_ISSUER_URI`
- `endpoints[].uiLayout.component`: `Form` | `List` | `View` (case-insensitive)
- `endpoints[].uiLayout.fields[].type` (for Form components): `string` | `number` | `integer` | `boolean` | `email` | `date` | `url` | `password` — maps to HTML input types; `email` adds pattern validation

HTTP methods allowed: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`. Duplicate endpoints (same path + method) are rejected.

Full reference: `docs/schema-reference.md`.

## CI

GitHub Actions (`.github/workflows/ci.yml`): `build` (mvn verify) → `web-builder` (lint + typecheck + tests), `e2e-compile` (17 compile checks incl. K8s/OpenShift/Helm/OpenAPI/OIDC/apiKey/multi-schema + Vue/Angular/React prod builds), `e2e-docker` (fullstack Docker build + runtime), `e2e-json-server` (live API integration). All E2E jobs run in parallel after `build`. Triggers on push to `main`/`feature/**`/`bugfix**` and PRs to `main`. Concurrency groups auto-cancel superseded runs.

Release workflow (`.github/workflows/release.yml`): triggers on `v*` tag push — builds fat JAR, creates GitHub Release with ZIP archive, builds and pushes Docker image to GHCR.

## Git

Branch naming: `feature/<name>` or `bugfix/<name>` → PR to `main`.
