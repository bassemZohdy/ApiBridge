# Test Coverage

> Last updated: 2026-05-31

## Maven (Java engine)

```
mvn verify → 323/323 PASS, 0 Checkstyle violations
JaCoCo threshold: 85% instruction / 80% branch (current: ~91% / ~87%)
```

| Test class | Count |
|---|---|
| YamlParser* (13 files) | 131 |
| CoreCartridgeEngineTest | 13 |
| FrontendCartridgeEngineTest | 6 |
| EngineInputGuardTest | 7 |
| MethodNameEngineTest | 7 |
| DevOpsCartridgeEngineTest | 17 |
| YamlParserEndpointTest | 23 |
| YamlParserFeatureFlagsTest | 22 |
| YamlParserApiVersionTest | 9 |
| YamlParserOidcTest | 4 |
| YamlParserUiLayoutTest | 11 |
| YamlParserUiFieldTest | 8 |
| YamlParserSearchModeTest | 4 |
| DistributedCacheEngineTest | 11 |
| TransformEngineTest | 10 |
| SchemaComposerTest | 8 |
| HelmCartridgeEngineTest | 8 |
| CartridgeCacheTest | 10 |
| CartridgeDownloaderTest | 8 |
| CartridgeResolverTest | 8 |
| HealthCheckEngineTest | 8 |
| OidcEngineTest | 8 |
| YamlParserFlagsTest | 18 |
| CircuitBreakerEngineTest | 6 |
| ResponseCacheEngineTest | 8 |
| RateLimiterEngineTest | 6 |
| OfflineSupportEngineTest | 6 |
| OpenApiEngineTest | 9 |
| SearchFilterEngineTest | 6 |
| YamlParserTopLevelTest | 6 |
| YamlParserMockResponseTest | 9 |
| YamlParserPaginationTest | 5 |
| YamlParserFileAccessTest | 5 |
| YamlParserTransformsTest | 10 |
| AuditLogEngineTest | 4 |
| ApiVersioningEngineTest | 4 |
| DebugModeEngineTest | 4 |
| ApiBridgeRunnerTest | 3 |
| DarkModeEngineTest | 3 |
| MockModeEngineTest | 2 |

## Vitest (web builder)

20 tests. Lint via ESLint v9 flat config.

## E2E suites (19 total)

| # | Suite | CI job |
|---|-------|--------|
| 1 | Spring Boot compile | e2e-compile |
| 2 | Quarkus compile | e2e-compile |
| 3 | Angular strict tsc | e2e-compile |
| 4 | React strict tsc | e2e-compile |
| 5 | Vue strict tsc | e2e-compile |
| 6 | Contract symmetry | e2e-compile |
| 7 | Kubernetes manifests | e2e-compile |
| 8 | OpenShift manifests | e2e-compile |
| 9 | React production build | e2e-compile |
| 10 | OpenAPI spec validation | e2e-compile |
| 11 | Helm chart validation | e2e-compile |
| 12 | UI schema validation | e2e-compile |
| 13 | OIDC / SecurityConfig | e2e-compile |
| 14 | apiKey security | e2e-compile |
| 15 | Vue production build | e2e-compile |
| 16 | Angular production build | e2e-compile |
| 17 | Multi-schema composition | e2e-compile |
| 18 | Fullstack Docker | e2e-docker |
| 19 | json-server integration | e2e-json-server |
