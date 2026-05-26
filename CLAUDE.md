# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build fat JAR
mvn clean package

# Run generator (all three flags required)
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=<path-to-schema.yaml> \
  --cartridge=apibridge-cartridges/<cartridge-name> \
  --output=<output-dir>

# Optional overrides (take precedence over schema flags)
  --be-flavor=spring-boot        # spring-boot | quarkus
  --fe-flavor=react              # angular | react | vue
  --deploy-target=docker-compose # docker-compose | kubernetes | openshift
```

## Testing & Linting

- Unit tests: `mvn test` — run freely during development
- Lint: `mvn verify` — runs Checkstyle (4-space indent, no star/unused imports, braces required); also runs unit tests
- E2E tests: `./e2e-tests/run-all-e2e.sh` — run on CI/PR only, not before every local commit (slow; compiles generated Spring Boot, Quarkus, and TypeScript output)

## Cartridge Architecture

Cartridges are **plain directories of `.ftl` FreeMarker templates** — they are NOT Maven modules and have no build config. Adding a cartridge means creating a new directory under `apibridge-cartridges/` with `.ftl` files.

- FreeMarker template root = the cartridge directory (no nested package structure)
- Generated file names strip the `.ftl` suffix: `Controller.java.ftl` → `Controller.java`
- All templates in a cartridge are processed in a single pass; FreeMarker context is bound once from the parsed `BridgeSchemaModel`
- **Subdirectory routing**: directories named `backend-{flavor}/` and `frontend-{flavor}/` are only entered when the model's `backendFlavor`/`feFlavor` matches; their content maps to `backend/` and `frontend/` in the output. All other directories recurse normally.
- **`fullstack` cartridge** (`apibridge-cartridges/fullstack`): generates a self-contained project with a three-stage multi-stage `Dockerfile` (node:20-alpine FE build → maven:3.9-amazoncorretto-21-alpine BE build → amazoncorretto:21-alpine runtime). The generated app exposes port 8080; `MOCK_MODE=true` returns canned responses, `BLOCK_TRAFFIC=true` returns 503.

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
