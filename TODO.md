# ApiBridge — Active Work

## Cleanup Review Cycle

Deep project-wide review completed. All P7 and anti-pattern fix work is done. This cycle is cleanup and hardening.

---

### CRITICAL — Bugs in generated code

| # | Fix | Source | Status |
|---|-----|--------|--------|
| C1 | **Quarkus ProxyService**: `redisClient` undefined when both `enableResponseCache=true` AND `enableAuditLog=true` — line 161 references `redisClient` but no `@Inject RedisClient` field exists. Compile error in generated code. | H-01 | [ ] |
| C2 | **Spring Boot SecurityConfig**: hardcoded `jwkSetUri` appends `/protocol/openid-connect/certs` (Keycloak-specific path). Breaks Auth0, Okta, AWS Cognito, other OIDC providers. Should use Spring's `issuer-uri` auto-discovery instead. | H-02 | [ ] |
| C3 | **Quarkus ProxyService**: response header `remove` transform is dead code — creates filtered `MultivaluedHashMap` but never applies it to the builder. Silently does nothing. | H-03 | [ ] |
| C4 | **Spring Boot ProxyService**: cached responses skip response field transforms — `responseCache.put()` stores raw body, cache hits return it without `applyFieldTransforms()`. Correctness bug when both cache + transforms enabled. | H-04 | [ ] |
| C5 | **OpenShift kustomization**: references `configmap.yaml`, `deployment.yaml`, `service.yaml` as local resources that don't exist in the OpenShift cartridge dir. Generated kustomization fails `kubectl apply -k`. | H-05 | [ ] |

### HIGH — Security, correctness, coverage

| # | Fix | Source | Status |
|---|-----|--------|--------|
| H1 | **Missing `OIDC_ISSUER_URI` env var** in all devops templates (Dockerfile, docker-compose, configmap, Helm values). SecurityConfig requires it at runtime but deployments won't have it. | M-01 | [ ] |
| H2 | **OpenAPI template**: `flags.securityLevel??` evaluates true for empty string `""`, produces invalid OpenAPI YAML with empty security scheme. Should be `(flags.securityLevel!"") != ""`. | M-10 | [ ] |
| H3 | **Angular `bridge-api.service.ts`** reads API key from `localStorage` (XSS-accessible) while React/Vue use `import.meta.env.VITE_API_KEY` (build-time). Security inconsistency. | M-07 | [ ] |
| H4 | **Bearer token auth non-functional in frontends**: React Form accepts `token` prop but never provides UI to input it; Vue Form passes `undefined` as token. API calls never include auth headers. | M-08 | [ ] |
| H5 | **Web builder `UiField.type` incomplete**: TypeScript type is `'string' | 'number' | 'boolean' | ''` but schema supports `integer`, `email`, `date`, `url`, `password`. Users cannot produce valid schemas for these types. | tests #32 | [ ] |
| H6 | **Web builder missing UI for `uiLayout`, `transforms`, `mockResponse`** — endpoint editor only has method/path/backendUrl/telemetryName. | tests #36 | [ ] |
| H7 | **README.md says `flags` "may be null"** but `ApiBridgeRunner` synthesizes `new Flags()` when absent — it's always non-null. Contradicts AGENTS.md and CLAUDE.md. | docs #6 | [ ] |
| H8 | **AGENTS.md FreeMarker context table incomplete** — lists 9 variables but context has 17. Missing: `enableRateLimiter`, `enableTransform`, `apiVersion`, `enableHealthCheck`, `enableSearch`, `enableOfflineSupport`, `enableOpenApi`. | docs #9 | [ ] |
| H9 | **HANDOFF.md references AGENTS.md for ENV VAR list** but AGENTS.md has zero ENV VAR documentation. Broken reference. | docs #13 | [ ] |
| H10 | **schema-reference.md missing 5 field types** — lists `string`, `number`, `boolean` but templates also support `integer`, `email`, `date`, `url`, `password`. | docs #7 | [ ] |
| H11 | **Missing test coverage for CLI arg-parsing** in `ApiBridgeRunnerTest` — `--help`, `--version`, missing required args, override precedence, unrecognized args all untested. | tests #4 | [ ] |
| H12 | **Missing tests for transform validation errors** — blank keys/values in `add`/`rename` maps, blank entries in `remove` lists have zero test coverage. | tests #21 | [ ] |

### MEDIUM — Code quality, maintenance, consistency

| # | Fix | Source | Status |
|---|-----|--------|--------|
| M1 | **YamlParser.validate() is 145 lines** with 4+ nesting levels. Decompose into `validateFlags()`, `validateEndpoints()`, `validateUiLayout()`, `validateTransforms()`, `validateMockResponse()`. | engine #27 | [ ] |
| M2 | **Zero Javadoc on all 8 public classes** — contradicts AGENTS.md claim "Full Javadoc on all classes and fields." Add class-level and key method Javadoc. | engine #69 | [ ] |
| M3 | **`enableOidc`/`oidcIssuerUri` fields missing Javadoc** in `BridgeSchemaModel.Flags` — only fields without docs. | engine #60 | [ ] |
| M4 | **ApiBridgeRunner uses FQN** `java.util.ArrayList`, `BridgeSchemaModel.Flags`, `java.util.function.Consumer` instead of imports. | engine #41-43 | [ ] |
| M5 | **`System.out/err.println` for all logging** — no log-level control. 40+ println calls across all engine classes. Consider `java.util.logging` or SLF4J. | engine #70 | [ ] |
| M6 | **`flags` null-check inconsistency**: `ApiBridgeRunner` guarantees non-null, but `resolvedFlag()`/`resolvedString()` still check `model.getFlags() != null`. Remove redundant checks or document contract. | engine #73 | [ ] |
| M7 | **`pathToEnvKey` FreeMarker function duplicated 7 times** across backend + devops templates. Extract to shared template or document as known duplication. | M-02 | [ ] |
| M8 | **`mapLiteral`/`listLiteral`/`transformArgs` macros duplicated** between Spring Boot and Quarkus. Spring Boot defines them unconditionally (dead code when `enableTransform=false`). | M-03 | [ ] |
| M9 | **Endpoint detection logic (`hasListEndpoint` etc.) copy-pasted 12+ times** across all frontend templates. | M-05 | [ ] |
| M10 | **Missing `.apib-offline-banner` CSS class** in all three frontend frameworks — offline banner renders as unstyled inline text. | M-06 | [ ] |
| M11 | **CSS ~99% duplicated between React and Angular** (~470 lines each). | M-09 | [ ] |
| M12 | **`YamlParserFeatureFlagsTest` boilerplate** — ~15 boolean flag tests follow identical pattern. Refactor to JUnit 5 `@ParameterizedTest`. | tests #18 | [ ] |
| M13 | **Fragile string assertions** in `CoreCartridgeEngineTest`, `MockModeEngineTest`, `TransformEngineTest` — assert exact method signatures/escape sequences that break on any template formatting change. | tests #22,24,25 | [ ] |
| M14 | **Missing null/blank test for `CartridgeResolver.resolve()`** — guard added but no test. | tests #8 | [ ] |
| M15 | **Missing null test for `CartridgeDownloader.downloadAndExtract()`** — guards added but no test. | tests #12 | [ ] |
| M16 | **Dead code in `ApiBridgeCartridgeEngineTestBase`** — `model.getEndpoints();` is a no-op discarded return value. | tests #1 | [ ] |
| M17 | **Stale per-class test counts in HANDOFF.md and TODO.md** — YamlParser=126 (not 112), Transform=10 (not 20), Search=6 (not 10). Total 300 is correct. | docs #1-2 | [ ] |
| M18 | **CHANGELOG.md stale test counts** — YamlParser "119 tests" → now 126; Engine classes "16 classes, 135 tests" → now 18 classes, ~170 tests. | docs #3-4 | [ ] |
| M19 | **`YOUR_ORG` placeholder** in README.md and Dockerfile.generator — dead links. Replace with actual org or document as intentional placeholder. | docs #16 | [ ] |
| M20 | **Missing LICENSE file** — referenced in `release.yml` but doesn't exist. Release ZIP ships without license. | docs #17 | [ ] |
| M21 | **`dist/` build artifact tracked in git** — `apibridge-web-builder/dist/` is committed. Add to `.gitignore`. | docs #21 | [ ] |
| M22 | **Missing `.dockerignore`** — Dockerfile.generator copies entire repo context including `e2e-tests/`, `node_modules/`. | docs #26 | [ ] |
| M23 | **SchemaComposer.compose() NPE risk** — `ep.getMethod().toUpperCase()` will NPE if method is null. Add defensive check. | engine #65 | [ ] |
| M24 | **CartridgeCache public methods lack null validation** — `isCached(null)`, `resolve(null)`, `allocate(null)` will NPE. | engine #52-54 | [ ] |
| M25 | **Magic strings** — `"github:"`, `"main"`, `".ftl"`, HTTP methods list, `"https://"` etc. should be constants across `CartridgeResolver`, `YamlParser`, `ApiBridgeCartridgeEngine`. | engine #19-21,28 | [ ] |
| M26 | **Inconsistent error message formatting** — `YamlParser` prefixes "Schema validation error:", `SchemaComposer` uses "Composition error:", `CartridgeResolver` uses "Invalid github: reference --". No unified format. | engine #71 | [ ] |
| M27 | **`pom.xml` redundant compiler properties** — uses both `maven.compiler.source/target` AND `maven-compiler-plugin <release>21</release>`. Remove `source`/`target`, use only `maven.compiler.release=21`. | build #29 | [ ] |
| M28 | **Web builder missing `autoprefixer`** — Tailwind CSS recommends it but it's not installed. | build #33 | [ ] |

### LOW — Polish, minor improvements

| # | Fix | Source | Status |
|---|-----|--------|--------|
| L1 | **Log message "Projected generated outlet asset:"** is garbled English. → "Wrote:" or "Generated:". | engine #4 | [ ] |
| L2 | **Error message "Bridge Schema Model (PIM)"** — unexplained "PIM" acronym in user-facing output. | engine #1 | [ ] |
| L3 | **Duplicate `TimeUnit` import** in Quarkus ProxyService when `enableResponseCache=true`. | L-02 | [ ] |
| L4 | **Spring Boot `BridgeController.java.ftl` defines transform macros unconditionally** — dead code when `enableTransform=false`. Quarkus version correctly wraps in conditional. | L-03 | [ ] |
| L5 | **Helm `values.yaml` omits most ENV VARs** — only includes rate limiter, cache, CB, health, search. Missing audit, security, telemetry, pagination, debug, CORS, etc. | L-01 | [ ] |
| L6 | **`BridgeConfig` endpoint exposes only subset of flags** — omits OIDC, CB, rate limiter, cache, transform, audit, OpenAPI, offline. May be intentional (client-relevant only) but undocumented. | L-06 | [ ] |
| L7 | **`.gitignore` missing IDE patterns** — `.idea/`, `*.iml`, `.vscode/`, `.DS_Store`, etc. | docs #22 | [ ] |
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
| L19 | **schema-reference.md "Phase 6 full" section header** — internal phase number meaningless to external users. → "Full example". | docs #8 | [ ] |

---

## Completed

| Phase | Description |
|-------|-------------|
| Anti-pattern fix cycle (H1–H12) | Critical bugs, thread safety, null guards, template consistency |
| P7a–P7f | CLI packaging, multi-schema, Helm, OIDC, web builder, cartridge registry |

---

## Test status

```
mvn verify → 300/300 PASS, 0 Checkstyle violations
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
| YamlParserTransformsTest | 5 |
| AuditLogEngineTest | 4 |
| ApiVersioningEngineTest | 4 |
| DebugModeEngineTest | 4 |
| ApiBridgeRunnerTest | 4 |
| CartridgeDownloaderTest | 4 |
| DarkModeEngineTest | 3 |
| MockModeEngineTest | 2 |

Web builder: 15 Vitest tests.
