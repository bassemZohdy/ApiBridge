# Changelog

All notable changes to **ApiBridge** are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) — Versioning: [SemVer](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Fixed — Compile-breaking and runtime bugs (BUG-1 to BUG-13)

- **BUG-1**: Removed duplicate React `ApiBridgeView` component (old View without DELETE left as dead code).
- **BUG-2**: Removed duplicate Angular `bridge-view.component.ts` class.
- **BUG-3**: Fixed unescaped `${this.recordId}` in Angular View FreeMarker template.
- **BUG-4**: Fixed uninitialized `upstream` variable in Quarkus `ProxyService` `finally` block (Java compile error).
- **BUG-5**: Fixed unescaped `${id}` in React `ApiBridgeList` row-click handler (navigated to service ID instead of row ID).
- **BUG-6**: Fixed broken URL construction in Angular `bridge-list.component.ts`.
- **BUG-7**: Spring Boot error responses now use `Content-Type: application/json` (was `text/plain`).
- **BUG-8**: Auth `RestTemplate` now has 5s connect / 10s read timeouts (was unbounded).
- **BUG-9**: Quarkus auth `Response` from bearer validation now properly closed (connection leak).
- **BUG-10**: Angular Form now has Back button and `@Output() navigate`.
- **BUG-11**: CORS now includes `exposedHeaders("*")` and `maxAge(3600)` — upstream headers (e.g. `X-Total-Count`) visible to frontend JS.
- **BUG-12**: Telemetry spans now set `StatusCode.ERROR` on exceptions.
- **BUG-13**: All `flags` accesses are null-safe — templates handle missing `flags:` section without crashing.

### Changed — Consistency and cleanup (M1–M16)

- **M1/M2**: Removed `navigationMode` and `uiPattern` from entire codebase (model, parser, templates, tests, schemas, docs).
- **M3**: `/api/bridge-config` now returns `securityLevel`, `basePath`, `enableTelemetry`, `customCssPath` (in addition to pagination).
- **M4**: CORS aligned between backends: `allowCredentials`, `maxAge(3600)`, `exposedHeaders("*")`.
- **M5**: DevOps templates now include all `PAGINATION_*` and `CUSTOM_CSS_PATH` env vars.
- **M6**: Removed unused imports (Angular `HttpHeaders`, `BridgeApiService`; Quarkus `java.util.List`).
- **M7**: Removed dead code (Vue `pathToMethod` FreeMarker function, unused `axios` dependency).
- **M8**: Aligned mock-mode method case to uppercase in both backends.
- **M9**: Quarkus FE static resource config is conditional on `feFlavor` with 365d cache headers.
- **M10**: Angular list/view use `BridgeApiService.getAuthHeaders()` consistently.
- **M11**: `UiLayoutSchema.json.ftl` now includes `columns` array and `field.label`.
- **M12**: Fixed `feFlavor` default documentation (no default, not `react`).
- **M13**: Quarkus `BridgeConfigResource` has `@ApplicationScoped`.
- **M14**: Quarkus `pom.xml.ftl` has `<name>` and `<description>`.
- **M15**: Angular `styles.css.ftl` has `.apib-spinner--dark` variant.
- **M16**: Vue `ApiBridgeView.vue.ftl` has `<style scoped>` section.

### Added — Schema and engine improvements (S1–S6)

- **S1**: HTTP method validation — only `GET`, `POST`, `PUT`, `DELETE`, `PATCH` allowed.
- **S2**: Case-insensitive `uiLayout.component` validation.
- **S3**: CLI override `--security-level=` added to `ApiBridgeRunner`.
- **S4**: Duplicate endpoint detection — same `path` + `method` rejected.
- **S5**: Proxy timeouts configurable via `PROXY_CONNECT_TIMEOUT` / `PROXY_READ_TIMEOUT` env vars.
- **S6**: `BridgeSchemaModel` has full Javadoc on all classes and fields.

### Testing — CI and E2E fixes (L3, L5, L6)

- **L3**: CI wired with `e2e-json-server` job in `.github/workflows/ci.yml`.
- **L5**: Vue E2E uses `vue-tsc` instead of `tsc`.
- **L6**: Fixed `run-all-e2e.sh` step numbering.

### Fixed — Frontend API method naming collision

- All 3 frontend `bridgeApi` templates (`bridgeApi.ts.ftl` for React/Vue, `bridge-api.service.ts.ftl` for Angular) now generate unique method names by combining HTTP method prefix + path segments + "By" suffix for path params. Previously, `GET /submissions` and `GET /submissions/{id}` both produced `submissions()` — a TypeScript compile error due to duplicate function declarations.

### Added — Edit-mode pre-population (H3)

- All 3 frontend Form components now pre-populate fields when `editId` is provided (navigating to `#/form/:id`). The component fetches the record from the View GET endpoint and fills the form state.
- Angular `app.component.html.ftl` now passes `[editId]="currentId"` to `<app-bridge-form>`.
- Form title changes to "Edit Record" and submit button to "Update Record" in edit mode.
- Loading spinner shown while fetching the record for editing.

### Added — Bearer-token security on backend (H4)

- Both `BridgeController.java.ftl` (Spring Boot) and `BridgeResource.java.ftl` (Quarkus) now validate `Authorization: Bearer <token>` headers when `securityLevel` is `"bearer-token"`.
- Configurable via `AUTH_SERVER_URL` env var: if set, the backend calls the auth server to validate the JWT; if empty, it performs a pass-through check (header must be present and non-empty).
- `AUTH_SERVER_URL` documented in `application.properties.ftl`, `docker-compose.yml.ftl`, `Dockerfile.ftl`, and `configmap.yaml.ftl`.

### Added — Quarkus telemetry (H5)

- `BridgeResource.java.ftl` now generates OpenTelemetry spans for each endpoint when `enableTelemetry` is true. Matches the Spring Boot telemetry implementation with `spanBuilder`, `setAttribute("http.method", ...)`, `setAttribute("http.url", ...)`, `recordException`, and proper `Scope` management.

### Fixed — Angular View FreeMarker escaping

- `bridge-view.component.ts.ftl`: escaped `${token}` as `${r"${token}"}` in two JS template literals that caused `InvalidReferenceException` at generation time.

### Fixed — Critical template and proxy bugs

- **C1**: Added `getAuthHeaders()` export to React and Vue `bridgeApi.ts.ftl`. Previously, `ApiBridgeList` and `ApiBridgeView` imported a non-existent function, causing compile failure when `securityLevel` was set.
- **C2**: Fixed GET+body bug in all 3 frontend API layers. React `axios.get(url, body, config)` misinterpreted body as config; Angular `http.get(url, body)` misinterpreted body as options; Vue `fetch` silently ignored body on GET. All three now conditionally omit body for GET/DELETE requests.
- **C3**: Fixed Angular Form component hardcoding empty strings for security credentials. Now reads token from `localStorage.getItem('token')` (same as List/View components), consistent with the `BridgeApiService.getAuthHeaders()` pattern.
- **C4**: Fixed method name collision in both backend cartridges. Method names now include the HTTP method prefix (e.g. `getUsers()`, `postUsers()`) instead of deriving from path alone, preventing compile errors when multiple methods share the same path.
- **H1**: Forwarded query parameters in both `ProxyService` templates. Spring Boot appends `request.getQueryString()`; Quarkus appends `uriInfo.getRequestUri().getRawQuery()`. Pagination, filtering, and sorting now reach the upstream backend.
- **H6**: Both `ProxyService` templates now forward all upstream response headers (excluding hop-by-hop headers), enabling REST pagination headers like `X-Total-Count` to pass through.
- **M5**: Aligned header forwarding between backends. Both ProxyService templates now forward all request headers excluding a standard hop-by-hop set, replacing the previous inconsistent allow-list approach.
- **M6**: Both `ProxyService` templates now return a generic `{"error":"Bad Gateway"}` instead of leaking `ex.getMessage()` in 502 responses.

### Added — DELETE support in View components

- **React `ApiBridgeView.tsx.ftl`**, **Vue `ApiBridgeView.vue.ftl`**, **Angular `bridge-view.component.ts.ftl` + `.html.ftl`**: View components now detect DELETE endpoints and render a "Delete" button with `window.confirm()` confirmation. On success, navigates back to the list page. Includes loading state ("Deleting…") and error handling.

### Added — Centralized auth helper in Angular

- **Angular `bridge-api.service.ts.ftl`**: Added `getAuthHeaders()` method (matching React/Vue pattern). Bearer-token reads from parameter; apiKey reads from `localStorage`. All endpoint methods now use `http.request(method, url, { body?, headers })` for correct GET vs POST/PUT handling.

### Fixed — Form templates filter GET endpoints

- **`ApiBridgeForm.tsx.ftl` (React), `bridge-form.component.ts.ftl` (Angular), `ApiBridgeForm.vue.ftl` (Vue)**: added `formEndpoints` filter at template top (`endpoints.filter(ep -> method != "GET")`). Form components now correctly ignore List/View GET endpoints when building `FIELD_DEFS`, `INITIAL_STATE`, tab labels, and submit handlers. Previously crashed with a null `field.type` when a schema contained View endpoints with typeless fields.

### Fixed — json-server E2E cartridge selection

- **`e2e-tests/json-server-test/run-e2e.sh`**: `run_combination` now accepts explicit `be_cartridge` and `fe_cartridge` parameters instead of hard-coding Spring Boot + React for both combinations. The Quarkus + Vue combination now correctly uses the Quarkus and Vue cartridges.

### Added — Comprehensive sample schema

- **`sample-schema.yaml`** extended to include all three page types (List, View, Form) with schema-defined columns, labels, and pagination configuration. All E2E compile tests (Angular, React, Vue) now exercise the List and View templates in addition to Form.

### Added — Test coverage for new model fields

- **`YamlParserTest`**: 10 new tests covering `Pagination` defaults/custom/negative-size validation, `Column` parsing/field-required validation, View component fields without `type`, and optional `Field.label`.
- **`ApiBridgeCartridgeEngineTest`**: 3 new integration tests (`testReactCartridgeWithListViewForm`, `testAngularCartridgeWithListViewForm`, `testVueCartridgeWithListViewForm`) verifying that List, View, and Form pages all generate correctly from a multi-endpoint model.
- Total unit tests: **85** (up from 72).

### Fixed — `BridgeSchemaModel.Flags` Pagination initialization

- `Pagination pagination` field now initialized to `new Pagination()` by default. `getPagination()` is never null when `flags` is non-null, consistent with how other flag fields behave.

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
- **Fullstack Angular frontend templates** (11 files): `package.json`, `angular.json`, `tsconfig.json`, `index.html`, `main.ts`, `app.module.ts`, `app.component.ts/html`, `bridge-api.service.ts`, `bridge-form.component.ts/html`. Dynamic form engine with ngx-formly.
- **Fullstack React frontend templates** (7 files): `package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`, `main.tsx`, `bridgeApi.ts`, `ApiBridgeForm.tsx`. RJSF form engine.
- **Fullstack Vue frontend templates** (7 files): `package.json`, `vite.config.ts`, `tsconfig.json`, `index.html`, `main.ts`, `bridgeApi.ts`, `ApiBridgeForm.vue`. Reactive form engine with typed fields.
- **Fullstack Docker E2E test** (`e2e-tests/docker-fullstack-test/run-e2e.sh`): 8-stage test — (1) builds generator JAR, (2) verifies no deployment configs generated when `deployTarget` absent, (3) verifies conditional `docker-compose.yml` with `--deploy-target=docker-compose`, (4–5) verifies backend/frontend file structure, (6) Docker build, (7) container runtime test with `MOCK_MODE=true` — polls health, asserts `"status":"mock"` response, (8) container runtime test with `BLOCK_TRAFFIC=true` — asserts 503. Docker stages auto-skipped if daemon unavailable. Integrated into `run-all-e2e.sh` as step 7.
- **GitHub Actions CI** (`.github/workflows/ci.yml`): two-job pipeline — `build` (`mvn verify` on JDK 21) and `e2e` (full E2E suite including Docker build). Triggers on push to `main`/`feature**`/`bugfix**` and PRs to `main`.
- **Checkstyle** (`apibridge-generator/checkstyle.xml`): 4-space indent, naming conventions, no star/unused imports, braces required. Bound to `mvn verify`; 0 violations on all sources.
- **Schema reference documentation** (`docs/schema-reference.md`): complete field reference with types, valid values, defaults, and validation rules.
- **CLAUDE.md project instructions**: persistent guidance for Claude Code sessions covering build commands, cartridge architecture, schema enum values, and git workflow.
- **Engine routing unit tests**: five new tests covering `testFlavorDirSelectionPicksMatchingBeDir`, `testFlavorDirSelectionSkipsMismatchedFeDir`, `testOutputPathMappingStripsFlavorPrefix`, `testSkipsEmptyRenderedOutput`, and `testRootTemplatesStillOutputToRoot`.
- **YamlParser unit tests**: 36 tests covering all validation paths — null/missing/directory/malformed file input, required field presence, all flags enum validation (including blank values and case-insensitivity for all enum flags), endpoint validation for all required fields (null and blank), second-endpoint index in error messages, uiLayout/field validation, uiLayout with null fields, and happy-path cases.
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
- Schema validation: `id`, `basePath`, `endpoints` required; `backendFlavor` enum; `securityLevel` enum; telemetry-name conditional requirement; uiLayout field validation.
