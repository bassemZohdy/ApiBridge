# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build fat JAR
mvn clean package

# Run generator — apply one or more cartridges to same output dir
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=<path-to-schema.yaml> \
  --cartridge=apibridge-cartridges/spring-boot \
  --cartridge=apibridge-cartridges/react \
  --cartridge=apibridge-cartridges/dockerfile \
  --cartridge=apibridge-cartridges/docker-compose \
  --output=<output-dir>

# Optional overrides (take precedence over schema flags)
  --be-flavor=spring-boot        # spring-boot | quarkus
  --fe-flavor=react              # angular | react | vue (omit for BE-only)
  --deploy-target=docker-compose # docker-compose | kubernetes | openshift
```

## Testing & Linting

- Unit tests: `mvn test` — run freely during development
- Lint: `mvn verify` — runs Checkstyle (4-space indent, no star/unused imports, braces required); also runs unit tests
- E2E tests: `./e2e-tests/run-all-e2e.sh` — run on CI/PR only, not before every local commit (slow; compiles generated Spring Boot, Quarkus, and TypeScript output)

## Cartridge Architecture

Cartridges are **independent, composable directories of `.ftl` FreeMarker templates**. Each addresses one concern; the engine applies them in sequence to the same output directory. There are no cross-cartridge dependencies.

- FreeMarker template root = the cartridge directory; directory tree is mirrored 1:1 to output
- Generated file names strip the `.ftl` suffix: `BridgeController.java.ftl` → `BridgeController.java`
- All templates in a cartridge are processed in a single pass; FreeMarker context is bound once from the parsed `BridgeSchemaModel`
- **`--cartridge=` is repeatable**: each cartridge is applied to the same output dir in order, enabling composition (e.g. `spring-boot` + `react` + `dockerfile` + `kubernetes`)
- **Available cartridges** under `apibridge-cartridges/`:
  - `spring-boot` / `quarkus` — backend source under `backend/`; Spring Boot serves FE static assets from `classpath:/static/`, Quarkus from `META-INF/resources/`
  - `angular` / `react` / `vue` — full FE project under `frontend/` (for embedding in the JAR via multi-stage Dockerfile)
  - `dockerfile` — multi-stage `Dockerfile`; FE build stage is conditional on `feFlavor` being set
  - `docker-compose` — `docker-compose.yml`
  - `kubernetes` — kustomization + deployment + service + configmap under `k8s/`
  - `openshift` — adds `route.yaml` and overrides `kustomization.yaml` (apply on top of `kubernetes`)
  - `frontend-angular` / `frontend-react` / `frontend-vue` — standalone component-only output (no full project scaffold)
  - `frontend-ui-schema` — generates `UiLayoutSchema.json` for UI-driven forms
- **Single deployable JAR**: the generated project is one unit. FE source lives in `frontend/`, BE in `backend/`, but the multi-stage Dockerfile compiles FE and copies the dist into the BE `static/` resources directory before the Maven build, producing a single runnable JAR.

## YAML Schema

Full reference: @docs/schema-reference.md

Required fields (validated by `YamlParser`): `id` (non-empty), `basePath` (non-empty), `endpoints` (non-empty list).

Valid enum values:
- `flags.backendFlavor`: `spring-boot` | `quarkus`
- `flags.feFlavor`: `angular` | `react` | `vue`
- `flags.uiPattern`: `form-engine` | `web-component`
- `flags.securityLevel`: `bearer-token` | `apiKey`
- `flags.deployTarget`: `docker-compose` | `kubernetes` | `openshift` (absent = no deployment config generated)

## Git Workflow

Branch naming: `feature/<name>` or `bugfix/<name>` → PR to `main`.
