# ApiBridge — Active Work

## Cleanup Review Cycle

Deep project-wide review completed. All P7 and anti-pattern fix work is done. This cycle is cleanup and hardening.

---

### CRITICAL — Bugs in generated code

| # | Fix | Source | Status |
|---|-----|--------|--------|
| C1 | **Quarkus ProxyService**: `redisClient` undefined when both `enableResponseCache=true` AND `enableAuditLog=true`. | H-01 | [x] |
| C2 | **Spring Boot SecurityConfig**: hardcoded `jwkSetUri` appends Keycloak-specific path. | H-02 | [x] |
| C3 | **Quarkus ProxyService**: response header `remove` transform is dead code. | H-03 | [x] |
| C4 | **Spring Boot ProxyService**: cached responses skip response field transforms. | H-04 | [x] |
| C5 | **OpenShift kustomization**: references local resources. Not a bug — both cartridges output to `k8s/`. | H-05 | [x] |

### HIGH — Security, correctness, coverage

| # | Fix | Source | Status |
|---|-----|--------|--------|
| H1 | **Missing `OIDC_ISSUER_URI` env var** in all devops templates. | M-01 | [x] |
| H2 | **OpenAPI template**: `flags.securityLevel??` evaluates true for empty string. | M-10 | [x] |
| H3 | **Angular `bridge-api.service.ts`** reads API key from `localStorage`. | M-07 | [x] |
| H4 | **Bearer token auth non-functional in frontends**. By design — token from external auth. | M-08 | [x] |
| H5 | **Web builder `UiField.type` incomplete**. | tests #32 | [ ] |
| H6 | **Web builder missing UI for `uiLayout`, `transforms`, `mockResponse`**. | tests #36 | [ ] |
| H7 | **README.md says `flags` "may be null"** — fixed. | docs #6 | [x] |
| H8 | **AGENTS.md FreeMarker context table incomplete** — expanded to 17 vars. | docs #9 | [x] |
| H9 | **HANDOFF.md references AGENTS.md for ENV VAR list** — fixed. | docs #13 | [x] |
| H10 | **schema-reference.md missing field types** — added. | docs #7 | [x] |
| H11 | **Missing test coverage for CLI arg-parsing** — not testable (System.exit). | tests #4 | [ ] |
| H12 | **Missing tests for transform validation errors** — 5 tests added. | tests #21 | [x] |

### MEDIUM — Code quality, maintenance, consistency

| # | Fix | Source | Status |
|---|-----|--------|--------|
| M1 | **YamlParser.validate() decomposed** into 12 focused methods. | engine #27 | [x] |
| M2 | **Javadoc added** to all 7 undocumented engine classes. | engine #69 | [x] |
| M3 | **`enableOidc`/`oidcIssuerUri` Javadoc** added. | engine #60 | [x] |
| M4 | **ApiBridgeRunner FQN imports** fixed. | engine #41-43 | [x] |
| M5 | **Library classes use java.util.logging** instead of System.out/err. | engine #70 | [x] |
| M6 | **`flags` null-check kept** — documents contract for non-runner callers. | engine #73 | [x] |
| M7 | **`pathToEnvKey` FreeMarker function duplicated 7 times** across backend + devops templates. Extract to shared template or document as known duplication. | M-02 | [ ] |
| M8 | **`mapLiteral`/`listLiteral`/`transformArgs` macros duplicated** between Spring Boot and Quarkus. Spring Boot defines them unconditionally (dead code when `enableTransform=false`). | M-03 | [ ] |
| M9 | **Endpoint detection logic (`hasListEndpoint` etc.) copy-pasted 12+ times** across all frontend templates. | M-05 | [ ] |
| M10 | **Missing `.apib-offline-banner` CSS class** in all three frontend frameworks — offline banner renders as unstyled inline text. | M-06 | [ ] |
| M11 | **CSS ~99% duplicated between React and Angular** (~470 lines each). | M-09 | [ ] |
| M12 | **`YamlParserFeatureFlagsTest` boilerplate** — ~15 boolean flag tests follow identical pattern. Refactor to JUnit 5 `@ParameterizedTest`. | tests #18 | [ ] |
| M13 | **Fragile string assertions** in `CoreCartridgeEngineTest`, `MockModeEngineTest`, `TransformEngineTest` — assert exact method signatures/escape sequences that break on any template formatting change. | tests #22,24,25 | [ ] |
| M14 | **Missing null/blank test for `CartridgeResolver.resolve()`** — guard added but no test. | tests #8 | [ ] |
| M15 | **Missing null test for `CartridgeDownloader.downloadAndExtract()`** — guards added but no test. | tests #12 | [ ] |
| M16 | **Dead code in `ApiBridgeCartridgeEngineTestBase`** — removed. | tests #1 | [x] |
| M17 | **Stale per-class test counts** — fixed. | docs #1-2 | [x] |
| M18 | **CHANGELOG.md stale test counts** — still stale. | docs #3-4 | [ ] |
| M19 | **`YOUR_ORG` placeholder** — replaced with `apibridge`. | docs #16 | [x] |
| M20 | **Missing LICENSE file** — added Apache 2.0. | docs #17 | [x] |
| M21 | **`dist/` build artifact** — added to `.gitignore`. | docs #21 | [x] |
| M22 | **Missing `.dockerignore`** — added. | docs #26 | [x] |
| M23 | **SchemaComposer.compose() NPE risk** — null guard added. | engine #65 | [x] |
| M24 | **CartridgeCache public methods null validation** — added. | engine #52-54 | [x] |
| M25 | **Magic strings** — extracted to constants (BANNER_LINE, FTL_SUFFIX, GITHUB_PREFIX, etc.). | engine #19-21,28 | [x] |
| M26 | **Error message formatting** — SchemaComposer now uses "Schema composition error:". | engine #71 | [x] |
| M27 | **`pom.xml` redundant compiler properties** — replaced with `maven.compiler.release`. | build #29 | [x] |
| M28 | **Web builder missing `autoprefixer`** — Tailwind CSS recommends it but it's not installed. | build #33 | [ ] |

### LOW — Polish, minor improvements

| # | Fix | Source | Status |
|---|-----|--------|--------|
| L1 | **Log message "Projected generated outlet asset:"** — changed to "Wrote generated file:". | engine #4 | [x] |
| L2 | **Error message "Bridge Schema Model (PIM)"** — "PIM" removed. | engine #1 | [x] |
| L3 | **Duplicate `TimeUnit` import** in Quarkus ProxyService — fixed. | L-02 | [x] |
| L4 | **Spring Boot `BridgeController.java.ftl` transform macros** — now conditional. | L-03 | [x] |
| L5 | **Helm `values.yaml` omits most ENV VARs** — only includes rate limiter, cache, CB, health, search. Missing audit, security, telemetry, pagination, debug, CORS, etc. | L-01 | [ ] |
| L6 | **`BridgeConfig` endpoint exposes only subset of flags** — omits OIDC, CB, rate limiter, cache, transform, audit, OpenAPI, offline. May be intentional (client-relevant only) but undocumented. | L-06 | [ ] |
| L7 | **`.gitignore` missing IDE patterns** — added. | docs #22 | [x] |
| L8 | **`CHANGELOG.md` unlabeled `### Added`/`### Changed` sections** — Phase 6 content without phase label mixed with labeled P7 sections. | docs #23 | [ ] |
| L9 | **HANDOFF.md missing `Column` and `Field` model classes** in the model section. | docs #14-15 | [ ] |
| L10 | **Schema quick reference duplicated** in AGENTS.md and CLAUDE.md; cartridge reference format quadruplicated across docs. | docs #18-19 | [ ] |
| L11 | **Test status duplicated in HANDOFF.md and TODO.md** — must update in sync. | docs #20 | [ ] |
| L12 | **`YamlParserFlagsTest.testDeployTargetAbsentMeansNullFlags`** — misleading name; actually validates entire `flags` section omitted. | tests #17 | [ ] |
| L13 | **Missing `Quarkus-SecurityConfig-not-generated` test** — Spring Boot version tested but not Quarkus. | tests #14 | [ ] |
| L14 | **Missing `HealthCheck-not-generated` test** — every other feature has a "not generated when off" test. | tests #27 | [ ] |
| L15 | **Redundant `testGetVersionNeverReturnsNull`** — already covered by `testGetVersionReturnsNonEmpty`. | tests #3 | [ ] |
| L16 | **Duplicate `findCartridgeDir` utility** in `ApiBridgeRunnerTest` and `ApiBridgeCartridgeEngineTestBase`. | tests #2,5 | [ ] |
| L17 | **Web builder missing tests** for serializer transforms/mockResponse/uiLayout/pagination, endpoint selection callback, flags panel dropdowns. | tests #37-39 | [ ] |
| L18 | **FreeMarker `Configuration.VERSION_2_3_32` hardcoded** — should track actual FreeMarker dependency version. | engine #7 | [ ] |
| L19 | **schema-reference.md "Phase 6 full" section header** — renamed to "Full example". | docs #8 | [x] |

---

## Completed

| Phase | Description |
|-------|-------------|
| Anti-pattern fix cycle (H1–H12) | Critical bugs, thread safety, null guards, template consistency |
| P7a–P7f | CLI packaging, multi-schema, Helm, OIDC, web builder, cartridge registry |

---

## Test status

```
mvn verify → 305/305 PASS, 0 Checkstyle violations
```

| Test class | Count |
|---|---|
| YamlParser* (9 files) | 126 |
| CoreCartridgeEngineTest | 33 |
| DevOpsCartridgeEngineTest | 17 |
| YamlParserEndpointTest | 20 |
| YamlParserFeatureFlagsTest | 35 |
| YamlParserUiLayoutTest | 23 |
| DistributedCacheEngineTest | 10 |
| TransformEngineTest | 10 |
| SchemaComposerTest | 8 |
| HelmCartridgeEngineTest | 8 |
| CartridgeCacheTest | 7 |
| HealthCheckEngineTest | 7 |
| OidcEngineTest | 7 |
| YamlParserFlagsTest | 18 |
| CartridgeResolverTest | 6 |
| CircuitBreakerEngineTest | 6 |
| ResponseCacheEngineTest | 6 |
| RateLimiterEngineTest | 6 |
| OfflineSupportEngineTest | 6 |
| OpenApiEngineTest | 6 |
| SearchFilterEngineTest | 6 |
| YamlParserTopLevelTest | 6 |
| YamlParserMockResponseTest | 9 |
| YamlParserPaginationTest | 5 |
| YamlParserFileAccessTest | 5 |
| YamlParserTransformsTest | 10 |
| AuditLogEngineTest | 4 |
| ApiVersioningEngineTest | 4 |
| DebugModeEngineTest | 4 |
| ApiBridgeRunnerTest | 4 |
| CartridgeDownloaderTest | 4 |
| DarkModeEngineTest | 3 |
| MockModeEngineTest | 2 |

Web builder: 15 Vitest tests.
