# ApiBridge — Backlog

Previous items (GAP-6, GAP-7, CLOUD-1–CLOUD-5, C1–C4, H1–H6, M5, M6, H3–H5) are complete.
See CHANGELOG.md for details.

---

## Phase 1 — Fix Compile-Breaking Bugs (CRITICAL)

- [ ] **BUG-1** React `ApiBridgeView.tsx.ftl:160-251` — **Duplicate component**. Old View (no DELETE) left after new one. TypeScript won't compile (duplicate identifier). Remove lines 160-251.

- [ ] **BUG-2** Angular `bridge-view.component.ts.ftl:142-225` — **Duplicate class**. Same issue. Remove lines 142-225.

- [ ] **BUG-3** Angular `bridge-view.component.ts.ftl:135` — **Unescaped `${this.recordId}`**. FreeMarker crash when `hasEdit=true`. Fix: `${r"${this.recordId}"}`.

- [ ] **BUG-4** Quarkus `ProxyService.java.ftl:62-86` — **Uninitialized `upstream` in `finally`**. Java compile error if `target.method()` throws. Fix: init to `null`, null-check in `finally`.

- [ ] **BUG-5** React `ApiBridgeList.tsx.ftl:104` — **Unescaped `${id}`**. FreeMarker replaces with service ID, row clicks navigate to wrong URL. Fix: `${r"${id}"}`.

- [ ] **BUG-6** Angular `bridge-list.component.ts.ftl:91` — **Broken URL**. `${'$'}{r"${basePath}"}` produces invalid JS. Fix: `${basePath}${listEndpoint.path}?${r"${queryStr}"}`.

---

## Phase 2 — Fix High-Severity Bugs

- [ ] **BUG-7** Spring Boot error responses served as `text/plain`, not `application/json`. Add `.contentType(MediaType.APPLICATION_JSON)` to all error `ResponseEntity` in `BridgeController.java.ftl` and `ProxyService.java.ftl`.

- [ ] **BUG-8** Auth `RestTemplate` has no timeouts — can hang indefinitely. Configure connect/read timeouts in `BridgeController.java.ftl`.

- [ ] **BUG-9** Quarkus auth `Response` from bearer validation never closed — connection leak. Close response in `BridgeResource.java.ftl` `validateBearerToken()`.

- [ ] **BUG-10** Angular Form has no navigation — missing `@Output() navigate`, no Back button. Add to `bridge-form.component.ts.ftl` and `bridge-form.component.html.ftl`.

- [ ] **BUG-11** Both CORS configs missing `exposedHeaders("*")` — upstream headers (e.g. `X-Total-Count`) invisible to frontend JS. Fix `CorsConfig.java.ftl` and Quarkus `application.properties.ftl`.

- [ ] **BUG-12** Telemetry span status never set to `ERROR` on exceptions — failed requests invisible in tracing. Add `span.setStatus(StatusCode.ERROR, ...)` in both `BridgeController.java.ftl` and `BridgeResource.java.ftl`.

- [ ] **BUG-13** `flags` null access crashes all backend templates when schema has no `flags:` section. Wrap in `<#if flags??>` or use `(flags!.field!default)` throughout.

---

## Phase 3 — Remove Dead Flags + Consistency Fixes

- [ ] **M1/M2** Remove `navigationMode` and `uiPattern` from entire codebase
  - `apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java`
  - `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java`
  - All 3 frontend App/Form/List/View templates (remove conditionals, remove web-component branches)
  - Both backend BridgeConfig controllers/resources
  - `apibridge-cartridges/devops/k8s/kubernetes/configmap.yaml.ftl`
  - `apibridge-generator/src/test/java/com/apibridge/engine/YamlParserTest.java`
  - `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeCartridgeEngineTest.java`
  - `sample-schema.yaml`
  - `e2e-tests/json-server-test/schema-spring-react.yaml`
  - `e2e-tests/json-server-test/schema-quarkus-vue.yaml`

- [ ] **M3** Enrich `/api/bridge-config` endpoint with `securityLevel`, `basePath`, `enableTelemetry`
  - `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/BridgeConfigController.java.ftl`
  - `apibridge-cartridges/backend/quarkus/src/main/java/com/apibridge/generated/BridgeConfigResource.java.ftl`

- [ ] **M4** Align CORS configuration (add `allowCredentials`, `maxAge`, `exposedHeaders`)
  - `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/CorsConfig.java.ftl`
  - `apibridge-cartridges/backend/quarkus/src/main/resources/application.properties.ftl`

- [ ] **M5** Add missing env vars to all DevOps templates: `PAGINATION_*` (5), `CUSTOM_CSS_PATH` (1)
  - `apibridge-cartridges/devops/dockerfile/Dockerfile.ftl`
  - `apibridge-cartridges/devops/docker-compose/docker-compose.yml.ftl`
  - `apibridge-cartridges/devops/k8s/kubernetes/configmap.yaml.ftl`

- [ ] **M6** Remove unused imports
  - Angular `bridge-list.component.ts.ftl:21` — unused `HttpHeaders`
  - Angular `bridge-list.component.ts.ftl:24` — unused `BridgeApiService`
  - Angular `bridge-api.service.ts.ftl:2` — unused `HttpContext`
  - Quarkus `ProxyService.java.ftl:14` — unused `java.util.List`

- [ ] **M7** Remove dead code / unused deps
  - Vue `bridgeApi.ts.ftl:3-23` — dead `pathToMethod` FreeMarker function
  - Vue `package.json.ftl:11` — unused `axios` dependency

- [ ] **M8** Fix mock-mode method case inconsistency — Spring Boot uses raw `${endpoint.method}`, Quarkus forces `${endpoint.method?upper_case}`. Align both to uppercase.

- [ ] **M9** Fix Quarkus FE static resource config — add conditional on feFlavor, add 365d cache headers.

- [ ] **M10** Fix Angular auth consistency — list/view components use inline `localStorage` instead of `BridgeApiService.getAuthHeaders()`.

- [ ] **M11** Fix `ui-schema/UiLayoutSchema.json.ftl` — add `columns` array and `field.label` (currently omitted).

- [ ] **M12** Fix `docs/schema-reference.md:24` — `feFlavor` default documented as `react` but model defaults to `null`.

- [ ] **M13** Add `@ApplicationScoped` to Quarkus `BridgeConfigResource.java.ftl`.

- [ ] **M14** Add `<name>` and `<description>` to Quarkus `pom.xml.ftl`.

- [ ] **M15** Add `.apib-spinner--dark` variant to Angular `styles.css.ftl`.

- [ ] **M16** Add `<style>` section to Vue `ApiBridgeView.vue.ftl`.

---

## Phase 4 — Testing & Quality

- [ ] **L1** Add Kubernetes manifest validation E2E suite
- [ ] **L2** Create richer multi-method test schema for E2E
- [ ] **L3** Fix CI wiring — add json-server-test job to `.github/workflows/ci.yml`
- [ ] **L4** Add frontend production build test (at least React)
- [ ] **L5** Fix Vue E2E to use `vue-tsc`
- [ ] **L6** Fix `run-all-e2e.sh` step numbering (first 5 say `/6`, rest `/7` or `/8`)
- [ ] **L7** Add basic form field validation from schema metadata
- [ ] **L8** Add unit test for generated API method names (`getSubmissions`, `getSubmissionsById`)
- [ ] **L9** Add DevOps cartridge unit tests (dockerfile, docker-compose)
- [ ] **L10** Add k8s cartridge E2E suite

---

## Phase 5 — Schema & Engine Improvements

- [ ] **S1** Add HTTP method validation to `YamlParser.java` — reject unknown verbs (only GET/POST/PUT/DELETE/PATCH allowed)
- [ ] **S2** Fix `uiLayout.component` validation to be case-insensitive (matches all other enum validations)
- [ ] **S3** Add `--security-level=` CLI override to `ApiBridgeRunner.java` (inconsistent with other flag overrides)
- [ ] **S4** Add duplicate endpoint detection to `YamlParser.java` (same path + method)
- [ ] **S5** Make proxy timeouts configurable via env vars (`PROXY_CONNECT_TIMEOUT`, `PROXY_READ_TIMEOUT`)
- [ ] **S6** Add Javadoc to `BridgeSchemaModel.java` (zero docs on all 6 inner classes, ~30 fields)
