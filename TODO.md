# TODO — ApiBridge Backlog

## In Progress

- _none_

## Up Next

- _none_

## Backlog

_All known issues have been addressed. New tasks added here as they arise._

---

## Done

### Review Findings — Generator and Cartridge Correctness (12 items)

- [x] **Normalize enum flag values before template context is built**
- [x] **Make generated bearer-token security fail closed when `AUTH_SERVER_URL` is not configured**
- [x] **Fix Quarkus `enableAuditLog + enableResponseCache` import collision — compile error**
- [x] **Detect route-shape duplicate endpoints before generation**
- [x] **Make remote cartridge cache writes atomic and status-aware — two bugs**
- [x] **Enforce Java 21 via Maven Enforcer rule**
- [x] **Fix missing timeouts on generated Spring Boot `authRestTemplate`**
- [x] **Fix Quarkus `ProxyService.java.ftl` — `TimeUnit` import conditional**
- [x] **Remove `logging.structured.format.console=ecs` from Spring Boot config** (requires 3.4.x)
- [x] **Add `quarkus-logging-json` dependency to Quarkus pom**
- [x] **Pin `typicode/json-server` Docker image to v0.17 in E2E compose**
- [x] **Add json-server `healthcheck` and `condition: service_healthy` to E2E compose**

### CI Pipeline & E2E Coverage (all completed in prior session)

- [x] Web builder CI job (lint + typecheck + test)
- [x] 7 new E2E test suites (OpenAPI, Helm, UI Schema, OIDC, apiKey, Vue/Angular prod build, multi-schema)
- [x] Extended existing tests (rate limiter, transform, apiVersion, search, Service Worker, auditLog)
- [x] Concurrency groups in CI and release workflows
- [x] npm caching in all E2E CI jobs
- [x] JaCoCo coverage threshold (85% instruction / 80% branch)
- [x] ESLint v9 flat config for web builder

---

_Move items Backlog → Up Next → In Progress as work starts. Mark Done when merged to main._
