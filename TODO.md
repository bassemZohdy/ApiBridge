# ApiBridge — Active Work

## Phase 7 Complete

All P7 sub-phases have been implemented and committed:

| Sub-phase | Description | Commit | Status |
|-----------|-------------|--------|--------|
| P7a | CLI Packaging & Distribution — shell wrappers, Dockerfile, release workflow | `72cb268` | [x] Done |
| P7b | Multi-Schema Composition — `SchemaComposer` + repeatable `--schema=` | `30d13c9` | [x] Done |
| P7c | Helm Chart Cartridge — `devops/k8s/helm` with Chart.yaml, values, templates | `b7e3e48` | [x] Done |
| P7d | OIDC Authentication Cartridge — Spring Boot + Quarkus JWT resource server | `35da0a9` | [x] Done |
| P7e | Web-Based Schema Builder — Vite+React+TypeScript SPA with live YAML preview | `348c130` | [x] Done |
| P7f | Plugin/External Cartridge Registry — URL + github: shorthand + SHA-256 cache | `38348c3` | [x] Done |

---

## Test status

```
mvn verify → 300/300 PASS, 0 Checkstyle violations
```

Test breakdown: 119 YamlParser*, 33 CoreCartridge, 17 DevOps, 20 Transform, 10 DistributedCache, 10 Search, 4 Audit, 6 CircuitBreaker, 6 ResponseCache, 6 RateLimiter, 7 HealthCheck, 6 Offline, 6 OpenApi, 4 Versioning, 4 Debug, 3 DarkMode, 2 MockMode, 4 ApiBridgeRunner, 7 CartridgeCache, 4 CartridgeDownloader, 6 CartridgeResolver.

---

## Deferred (from pre-P7 review)

| ID | Description | Status |
|----|-------------|--------|
| A1 | `YamlParser.validate()` flat method — extract `validateEnum()` helper | [ ] Deferred |
| A2 | `searchMode`/`enableSearch` cross-field pattern precedent for OIDC | [ ] Deferred |
