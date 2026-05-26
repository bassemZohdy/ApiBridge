---
name: add-cartridge
description: Step-by-step workflow for creating a new ApiBridge cartridge — directory structure, FreeMarker template conventions, schema model bindings, and wiring E2E tests. Use when adding a new target platform (backend or frontend).
disable-model-invocation: true
---

# Adding a New ApiBridge Cartridge

A cartridge is a plain directory of `.ftl` FreeMarker templates. No Maven module or build config needed.

## 1. Create the cartridge directory

```bash
mkdir apibridge-cartridges/$ARGUMENTS
```

Name it descriptively: `backend-<framework>` or `frontend-<framework>`.

## 2. Write `.ftl` templates

- Each file in the directory becomes a generated output file (`.ftl` suffix is stripped).
- FreeMarker template root is the cartridge directory itself — no sub-paths needed for `<#include>`.
- The FreeMarker context exposes the full `BridgeSchemaModel`:
  - `${id}` — service identifier (kebab-case)
  - `${basePath}` — REST base path
  - `${flags.backendFlavor}`, `${flags.uiPattern}`, `${flags.securityLevel}`, `${flags.enableTelemetry}`
  - `<#list endpoints as ep>` — iterate endpoints (each has: `path`, `method`, `backendUrl`, `telemetryName`, `uiLayout`)
  - `<#list ep.uiLayout.fields as field>` — iterate UI fields (each has: `name`, `type`, `required`)

**Useful FreeMarker patterns already established in existing cartridges:**
- PascalCase from kebab-case: `${id?replace("-", " ")?capitalize?replace(" ", "")}`
- Conditional telemetry: `<#if flags.enableTelemetry>...</#if>`
- UI pattern branching: `<#if (flags.uiPattern!"form-engine") == "form-engine">...</#if>`
- Escaping `$` in generated JS/TS: `${"$"}{someVar}`

## 3. Test manually

```bash
mvn clean package
java -jar apibridge-generator/target/apibridge-generator-0.1.0-SNAPSHOT.jar \
  --schema=sample-schema.yaml \
  --cartridge=apibridge-cartridges/$ARGUMENTS \
  --output=output/$ARGUMENTS
```

Inspect `output/$ARGUMENTS/` to verify generated files look correct.

## 4. Wire an E2E test (if compilation verification is needed)

- Copy the closest existing E2E suite under `e2e-tests/` as a template.
- Update `run-e2e.sh` to generate from the new cartridge and compile the output.
- Add the new E2E call to `e2e-tests/run-all-e2e.sh`.

## 5. Update `sample-schema.yaml` if needed

If the new cartridge uses schema fields not present in the sample, add representative values to `sample-schema.yaml` so manual and E2E tests exercise the full template.
