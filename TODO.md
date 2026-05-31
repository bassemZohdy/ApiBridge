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
- [x] **Pin `typicode/json-server` Docker image to v0.17.4 in E2E compose** — `0.17` floating minor tag does not exist on Docker Hub; docker pull fails silently, test times out at 90s wait
- [x] **Fix `set -e` + `((PASSED++))` arithmetic zero exit bug in `run-e2e.sh`** — bash `(( ))` returns exit code 1 when expression evaluates to 0 (post-increment of 0); `set -euo pipefail` killed the script after the very first `pass()` call, before Docker build even started; fixed with `PASSED=$((PASSED + 1))`
- [x] **Add json-server `healthcheck` and `condition: service_healthy` to E2E compose**
- [x] **Add `docker/setup-buildx-action` and `timeout-minutes: 30` to `e2e-json-server` CI job** — sister job `e2e-docker` had both; json-server job was missing both (cold npm+Maven builds, no hung-build guard)

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
