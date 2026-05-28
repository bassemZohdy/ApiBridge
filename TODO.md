# ApiBridge — Backlog

---

## Phase 5 — Resilience features

Two new independent schema flags. Each is opt-in; neither requires the other. Both follow the same ENV VAR override pattern as existing flags.

---

### `flags.enableCircuitBreaker: true` — Circuit breaker + retry

Wraps every upstream proxy call with a circuit breaker and retry policy. When the circuit is open, all calls short-circuit immediately to a 503 fallback (`{"error":"Service Unavailable","circuit":"open"}`). Retries fire before the failure is recorded against the circuit breaker.

**Schema addition**

```yaml
flags:
  enableCircuitBreaker: true
```

**Runtime ENV VARs** (all overrideable at runtime, no rebuild required)

| ENV VAR | Default | Purpose |
|---|---|---|
| `CB_FAILURE_RATE_THRESHOLD` | `50` | % failures (in sliding window) that trips circuit to OPEN |
| `CB_WAIT_DURATION_SECONDS` | `30` | seconds circuit stays OPEN before moving to HALF-OPEN |
| `CB_SLIDING_WINDOW_SIZE` | `10` | number of calls sampled for failure rate calculation |
| `CB_RETRY_MAX_ATTEMPTS` | `3` | total attempts per call (1 original + 2 retries) |
| `CB_RETRY_WAIT_MS` | `500` | fixed wait between retry attempts |

**Spring Boot cartridge changes**

- `pom.xml.ftl` — add `io.github.resilience4j:resilience4j-spring-boot3` + `org.springframework.boot:spring-boot-starter-aop` (required for Resilience4j annotations) when flag is true
- `application.properties.ftl` — emit resilience4j config block bound to ENV VARs:
  ```
  resilience4j.circuitbreaker.instances.proxy.failure-rate-threshold=${CB_FAILURE_RATE_THRESHOLD:50}
  resilience4j.circuitbreaker.instances.proxy.wait-duration-in-open-state=${CB_WAIT_DURATION_SECONDS:30}s
  resilience4j.circuitbreaker.instances.proxy.sliding-window-size=${CB_SLIDING_WINDOW_SIZE:10}
  resilience4j.retry.instances.proxy.max-attempts=${CB_RETRY_MAX_ATTEMPTS:3}
  resilience4j.retry.instances.proxy.wait-duration=${CB_RETRY_WAIT_MS:500}ms
  ```
- `ProxyService.java.ftl` — annotate each generated proxy method with `@CircuitBreaker(name="proxy", fallbackMethod="fallback")` + `@Retry(name="proxy")`; add `fallback(Throwable)` method returning 503 JSON

**Quarkus cartridge changes**

- `pom.xml.ftl` — add `io.quarkus:quarkus-smallrye-fault-tolerance` when flag is true
- `application.properties.ftl` — emit SmallRye config block bound to ENV VARs:
  ```
  quarkus.fault-tolerance.cb.failure-rate=${CB_FAILURE_RATE_THRESHOLD:50}
  quarkus.fault-tolerance.cb.delay=${CB_WAIT_DURATION_SECONDS:30}
  quarkus.fault-tolerance.cb.request-volume-threshold=${CB_SLIDING_WINDOW_SIZE:10}
  quarkus.fault-tolerance.retry.max-retries=${CB_RETRY_MAX_ATTEMPTS:3}
  quarkus.fault-tolerance.retry.delay=${CB_RETRY_WAIT_MS:500}
  ```
- `ProxyService.java.ftl` — annotate each proxy method with `@CircuitBreaker(requestVolumeThreshold=10)` + `@Retry(maxRetries=3)` + `@Fallback(fallbackMethod="fallback")`; add `fallback()` method

**k8s ConfigMap changes**

- `configmap.yaml.ftl` — add conditional circuit breaker ENV VAR block when `flags.enableCircuitBreaker` is true

**docker-compose changes**

- `docker-compose.yml.ftl` — add conditional circuit breaker ENV VAR block in app service environment section

**Test coverage required**

- `YamlParserTest`: `enableCircuitBreaker` defaults false, explicit true, explicit false (3 tests)
- `ApiBridgeCartridgeEngineTest`: Spring Boot pom contains resilience4j dep; Spring Boot ProxyService has `@CircuitBreaker`+`@Retry`+fallback; Quarkus pom contains smallrye dep; Quarkus ProxyService has annotations; k8s ConfigMap has CB env vars; docker-compose has CB env vars (6 tests)

---

### `flags.enableResponseCache: true` — In-process GET response cache

Caches GET proxy responses in-process using Caffeine (Spring Boot) or Quarkus Cache (Quarkus). No additional infrastructure required — independent of `enableAuditLog`. Only GET method calls are cached; non-GET calls always pass through. Cache key = HTTP method + full path + sorted query string. On cache hit, upstream is never called.

**Schema addition**

```yaml
flags:
  enableResponseCache: true
```

**Runtime ENV VARs**

| ENV VAR | Default | Purpose |
|---|---|---|
| `CACHE_TTL_SECONDS` | `60` | TTL for cached GET responses |
| `CACHE_MAX_SIZE` | `1000` | Maximum cached entries (LRU eviction) |

**Spring Boot cartridge changes**

- `pom.xml.ftl` — add `org.springframework.boot:spring-boot-starter-cache` + `com.github.ben-manes.caffeine:caffeine` when flag is true
- `Application.java.ftl` — add `@EnableCaching` import and annotation when flag is true
- `application.properties.ftl` — emit Caffeine cache config:
  ```
  spring.cache.type=caffeine
  spring.cache.caffeine.spec=maximumSize=${CACHE_MAX_SIZE:1000},expireAfterWrite=${CACHE_TTL_SECONDS:60}s
  ```
- `ProxyService.java.ftl` — annotate GET proxy methods with `@Cacheable(value="proxy-responses", key="#path + '?' + #queryParams")`; non-GET methods annotated with `@CacheEvict(value="proxy-responses", allEntries=true)` for PUT/DELETE/PATCH mutations on the same path

**Quarkus cartridge changes**

- `pom.xml.ftl` — add `io.quarkus:quarkus-cache` when flag is true
- `application.properties.ftl` — emit Quarkus cache config:
  ```
  quarkus.cache.caffeine.proxy-responses.expire-after-write=${CACHE_TTL_SECONDS:60}S
  quarkus.cache.caffeine.proxy-responses.maximum-size=${CACHE_MAX_SIZE:1000}
  ```
- `ProxyService.java.ftl` — annotate GET proxy methods with `@CacheResult(cacheName="proxy-responses")`; non-GET mutation methods with `@CacheInvalidateAll(cacheName="proxy-responses")`

**k8s ConfigMap changes**

- `configmap.yaml.ftl` — add conditional cache ENV VAR block when `flags.enableResponseCache` is true

**docker-compose changes**

- `docker-compose.yml.ftl` — add conditional cache ENV VAR block in app service environment section

**Test coverage required**

- `YamlParserTest`: `enableResponseCache` defaults false, explicit true, explicit false (3 tests)
- `ApiBridgeCartridgeEngineTest`: Spring Boot pom contains cache deps; Spring Boot Application has `@EnableCaching`; Spring Boot ProxyService GET has `@Cacheable`, PUT/DELETE have `@CacheEvict`; Quarkus pom contains quarkus-cache; Quarkus ProxyService GET has `@CacheResult`, mutations have `@CacheInvalidateAll`; k8s ConfigMap has cache env vars (6 tests)

---

## Completion criteria

Both flags complete when:
1. All generated code compiles clean (Spring Boot `mvn compile`, Quarkus `mvn compile`)
2. All unit tests pass (`mvn test`)
3. `schema-reference.md`, `README.md`, `CHANGELOG.md`, `HANDOFF.md` updated
4. `sample-schema.yaml` updated to exercise both flags
