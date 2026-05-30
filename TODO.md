# ApiBridge — Active Work

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
