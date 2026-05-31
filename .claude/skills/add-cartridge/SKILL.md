---
name: add-cartridge
description: Step-by-step workflow for creating a new ApiBridge cartridge — directory structure, FreeMarker template conventions, schema model bindings, and wiring E2E tests. Use when adding a new target platform (backend, frontend, or devops).
disable-model-invocation: true
---

# Adding a New ApiBridge Cartridge

A cartridge is a plain directory of `.ftl` FreeMarker templates. No Maven module or build config needed.

## 1. Create the cartridge directory

Place the cartridge under the appropriate category:

```
apibridge-cartridges/backend/<name>/      # outputs to backend/ in generated project
apibridge-cartridges/frontend/<name>/     # outputs to frontend/ in generated project
apibridge-cartridges/devops/<name>/       # outputs directly to generated project root
apibridge-cartridges/devops/k8s/<name>/   # outputs to k8s/ in generated project
apibridge-cartridges/docs/<name>/         # outputs docs files (e.g. openapi.yaml)
```

The engine automatically prefixes output with the parent directory name when it is `backend`, `frontend`, or `k8s`. Cartridges under other parents (e.g. `devops/dockerfile`) output directly to the root.

```bash
mkdir -p apibridge-cartridges/$ARGUMENTS
```

## 2. Write `.ftl` templates

- Each `.ftl` file becomes one generated output file (`.ftl` suffix stripped).
- Directory tree is mirrored 1:1 to output — no inner `backend/` or `frontend/` subdirectory needed.
- FreeMarker context variables:

| Variable | Type | Notes |
|---|---|---|
| `id` | String | Service identifier (kebab-case) |
| `basePath` | String | REST base path |
| `flags` | Flags | Always non-null — runner synthesises `new Flags()` when `flags:` absent in schema. Use field-level guards (`flags.securityLevel??`), not `flags??`. |
| `endpoints` | List\<Endpoint\> | All endpoint definitions |
| `backendFlavor` | String | `spring-boot` or `quarkus` (never null) |
| `feFlavor` | String | `react`, `angular`, `vue`, or `""` if unset |
| `deployTarget` | String | `docker-compose`, `kubernetes`, `openshift`, or `""` |
| `enableRateLimiter` | boolean | Top-level convenience variable; `false` when flag off |
| `enableTransform` | boolean | Top-level convenience variable; `false` when flag off |
| `enableHealthCheck` | boolean | Top-level convenience variable; `false` when flag off |
| `enableSearch` | boolean | Top-level convenience variable; `false` when flag off |
| `enableOfflineSupport` | boolean | Top-level convenience variable; `false` when flag off |
| `enableOpenApi` | boolean | Top-level convenience variable; `false` when flag off |
| `enableOidc` | boolean | Top-level convenience variable; `false` when flag off |
| `oidcIssuerUri` | String | OIDC issuer URL; only meaningful when `enableOidc` is true |
| `apiVersion` | String | Global version prefix (e.g. `"v1"`); `""` when unset |

**Useful FreeMarker patterns:**
- PascalCase from kebab-case: `${id?replace("-", " ")?capitalize?replace(" ", "")}`
- Gate on FE presence: `<#if (feFlavor!"") != "">`
- Conditional flag: `<#if (flags.enableTelemetry)!false>`
- Escaping `${...}` in generated JS/TS template literals: `${r"${someVar}"}` — use the raw-string pattern, not `${"$"}`
- Helm `{{ }}` expressions in templates: `${r"{{ .Values.foo }}"}`

## 3. Test manually

```bash
java -jar apibridge-generator/target/apibridge-generator-0.1.0.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/$ARGUMENTS \
  --output=output/test-$ARGUMENTS
find output/test-$ARGUMENTS -type f | sort
```

## 4. Add unit tests

Create a test class in `apibridge-generator/src/test/java/com/apibridge/engine/` extending `ApiBridgeCartridgeEngineTestBase`. Name it `<FeatureName>EngineTest`. Use `writeFtl()` and `findCartridgeDir()` from the base class.

## 5. Wire an E2E test (if compilation verification is needed)

- Copy the closest existing E2E script under `e2e-tests/` as a template.
- Generate from the new cartridge and compile/type-check the output.
- Add the new step to `e2e-tests/run-all-e2e.sh` and `.github/workflows/ci.yml`.

## 6. Update documentation

- Add the cartridge to the table in `README.md`.
- Add the path to the cartridge list in `CLAUDE.md`.
- Add an entry to `CHANGELOG.md`.
