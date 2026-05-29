# ApiBridge — Backlog

## Phase 6: Feature Expansion

> Detailed implementation plan: [`docs/superpowers/plans/2026-05-28-phase6-feature-expansion.md`](docs/superpowers/plans/2026-05-28-phase6-feature-expansion.md)

---

### Track 0: Model + Validation (prerequisite for all features)

- [x] M0.1 Add to `Flags`: `enableRateLimiter`, `enableTransform`, `apiVersion`, `enableHealthCheck`, `enableSearch`, `enableOfflineSupport`, `enableOpenApi`
- [x] M0.2 Add to `Endpoint`: `transforms` (Transforms), `mockResponse` (MockResponse)
- [x] M0.3 Add to `UiLayout`: `searchMode` (String)
- [x] M0.4 Create inner classes: `Transforms`, `HeaderTransform`, `FieldTransform`, `MockResponse`
- [x] M0.5 Add all getters/setters/toString
- [x] M0.6 Add YamlParser validation for all new fields
- [x] M0.7 Add new context variables to `ApiBridgeCartridgeEngine.buildContext()`
- [x] M0.8 `mvn verify` passes (existing tests should still pass — all new fields are optional with defaults)

---

### Track 1: Backend Proxy Enhancements

#### Feature 1: Rate Limiting

- [x] 1.1 Update Spring Boot `ProxyService.java.ftl` — RateLimiter field + init from ENV VARs + wrap forward()
- [x] 1.2 Update Spring Boot `BridgeController.java.ftl` — catch RequestNotPermitted → 429
- [x] 1.3 Update Spring Boot `pom.xml.ftl` — conditional resilience4j-ratelimiter dep
- [x] 1.4 Update Spring Boot `application.properties.ftl` — RATE_LIMIT_* docs
- [x] 1.5 Update Quarkus `ProxyService.java.ftl` — same RateLimiter pattern
- [x] 1.6 Update Quarkus `BridgeResource.java.ftl` — same 429 catch
- [x] 1.7 Update Quarkus `pom.xml.ftl` — conditional dep
- [x] 1.8 Update `docker-compose.yml.ftl` — RATE_LIMIT_* env vars
- [x] 1.9 Update `configmap.yaml.ftl` — RATE_LIMIT_* entries
- [x] 1.10 Add 6 unit tests (parser ×1, defaults ×1, engine ×4)
- [x] 1.11 `mvn verify` passes

#### Feature 2: Redis Distributed Cache (conditional)

- [x] 2.1 Refactor Spring Boot `ProxyService.java.ftl` — extract ResponseCache interface + CaffeineResponseCache + RedisResponseCache
- [x] 2.2 Update Spring Boot `pom.xml.ftl` — redis dep when enableResponseCache OR enableAuditLog
- [x] 2.3 Update Spring Boot `application.properties.ftl` — CACHE_REDIS_URL docs
- [x] 2.4 Refactor Quarkus `ProxyService.java.ftl` — same dual cache
- [x] 2.5 Update `docker-compose.yml.ftl` — CACHE_REDIS_URL + conditional redis service
- [x] 2.6 Update `configmap.yaml.ftl` — CACHE_REDIS_URL entry
- [x] 2.7 Add 8 unit tests (dual cache paths ×4, deps ×1, devops ×2, dedup ×1)
- [x] 2.8 `mvn verify` passes

#### Feature 3: Request/Response Transformation

- [x] 3.1 Update Spring Boot `ProxyService.java.ftl` — TransformService + header/field transforms in forward()
- [x] 3.2 Update Quarkus `ProxyService.java.ftl` — same pattern
- [x] 3.3 Update `application.properties.ftl` — transform behavior docs
- [x] 3.4 Add 10 unit tests (parser ×2, engine SB ×3, engine Quarkus ×3, off ×1, no-op ×1)
- [x] 3.5 `mvn verify` passes

#### Feature 4: API Versioning

- [x] 4.1 Update Spring Boot `BridgeController.java.ftl` — conditional `@RequestMapping("/${apiVersion}${basePath}")`
- [x] 4.2 Update Quarkus `BridgeResource.java.ftl` — same path adjustment
- [x] 4.3 Update `BridgeConfigController.java.ftl` — add apiVersion to response
- [x] 4.4 Update Quarkus `BridgeConfigResource.java.ftl` — add apiVersion to response
- [x] 4.5 Update React `bridgeApi.ts.ftl` — version prefix in base URL
- [x] 4.6 Update Angular `bridge-api.service.ts.ftl` — version prefix
- [x] 4.7 Update Vue `bridgeApi.ts.ftl` — version prefix
- [x] 4.8 Update `bridgeConfig.ts.ftl` / service files (all 3 frameworks) — add apiVersion to interface
- [x] 4.9 Add 8 unit tests (parser ×4, engine ×4)
- [x] 4.10 `mvn verify` passes

#### Feature 5: Enhanced Mock Mode

- [x] 5.1 Update Spring Boot `BridgeController.java.ftl` — schema-defined mock with delay + statusCode
- [x] 5.2 Update Quarkus `BridgeResource.java.ftl` — same pattern
- [x] 5.3 Add 6 unit tests (parser ×4, engine ×2)
- [x] 5.4 `mvn verify` passes

#### Feature 6: Debug Mode

- [x] 6.1 Create Spring Boot `DebugLoggingFilter.java.ftl` — OncePerRequestFilter with debug guard
- [x] 6.2 Create Quarkus `DebugLoggingFilter.java.ftl` — CDI filter with same guard
- [x] 6.3 Update `application.properties.ftl` — DEBUG_MODE docs
- [x] 6.4 Update `docker-compose.yml.ftl` — DEBUG_MODE env var (commented out)
- [x] 6.5 Update `configmap.yaml.ftl` — DEBUG_MODE entry
- [x] 6.6 Add 4 unit tests (engine ×4)
- [x] 6.7 `mvn verify` passes

---

### Track 2: Health & Observability

#### Feature 7: Health Check Aggregation

- [x] 7.1 Create Spring Boot `HealthCheckService.java.ftl` — scheduled probe + in-memory map
- [x] 7.2 Create Spring Boot `BridgeHealthController.java.ftl` — GET /api/bridge-health
- [x] 7.3 Create Quarkus `HealthCheckService.java.ftl` — same logic
- [x] 7.4 Create Quarkus `BridgeHealthResource.java.ftl` — JAX-RS endpoint
- [x] 7.5 Update `BridgeConfigController.java.ftl` + Quarkus equiv — add enableHealthCheck to config
- [x] 7.6 Update `application.properties.ftl` — HEALTH_CHECK_* docs
- [x] 7.7 Update `docker-compose.yml.ftl` + `configmap.yaml.ftl` — env vars
- [x] 7.8 Add 8 unit tests (parser ×1, engine ×6, devops ×1)
- [x] 7.9 `mvn verify` passes

---

### Track 3: Frontend Enhancements

#### Feature 8: Search & Filtering

- [x] 8.1 Update React `ApiBridgeList.tsx.ftl` — SearchBar + URL hash sync + delegate/local modes
- [x] 8.2 Update Angular `bridge-list.component.ts/html.ftl` — same components
- [x] 8.3 Update Vue `ApiBridgeList.vue.ftl` — same components
- [x] 8.4 Update `bridgeConfig.ts.ftl` / service files (all 3 frameworks) — add searchParam + enableSearch
- [x] 8.5 Update `BridgeConfigController.java.ftl` + Quarkus equiv — enableSearch + searchParam in config
- [x] 8.6 Update `application.properties.ftl` + `docker-compose.yml.ftl` + `configmap.yaml.ftl` — SEARCH_PARAM
- [x] 8.7 Add 10 unit tests (parser ×4 already done, engine ×6 added)
- [x] 8.8 `mvn verify` passes

#### Feature 9: Dark Mode / Theme Switcher

- [x] 9.1 Update React `index.css.ftl` — `[data-theme="dark"]` CSS block
- [x] 9.2 Update React `App.tsx.ftl` — theme toggle + localStorage + prefers-color-scheme
- [x] 9.3 Update Angular `styles.css.ftl` — dark CSS block
- [x] 9.4 Update Angular `app.component.ts/html.ftl` — theme toggle
- [x] 9.5 Update Vue CSS — dark CSS block in `App.vue.ftl` `<style>`
- [x] 9.6 Update Vue `App.vue.ftl` — theme toggle
- [x] 9.7 Add 3 unit tests (one per framework)
- [x] 9.8 `mvn verify` passes

#### Feature 10: Offline Support / Service Worker

- [x] 10.1 Create React `public/sw.js.ftl` — Service Worker (cache-first shell, stale-while-revalidate API)
- [x] 10.2 Update React `main.tsx.ftl` — register SW
- [x] 10.3 Update React `App.tsx.ftl` — `useOnlineStatus()` hook + offline banner
- [x] 10.4 Create Angular `src/sw.js.ftl` — Service Worker
- [x] 10.5 Update Angular `main.ts.ftl` — register SW + offline banner in app component
- [x] 10.6 Create Vue `public/sw.js.ftl` — Service Worker
- [x] 10.7 Update Vue `main.ts.ftl` — register SW + offline banner in App.vue
- [x] 10.8 Add 6 unit tests (sw.js ×3, no-sw ×1, registration ×2)
- [x] 10.9 `mvn verify` passes

---

### Track 4: Documentation

#### Feature 11: OpenAPI 3.0 Spec Generation

- [x] 11.1 Create `apibridge-cartridges/docs/openapi/` directory
- [x] 11.2 Create `openapi.yaml.ftl` — OpenAPI 3.0.3 spec from model
- [x] 11.3 Update Spring Boot `pom.xml.ftl` — conditional springdoc-openapi dep
- [x] 11.4 Update Quarkus `pom.xml.ftl` — conditional quarkus-smallrye-openapi dep
- [x] 11.5 Add 6 unit tests (parser ×1, engine ×5)
- [x] 11.6 `mvn verify` passes

---

### Backlog: YamlParser Test Coverage Gaps

> ~35 missing tests identified during review. Do after F10/F11 and final cleanup.

- [ ] T.1 Invalid `uiLayout.component` value (e.g. "Table") throws → `YamlParserUiLayoutTest`
- [ ] T.2 `backendFlavor: "quarkus"` valid parse → `YamlParserFlagsTest`
- [ ] T.3 Valid HTTP methods `PUT` / `DELETE` → `YamlParserEndpointTest`
- [ ] T.4 Lowercase HTTP method accepted (`"get"`) → `YamlParserEndpointTest`
- [ ] T.5 Duplicate endpoint exact same case (`GET /x` + `GET /x`) → `YamlParserEndpointTest`
- [ ] T.6 Same path different methods allowed (`GET /x` + `POST /x`) → `YamlParserEndpointTest`
- [ ] T.7 `apiVersion: ""` throws → `YamlParserFeatureFlagsTest`
- [ ] T.8 `apiVersion: "v"` (no digits) throws → `YamlParserFeatureFlagsTest`
- [ ] T.9 `apiVersion: "V1"` (uppercase V) throws → `YamlParserFeatureFlagsTest`
- [ ] T.10 `apiVersion: "v0"` valid → `YamlParserFeatureFlagsTest`
- [ ] T.11 `apiVersion: "v123"` valid → `YamlParserFeatureFlagsTest`
- [ ] T.12 `enableTelemetry` default false + explicit true → `YamlParserFeatureFlagsTest`
- [ ] T.13 `enableSearch` default false + explicit true → `YamlParserFeatureFlagsTest`
- [ ] T.14 `enableOfflineSupport` default false + explicit true → `YamlParserFeatureFlagsTest`
- [ ] T.15 `enableOpenApi` default false + explicit true → `YamlParserFeatureFlagsTest`
- [ ] T.16 `enableTransform` default false + explicit true → `YamlParserFeatureFlagsTest`
- [ ] T.17 `backendFlavor` defaults `"spring-boot"` when omitted → `YamlParserFlagsTest`
- [ ] T.18 `MockResponse` defaults (statusCode=200, delayMs=0, body=null) → `YamlParserMockResponseTest`
- [ ] T.19 `Column.sortable` defaults false → `YamlParserUiLayoutTest`
- [ ] T.20 `Column.label` null when absent → `YamlParserUiLayoutTest`
- [ ] T.21 `mockResponse.statusCode: 100` boundary valid → `YamlParserMockResponseTest`
- [ ] T.22 `mockResponse.statusCode: 599` boundary valid → `YamlParserMockResponseTest`
- [ ] T.23 `mockResponse.delayMs: 0` boundary valid → `YamlParserMockResponseTest`
- [ ] T.24 `mockResponse` absent → null on endpoint → `YamlParserMockResponseTest`
- [ ] T.25 Second field error `fields[1]` in message → `YamlParserUiLayoutTest`
- [ ] T.26 Second column error `columns[1]` in message → `YamlParserUiLayoutTest`
- [ ] T.27 Transforms `responseHeaders` + `requestFields` sub-objects → `YamlParserTransformsTest`
- [ ] T.28 Empty `transforms: {}` → null sub-objects → `YamlParserTransformsTest`
- [ ] T.29 Transforms absent → null on endpoint → `YamlParserTransformsTest`
- [ ] T.30 `telemetryName: "my_span"` stored correctly on model → `YamlParserEndpointTest`

---

### Final: Documentation & Cleanup

- [x] F.1 Update `docs/schema-reference.md` with all new flags + schema sections
- [x] F.2 Update `sample-schema.yaml` with Phase 6 features demonstrated
- [x] F.3 Update `CHANGELOG.md` with Phase 6 entries
- [x] F.4 Update `HANDOFF.md` with new test counts + design invariants
- [x] F.5 Update `README.md` with Phase 6 feature documentation
- [ ] F.6 Full `mvn verify` + E2E smoke test

---

## Progress Tracker

| Feature | Status | Tests | Assignee |
|---|---|---|---|
| M0: Model + Validation | Done | 20/20 | — |
| F1: Rate Limiting | Done | 8/6 | — |
| F2: Redis Distributed Cache | Done | 11/8 | — |
| F3: Request/Response Transform | Done | 10/10 | — |
| F4: API Versioning | Done | 8/8 | — |
| F5: Enhanced Mock Mode | Done | 6/6 | — |
| F6: Debug Mode | Done | 4/4 | — |
| F7: Health Check Aggregation | Done | 8/8 | — |
| F8: Search & Filtering | Done | 10/10 | — |
| F9: Dark Mode / Theme | Done | 3/3 | — |
| F10: Offline Support / SW | Done | 6/6 | — |
| F11: OpenAPI Spec | Done | 6/6 | — |
| **Total** | **11/11** | **90/90** | — |
