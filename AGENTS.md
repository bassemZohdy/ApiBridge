# AGENTS.md

## Build

- Java 21 (JDK 21 required — `maven.compiler.release=21`).
- Single Maven module: `apibridge-generator/`. Cartridges under `apibridge-cartridges/` are **not** Maven modules — they are plain directories of `.ftl` FreeMarker templates.
- Fat JAR via `maven-shade-plugin`; main class: `com.apibridge.engine.ApiBridgeRunner`.
- Output JAR: `apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar`.

```bash
mvn clean package            # build fat JAR (skips tests)
mvn test                     # unit tests only (fast)
mvn verify                   # unit tests + Checkstyle + JaCoCo report
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

- **Engine entry point**: `ApiBridgeRunner.main()` — CLI arg parser, calls `YamlParser.parse()` then `ApiBridgeCartridgeEngine.generate()` per cartridge.
- **Model**: `BridgeSchemaModel` (in `.model` subpackage) — Jackson-deserialized from YAML. Contains `Flags` (with defaults: `backendFlavor="spring-boot"`), `Pagination`, `Endpoint`, `UiLayout`, `Field`, `Column`. Full Javadoc on all classes and fields.
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
| `flags` | Flags | May be `null` — always null-check |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | `spring-boot` or `quarkus` (never null, defaults to `spring-boot`) |
| `feFlavor` | String | `react`, `angular`, `vue`, or `""` if unset |
| `deployTarget` | String | `docker-compose`, `kubernetes`, `openshift`, or `""` |

Gate FE-specific content with: `(feFlavor!"") != ""`.

## Running the generator

```bash
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/backend/spring-boot \
  --cartridge=apibridge-cartridges/frontend/react \
  --output=output/my-app
```

CLI overrides take precedence over schema `flags`: `--be-flavor=`, `--fe-flavor=`, `--deploy-target=`, `--security-level=`.

## E2E tests

- Script: `./e2e-tests/run-all-e2e.sh` (bash — requires Linux/macOS or WSL).
- Set `SKIP_GENERATOR_BUILD=true` to skip rebuilding the JAR (used in CI).
- Suites: Spring Boot compile, Quarkus compile, Angular/React/Vue strict TypeScript compile, React production build, contract symmetry, Kubernetes manifest validation, OpenShift manifest validation, fullstack Docker, json-server integration (11 suites total).
- **Slow** — run on CI/PR only, not before every local commit.
- Individual suite: e.g. `./e2e-tests/maven-spring-boot-test/run-e2e.sh`.

## Adding a cartridge

1. Create a directory under `apibridge-cartridges/`. Its path is the `--cartridge=` value.
2. Add `.ftl` files. Directory tree mirrors 1:1 to output; `.ftl` suffix is stripped.
3. Add unit tests in `ApiBridgeCartridgeEngineTest` to verify generation.
4. Add an E2E suite under `e2e-tests/` and wire it into `run-all-e2e.sh` and `.github/workflows/ci.yml`.

## Schema quick reference

Required fields: `id`, `basePath`, `endpoints` (non-empty list, each with `path`, `method`, `backendUrl`).

Valid `flags` enums:
- `backendFlavor`: `spring-boot` | `quarkus`
- `feFlavor`: `angular` | `react` | `vue`
- `securityLevel`: `bearer-token` | `apiKey`
- `deployTarget`: `docker-compose` | `kubernetes` | `openshift`
- `endpoints[].uiLayout.component`: `Form` | `List` | `View` (case-insensitive)
- `endpoints[].uiLayout.fields[].type` (for Form components): `string` | `number` | `integer` | `boolean` | `email` | `date` | `url` | `password` — maps to HTML input types; `email` adds pattern validation

HTTP methods allowed: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`. Duplicate endpoints (same path + method) are rejected.

Full reference: `docs/schema-reference.md`.

## CI

GitHub Actions (`.github/workflows/ci.yml`): `build` (mvn verify) → `e2e-compile` (compile checks + K8s/OpenShift manifest validation + React prod build) → `e2e-docker` (fullstack Docker build + runtime) → `e2e-json-server` (live API integration). Triggers on push to `main`/`feature/**`/`bugfix**` and PRs to `main`.

## Git

Branch naming: `feature/<name>` or `bugfix/<name>` → PR to `main`.
