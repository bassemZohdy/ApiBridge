# Changelog

All notable changes to **ApiBridge** are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Changed — Cartridge layout finalised

- **`frontend-ui-schema/` renamed to `frontend/ui-schema/`**: now grouped under `frontend/` alongside Angular/React/Vue. Output auto-prefixed to `frontend/UiLayoutSchema.json` by the engine prefix convention.
- **`devops/kubernetes/` and `devops/openshift/` collapsed under `devops/k8s/`**: new paths are `devops/k8s/kubernetes/` and `devops/k8s/openshift/`. Cartridge templates sit directly in these directories (no inner `k8s/` subdirectory); the engine auto-prefixes their output to `k8s/`.
- **`backend/` and `frontend/` inner subdirectories removed from all cartridges**: templates now live directly under `backend/<flavor>/` and `frontend/<flavor>/`. The engine auto-prefixes output via the `OUTPUT_PREFIX_CATEGORIES` convention instead of requiring the inner directory.
- **Engine `OUTPUT_PREFIX_CATEGORIES` extended to `{backend, frontend, k8s}`**: any cartridge whose immediate parent directory matches one of these names has its output rooted at `<outputDir>/<category>/`.

### Changed — Composable cartridge architecture

- **Cartridge directory restructured**: `spring-boot/` → `backend/spring-boot/`, `quarkus/` → `backend/quarkus/`, `angular/` → `frontend/angular/`, `react/` → `frontend/react/`, `vue/` → `frontend/vue/`; `dockerfile/`, `docker-compose/` moved under `devops/`; `kubernetes/` → `devops/k8s/kubernetes/`, `openshift/` → `devops/k8s/openshift/`.
- **Standalone component-only cartridges removed** (`frontend-angular/`, `frontend-react/`, `frontend-vue/`): the full-project cartridges (`frontend/angular`, `frontend/react`, `frontend/vue`) supersede them.
- **Monolithic `fullstack/` cartridge removed**: replaced by independent composable cartridges applied via repeatable `--cartridge=` flag.
- **`backend-spring-boot/` and `backend-quarkus/` removed**: superseded by `backend/spring-boot` and `backend/quarkus`.
- **Engine rewritten**: `ApiBridgeCartridgeEngine` now mirrors each cartridge's directory tree 1:1 to the output with no flavor-based subdirectory routing. Multiple cartridges compose by applying to the same output directory.
- **`--cartridge=` is repeatable**: `ApiBridgeRunner` accepts multiple `--cartridge=` arguments, applying each in order.
- **`feFlavor` default changed to null**: absence of FE flavor is now detectable in templates via `(feFlavor!"") != ""`; the Dockerfile FE build stage and static-resource properties are gated on this.
- **E2E tests updated**: Maven backend tests compile the generated `backend/pom.xml` directly; TypeScript tests run on full generated `frontend/` projects; contract symmetry check uses schema-derived paths.

### Fixed — E2E template and script correctness

- **Angular `package.json.ftl`**: added missing `@ngx-formly/bootstrap` dependency (imported in `app.module.ts` but absent from `package.json`).
- **React `tsconfig.json.ftl`**: added `"types": ["vite/client"]` so `import.meta.env` resolves under strict TypeScript.
- **React `ApiBridgeForm.tsx.ftl`**: cast RJSF v5 `AJV8Validator` to `any` to satisfy `Form`'s `ValidatorType` generic constraint under `strict: true`.
- **Vue `tsconfig.json.ftl`**: added `"types": ["vite/client"]`; new `src/vite-env.d.ts.ftl` declares `.vue` module types so `import './ApiBridgeForm.vue'` resolves under strict TypeScript.
- **`verify-contract-symmetry.sh`**: fixed schema path (`../../` → `../`); replaced `mapfile` (bash 4+) with `while read` for macOS bash 3.2 compatibility; fixed endpoint grep pattern (`'    path:'` → `'^\s*- path:'`).
- **`docker-fullstack-test/run-e2e.sh`**: fixed empty-array expansion (`"${extra_args[@]}"` → `${extra_args[@]+"${extra_args[@]}"}`) under `set -u` on bash 3.2.
- **`run-all-e2e.sh`**: builds the generator JAR once up front and exports `SKIP_GENERATOR_BUILD=true` to all sub-scripts, eliminating 7 redundant Maven builds per suite run.

### Removed — Stale e2e test harness

- Deleted leftover per-test `pom.xml`, `package.json`, `tsconfig.json`, `package-lock.json`, and `src/` source files from `e2e-tests/maven-*/` and `e2e-tests/typescript-*/`. These were scaffolding from the old single-compile approach; the current e2e tests compile the generated output directly.

### Added — Previous unreleased
- **Fullstack Docker cartridge** (`apibridge-cartridges/fullstack`): generates a complete, self-contained app with a three-stage multi-stage `Dockerfile` (node:20-alpine FE build → maven:3.9-amazoncorretto-21-alpine BE build → amazoncorretto:21-alpine runtime). The generated backend proxies all schema endpoints, with `MOCK_MODE` and `BLOCK_TRAFFIC` ENV flags for runtime control.
- **Frontend flavor selection** (`flags.feFlavor`): new validated schema field (`angular` | `react` | `vue`). Defaults to `react`. Validated by `YamlParser` at parse time (case-insensitive).
- **Subdirectory-routed cartridge engine**: `ApiBridgeCartridgeEngine` now performs a recursive scan with flavor-directory routing — `backend-{flavor}/` and `frontend-{flavor}/` directories are only entered when the schema's `backendFlavor`/`feFlavor` matches; their output maps to `backend/` and `frontend/`. All other directories recurse normally. Empty rendered output is silently skipped.
- **Deployment target selection** (`flags.deployTarget`): new validated schema field (`docker-compose` | `kubernetes` | `openshift`). When set, generates deployment configuration files alongside the project code (docker-compose.yml; or k8s/ manifests with Deployment, Service, ConfigMap, Kustomization, and OpenShift Route). When absent, only project code and Dockerfile are generated. CLI override `--deploy-target` takes precedence over schema.
- **CLI flavor overrides**: `--be-flavor`, `--fe-flavor`, and `--deploy-target` arguments added to `ApiBridgeRunner`. They take precedence over schema flags.
- **FreeMarker context map**: engine now exposes `feFlavor`, `backendFlavor`, and `deployTarget` as top-level template variables alongside the full model object.
- **Fullstack Spring Boot backend templates**: `Application.java`, `BridgeController.java` (HTTP method shortcuts, proxy/mock/block logic), `ProxyService.java` (RestTemplate, header passthrough), `pom.xml` (spring-boot-starter-parent 3.2.5), `application.properties`.
- **Fullstack Quarkus backend templates**: `BridgeResource.java` (JAX-RS, `@ConfigProperty`, path-derived method names), `ProxyService.java` (JAX-RS Client, `@ApplicationScoped`), `pom.xml` (Quarkus platform BOM 3.9.4, uber-jar), `application.properties`.
- **Fullstack Angular frontend templates** (11 files): `package.json`, `angular.json`, `tsconfig.json`, `index.html`, `main.ts`, `app.module.ts`, `app.component.ts/html`, `bridge-api.service.ts`, `bridge-form.component.ts/html`. Supports both `form-engine` (ngx-formly) and `web-component` rendering modes.
- **Fullstack React frontend templates** (7 files): `package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`, `main.tsx`, `bridgeApi.ts`, `ApiBridgeForm.tsx`. RJSF for `form-engine`, `useRef`/`useEffect` web-component integration.
- **Fullstack Vue frontend templates** (7 files): `package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`, `main.ts`, `bridgeApi.ts`, `ApiBridgeForm.vue`. Reactive `form-engine` with typed fields, `web-component` with `onMounted` listener.
- **Fullstack Docker E2E test** (`e2e-tests/docker-fullstack-test/run-e2e.sh`): 8-stage test — (1) builds generator JAR, (2) verifies no deployment configs generated when `deployTarget` absent, (3) verifies conditional `docker-compose.yml` with `--deploy-target=docker-compose`, (4–5) verifies backend/frontend file structure, (6) Docker build, (7) container runtime test with `MOCK_MODE=true` — polls health, asserts `"status":"mock"` response, (8) container runtime test with `BLOCK_TRAFFIC=true` — asserts 503. Docker stages auto-skipped if daemon unavailable. Integrated into `run-all-e2e.sh` as step 7.
- **GitHub Actions CI** (`.github/workflows/ci.yml`): two-job pipeline — `build` (`mvn verify` on JDK 21) and `e2e` (full E2E suite including Docker build). Triggers on push to `main`/`feature**`/`bugfix**` and PRs to `main`.
- **Checkstyle** (`apibridge-generator/checkstyle.xml`): 4-space indent, naming conventions, no star/unused imports, braces required. Bound to `mvn verify`; 0 violations on all sources.
- **Schema reference documentation** (`docs/schema-reference.md`): complete field reference with types, valid values, defaults, and validation rules.
- **CLAUDE.md project instructions**: persistent guidance for Claude Code sessions covering build commands, cartridge architecture, schema enum values, and git workflow.
- **Engine routing unit tests**: five new tests covering `testFlavorDirSelectionPicksMatchingBeDir`, `testFlavorDirSelectionSkipsMismatchedFeDir`, `testOutputPathMappingStripsFlavorPrefix`, `testSkipsEmptyRenderedOutput`, and `testRootTemplatesStillOutputToRoot`.
- **YamlParser unit tests**: 36 tests covering all validation paths — null/missing/directory/malformed file input, required field presence, all flags enum validation (including blank values and case-insensitivity for all four enum flags), endpoint validation for all required fields (null and blank), second-endpoint index in error messages, uiLayout/field validation, uiLayout with null fields, and happy-path cases.
- **Engine unit tests**: 23 tests covering input guard contracts (null model, null/missing/file cartridge dir, null output dir), empty cartridge error, output dir auto-creation, `deployTarget` FreeMarker context (conditional skip when absent, conditional render when set), and default BE/FE flavor routing when `flags` is null.
- Total test suite: **59 tests, 0 failures**.

### Changed
- `ApiBridgeCartridgeEngine.generate()` rewritten from a flat directory scan to a recursive scan with subdirectory routing and conditional flavor-directory inclusion.
- FreeMarker context changed from a direct PIM POJO to a `HashMap<String, Object>`, allowing top-level `feFlavor` and `backendFlavor` shortcuts alongside the full model.

### Removed
- `apibridge-generator/src/main/resources/templates/` — old pre-cartridge built-in templates (`Controller.java.ftl`, `BuildConfiguration.xml.ftl`, `UiLayoutSchema.json.ftl`) superseded by the standalone and fullstack cartridges.
- Committed E2E runtime artifacts from `e2e-tests/*/generated/` and `e2e-tests/*/src/main/java/CustomerOnboarding*.java` (now gitignored).

---

## [0.1.0-SNAPSHOT] — 2026-05-26 (initial)

### Added
- Core engine: `ApiBridgeRunner` (CLI), `ApiBridgeCartridgeEngine` (flat single-pass scan), `YamlParser` (YAML→PIM with validation), `BridgeSchemaModel` (PIM domain model).
- Standalone cartridges: `backend-spring-boot`, `backend-quarkus`, `frontend-ui-schema`, `frontend-angular`, `frontend-react`, `frontend-vue`.
- E2E test suite: Maven compile verification for Spring Boot and Quarkus; TypeScript compile verification for Angular, React, and Vue; backend-frontend contract symmetry check.
- Multi-module Maven reactor POM with `maven-shade-plugin` fat JAR packaging.
- Schema validation: `id`, `basePath`, `endpoints` required; `backendFlavor` enum; `uiPattern` enum; telemetry-name conditional requirement; uiLayout field validation.
