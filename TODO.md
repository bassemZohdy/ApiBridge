# ApiBridge — Active Work

## Anti-Pattern Fix Cycle (post-P7 review)

Critical and high-priority fixes from the full anti-pattern review. All P7 work is done; this is a cleanup pass.

| # | Fix | Severity | Status |
|---|-----|----------|--------|
| H1 | Remove duplicate component code (lines 160–251) in `react/ApiBridgeView.tsx.ftl` — generates invalid TS with duplicate exports | CRITICAL | [x] Done |
| H2 | Fix broken JS template literal in `angular/bridge-list.component.ts.ftl:123` — `${'$'}{r"${basePath}"}` produces undefined `r` at runtime | CRITICAL | [x] Done |
| H3 | Replace `HashMap` with `ConcurrentHashMap` + `computeIfAbsent` in `ApiBridgeCartridgeEngine.CONFIGURATION_CACHE` — thread safety | HIGH | [x] Done |
| H4 | Add null guard on `model` in `YamlParser.validate()` | HIGH | [x] Done |
| H5 | Add null guard on `cartridgeArg` in `CartridgeResolver.resolve()` | HIGH | [x] Done |
| H6 | Add null guards on `url`/`targetDir` in `CartridgeDownloader.downloadAndExtract()` | HIGH | [x] Done |
| H7 | Convert `TemplateEntry` to record in `ApiBridgeCartridgeEngine` | MEDIUM | [x] Done |
| H8 | Make `validateEnum()` static in `YamlParser` | MEDIUM | [x] Done |
| H9 | Deduplicate `resolvedBeFlavor`/`resolvedFeFlavor`/`resolvedDeployTarget` to use `resolvedString()` | MEDIUM | [x] Done |
| H10 | Remove `java.util.Set` fully-qualified refs in `ApiBridgeCartridgeEngine` — use import | MEDIUM | [x] Done |
| H11 | Normalize 17 bare `<#if flags.enableTelemetry>` → `<#if (flags.enableTelemetry)!false>` across 10 templates for consistency | MEDIUM | [x] Done |
| H12 | Run `mvn verify` → commit all fixes | HIGH | [x] Done |

### Completed before this cycle
- A1: Extract `validateEnum()` / `formatEnumValues()` / `requireNonBlankIf()` / `requireFlagForField()` helpers in `YamlParser.java`
- A2: Generalized cross-field validation via `requireNonBlankIf()` and `requireFlagForField()`

## Phase 7 Complete

All P7 sub-phases have been implemented and committed:

| Sub-phase | Description | Status |
|-----------|-------------|--------|
| P7a | CLI Packaging & Distribution — shell wrappers, Dockerfile, release workflow | [x] Done |
| P7b | Multi-Schema Composition — `SchemaComposer` + repeatable `--schema=` | [x] Done |
| P7c | Helm Chart Cartridge — `devops/k8s/helm` with Chart.yaml, values, templates | [x] Done |
| P7d | OIDC Authentication Cartridge — Spring Boot + Quarkus JWT resource server | [x] Done |
| P7e | Web-Based Schema Builder — Vite+React+TypeScript SPA with live YAML preview | [x] Done |
| P7f | Plugin/External Cartridge Registry — URL + github: shorthand + SHA-256 cache | [x] Done |

---

## Test status

```
mvn verify → 300/300 PASS, 0 Checkstyle violations
```

Test breakdown: 112 YamlParser*, 33 CoreCartridge, 17 DevOps, 20 Transform, 10 DistributedCache, 10 Search, 4 Audit, 6 CircuitBreaker, 6 ResponseCache, 6 RateLimiter, 7 HealthCheck, 6 Offline, 6 OpenApi, 4 Versioning, 4 Debug, 3 DarkMode, 2 MockMode, 7 OIDC, 8 Helm, 8 SchemaComposer, 4 ApiBridgeRunner, 7 CartridgeCache, 4 CartridgeDownloader, 6 CartridgeResolver.

Web builder: 15 Vitest tests.
