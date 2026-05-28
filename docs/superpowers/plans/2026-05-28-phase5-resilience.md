# Phase 5 Resilience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `flags.enableCircuitBreaker` and `flags.enableResponseCache` to the ApiBridge code generator, producing resilient proxy backends with circuit breaker + retry and in-process GET response caching.

**Architecture:** Both flags generate code in both backend cartridges (Spring Boot + Quarkus) using Resilience4j core API (programmatic, framework-agnostic). Circuit breaker wraps the upstream exchange call; response cache uses Caffeine directly embedded in ProxyService. DevOps cartridges (docker-compose, k8s ConfigMap) gain conditional ENV VAR blocks for both flags.

**Tech Stack:** Resilience4j 2.2.0 (`resilience4j-circuitbreaker`, `resilience4j-retry`), Caffeine 3.1.8, FreeMarker templates, JUnit 5.

---

## File Map

| File | Change |
|---|---|
| `BridgeSchemaModel.java` | Add `enableCircuitBreaker`, `enableResponseCache` to `Flags` |
| `backend/spring-boot/pom.xml.ftl` | Add resilience4j + caffeine deps conditionally |
| `backend/spring-boot/.../ProxyService.java.ftl` | Add CB init + cache init + forward() wrapping |
| `backend/spring-boot/.../application.properties.ftl` | Add CB + cache ENV VAR comments |
| `backend/quarkus/pom.xml.ftl` | Add resilience4j + caffeine deps conditionally |
| `backend/quarkus/.../ProxyService.java.ftl` | Add CB init + cache init + forward() wrapping |
| `backend/quarkus/.../application.properties.ftl` | Add CB + cache ENV VAR comments |
| `devops/docker-compose/docker-compose.yml.ftl` | Add CB + cache ENV VAR blocks |
| `devops/k8s/kubernetes/configmap.yaml.ftl` | Add CB + cache ENV VAR blocks |
| `YamlParserTest.java` | 6 new tests |
| `ApiBridgeCartridgeEngineTest.java` | 12 new tests |
| `sample-schema.yaml` | Add both flags |
| `schema-reference.md`, `README.md`, `CHANGELOG.md`, `HANDOFF.md` | Doc updates |

---

## Task 1: Model — add new Flags fields

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java`

- [ ] **Step 1: Add fields + accessors to Flags inner class**

In `BridgeSchemaModel.Flags`, after the `enableAuditLog` field/getter/setter block, add:

```java
/** Whether to generate Resilience4j circuit breaker + retry wrapping all proxy calls. */
private boolean enableCircuitBreaker;
/** Whether to generate an in-process Caffeine GET response cache in the proxy. */
private boolean enableResponseCache;

public boolean isEnableCircuitBreaker() { return enableCircuitBreaker; }
public void setEnableCircuitBreaker(boolean enableCircuitBreaker) { this.enableCircuitBreaker = enableCircuitBreaker; }

public boolean isEnableResponseCache() { return enableResponseCache; }
public void setEnableResponseCache(boolean enableResponseCache) { this.enableResponseCache = enableResponseCache; }
```

- [ ] **Step 2: Update Flags.toString()**

Replace the existing `toString()` body to include both new fields:

```java
return "Flags{enableTelemetry=" + enableTelemetry + ", enableAuditLog=" + enableAuditLog
        + ", enableCircuitBreaker=" + enableCircuitBreaker + ", enableResponseCache=" + enableResponseCache
        + ", securityLevel='" + securityLevel + "', backendFlavor='" + backendFlavor
        + "', feFlavor='" + feFlavor + "', deployTarget='" + deployTarget
        + "', pagination=" + pagination + '}';
```

- [ ] **Step 3: Run tests — must still pass 119/119**

```bash
cd apibridge-generator && mvn test -q
```

Expected: `BUILD SUCCESS`

---

## Task 2: Spring Boot pom.xml.ftl — add dependencies

**Files:**
- Modify: `apibridge-cartridges/backend/spring-boot/pom.xml.ftl`

- [ ] **Step 1: Add resilience4j + caffeine dependency blocks**

After the closing `</#if>` of the audit log block (line 53), add:

```xml
<#if (flags.enableCircuitBreaker)!false>
        <dependency>
            <groupId>io.github.resilience4j</groupId>
            <artifactId>resilience4j-circuitbreaker</artifactId>
            <version>2.2.0</version>
        </dependency>
        <dependency>
            <groupId>io.github.resilience4j</groupId>
            <artifactId>resilience4j-retry</artifactId>
            <version>2.2.0</version>
        </dependency>
</#if>
<#if (flags.enableResponseCache)!false>
        <dependency>
            <groupId>com.github.ben-manes.caffeine</groupId>
            <artifactId>caffeine</artifactId>
        </dependency>
</#if>
```

Note: Spring Boot BOM (3.2.5) manages `caffeine` version — no explicit version needed.

---

## Task 3: Spring Boot ProxyService.java.ftl — CB + cache

**Files:**
- Modify: `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/ProxyService.java.ftl`

- [ ] **Step 1: Add conditional imports**

After the audit log imports block, add:

```java
<#if (flags.enableCircuitBreaker)!false>
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import java.time.Duration;
import java.util.function.Supplier;
</#if>
<#if (flags.enableResponseCache)!false>
import com.github.ben-manes.caffeine.cache.Cache;
import com.github.ben-manes.caffeine.cache.Caffeine;
import java.util.concurrent.TimeUnit;
</#if>
```

- [ ] **Step 2: Add conditional fields**

After `private final RestTemplate restTemplate;`, add:

```java
<#if (flags.enableCircuitBreaker)!false>
    private final CircuitBreaker circuitBreaker;
    private final Retry retry;
</#if>
<#if (flags.enableResponseCache)!false>
    private final Cache<String, String> responseCache;
</#if>
```

- [ ] **Step 3: Rewrite constructor(s) with CB + cache init**

Replace the entire constructor block (`<#if (flags.enableAuditLog)!false>` … `</#if>`) with:

```java
<#if (flags.enableAuditLog)!false>
    public ProxyService(ApplicationEventPublisher events) {
        this.restTemplate = new RestTemplate();
        this.events = events;
<#if (flags.enableCircuitBreaker)!false>
        this.circuitBreaker = buildCircuitBreaker();
        this.retry = buildRetry();
</#if>
<#if (flags.enableResponseCache)!false>
        this.responseCache = buildResponseCache();
</#if>
    }
<#else>
    public ProxyService() {
        this.restTemplate = new RestTemplate();
<#if (flags.enableCircuitBreaker)!false>
        this.circuitBreaker = buildCircuitBreaker();
        this.retry = buildRetry();
</#if>
<#if (flags.enableResponseCache)!false>
        this.responseCache = buildResponseCache();
</#if>
    }
</#if>
<#if (flags.enableCircuitBreaker)!false>

    private static CircuitBreaker buildCircuitBreaker() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom()
                .failureRateThreshold(Float.parseFloat(System.getenv().getOrDefault("CB_FAILURE_RATE_THRESHOLD", "50")))
                .waitDurationInOpenState(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("CB_WAIT_DURATION_SECONDS", "30"))))
                .slidingWindowSize(Integer.parseInt(System.getenv().getOrDefault("CB_SLIDING_WINDOW_SIZE", "10")))
                .build();
        return CircuitBreakerRegistry.of(config).circuitBreaker("proxy");
    }

    private static Retry buildRetry() {
        RetryConfig config = RetryConfig.custom()
                .maxAttempts(Integer.parseInt(System.getenv().getOrDefault("CB_RETRY_MAX_ATTEMPTS", "3")))
                .waitDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("CB_RETRY_WAIT_MS", "500"))))
                .build();
        return RetryRegistry.of(config).retry("proxy");
    }
</#if>
<#if (flags.enableResponseCache)!false>

    private static Cache<String, String> buildResponseCache() {
        return Caffeine.newBuilder()
                .maximumSize(Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000")))
                .expireAfterWrite(Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60")), TimeUnit.SECONDS)
                .build();
    }
</#if>
```

- [ ] **Step 4: Add cache check before try block in forward()**

After the `HttpEntity<String> entity = ...` line and before `<#if (flags.enableAuditLog)!false>` audit block, insert:

```java
<#if (flags.enableResponseCache)!false>
        if ("GET".equalsIgnoreCase(method)) {
            String cached = responseCache.getIfPresent(urlWithQuery);
            if (cached != null) {
                return ResponseEntity.ok().body(cached);
            }
        } else {
            responseCache.invalidateAll();
        }
</#if>
```

- [ ] **Step 5: Wrap exchange call with CB+Retry and add cache put**

Inside the `try` block, replace the direct `restTemplate.exchange(...)` call line with:

```java
<#if (flags.enableCircuitBreaker)!false>
            Supplier<ResponseEntity<String>> call = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry,
                            () -> restTemplate.exchange(urlWithQuery, httpMethod, entity, String.class)));
            ResponseEntity<String> upstream = call.get();
<#else>
            ResponseEntity<String> upstream = restTemplate.exchange(
                    urlWithQuery, httpMethod, entity, String.class);
</#if>
```

After the response headers loop (before the `<#if (flags.enableAuditLog)!false>` ProxySuccessEvent block), add:

```java
<#if (flags.enableResponseCache)!false>
            if ("GET".equalsIgnoreCase(method) && upstream.getBody() != null) {
                responseCache.put(urlWithQuery, upstream.getBody());
            }
</#if>
```

- [ ] **Step 6: Add CallNotPermittedException catch block**

Add before the `catch (RestClientResponseException ex)` block:

```java
<#if (flags.enableCircuitBreaker)!false>
        } catch (CallNotPermittedException e) {
            return ResponseEntity
                    .status(503)
                    .body("{\"error\":\"Service Unavailable\",\"circuit\":\"open\"}");
</#if>
```

---

## Task 4: Spring Boot application.properties.ftl — ENV VAR docs

**Files:**
- Modify: `apibridge-cartridges/backend/spring-boot/src/main/resources/application.properties.ftl`

- [ ] **Step 1: Add CB and cache ENV VAR comments**

After the audit log comment block (`<#if (flags.enableAuditLog)!false>` … `</#if>`), add:

```
<#if (flags.enableCircuitBreaker)!false>
#   CB_FAILURE_RATE_THRESHOLD=50    % failures (of CB_SLIDING_WINDOW_SIZE calls) to open circuit
#   CB_WAIT_DURATION_SECONDS=30     Seconds circuit stays OPEN before moving to HALF-OPEN
#   CB_SLIDING_WINDOW_SIZE=10       Number of calls sampled for failure rate calculation
#   CB_RETRY_MAX_ATTEMPTS=3         Total attempts per call (original + retries)
#   CB_RETRY_WAIT_MS=500            Wait between retry attempts in milliseconds
</#if>
<#if (flags.enableResponseCache)!false>
#   CACHE_TTL_SECONDS=60            TTL for cached GET responses
#   CACHE_MAX_SIZE=1000             Maximum cached entries (LRU eviction)
</#if>
```

---

## Task 5: Quarkus pom.xml.ftl — add dependencies

**Files:**
- Modify: `apibridge-cartridges/backend/quarkus/pom.xml.ftl`

- [ ] **Step 1: Add resilience4j + caffeine blocks after audit log block**

After the closing `</#if>` of the audit log block (line 59), add:

```xml
<#if (flags.enableCircuitBreaker)!false>
        <dependency>
            <groupId>io.github.resilience4j</groupId>
            <artifactId>resilience4j-circuitbreaker</artifactId>
            <version>2.2.0</version>
        </dependency>
        <dependency>
            <groupId>io.github.resilience4j</groupId>
            <artifactId>resilience4j-retry</artifactId>
            <version>2.2.0</version>
        </dependency>
</#if>
<#if (flags.enableResponseCache)!false>
        <dependency>
            <groupId>com.github.ben-manes.caffeine</groupId>
            <artifactId>caffeine</artifactId>
            <version>3.1.8</version>
        </dependency>
</#if>
```

Note: Quarkus BOM does not manage caffeine unless `quarkus-cache` is present, so version is explicit.

---

## Task 6: Quarkus ProxyService.java.ftl — CB + cache

**Files:**
- Modify: `apibridge-cartridges/backend/quarkus/src/main/java/com/apibridge/generated/ProxyService.java.ftl`

- [ ] **Step 1: Add conditional imports after audit log imports**

```java
<#if (flags.enableCircuitBreaker)!false>
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.github.resilience4j.retry.Retry;
import io.github.resilience4j.retry.RetryConfig;
import io.github.resilience4j.retry.RetryRegistry;
import java.time.Duration;
import java.util.function.Supplier;
</#if>
<#if (flags.enableResponseCache)!false>
import com.github.ben-manes.caffeine.cache.Cache;
import com.github.ben-manes.caffeine.cache.Caffeine;
import java.util.concurrent.TimeUnit;
</#if>
```

- [ ] **Step 2: Add conditional fields after audit event fields**

```java
<#if (flags.enableCircuitBreaker)!false>
    private CircuitBreaker circuitBreaker;
    private Retry retry;
</#if>
<#if (flags.enableResponseCache)!false>
    private Cache<String, String> responseCache;
</#if>
```

- [ ] **Step 3: Add CB + cache init to @PostConstruct init()**

Inside `void init()`, after the `client = ClientBuilder...build();` line, add:

```java
<#if (flags.enableCircuitBreaker)!false>
        CircuitBreakerConfig cbConfig = CircuitBreakerConfig.custom()
                .failureRateThreshold(Float.parseFloat(System.getenv().getOrDefault("CB_FAILURE_RATE_THRESHOLD", "50")))
                .waitDurationInOpenState(Duration.ofSeconds(Long.parseLong(System.getenv().getOrDefault("CB_WAIT_DURATION_SECONDS", "30"))))
                .slidingWindowSize(Integer.parseInt(System.getenv().getOrDefault("CB_SLIDING_WINDOW_SIZE", "10")))
                .build();
        RetryConfig retryConfig = RetryConfig.custom()
                .maxAttempts(Integer.parseInt(System.getenv().getOrDefault("CB_RETRY_MAX_ATTEMPTS", "3")))
                .waitDuration(Duration.ofMillis(Long.parseLong(System.getenv().getOrDefault("CB_RETRY_WAIT_MS", "500"))))
                .build();
        this.circuitBreaker = CircuitBreakerRegistry.of(cbConfig).circuitBreaker("proxy");
        this.retry = RetryRegistry.of(retryConfig).retry("proxy");
</#if>
<#if (flags.enableResponseCache)!false>
        this.responseCache = Caffeine.newBuilder()
                .maximumSize(Long.parseLong(System.getenv().getOrDefault("CACHE_MAX_SIZE", "1000")))
                .expireAfterWrite(Long.parseLong(System.getenv().getOrDefault("CACHE_TTL_SECONDS", "60")), TimeUnit.SECONDS)
                .build();
</#if>
```

- [ ] **Step 4: Add cache check before try block in forward()**

At the start of `forward()`, before the `<#if (flags.enableAuditLog)!false>` block:

```java
<#if (flags.enableResponseCache)!false>
        if ("GET".equalsIgnoreCase(method)) {
            String cached = responseCache.getIfPresent(targetUrl);
            if (cached != null) {
                return Response.ok(cached).type(MediaType.APPLICATION_JSON).build();
            }
        } else {
            responseCache.invalidateAll();
        }
</#if>
```

Note: Quarkus `forward()` receives `targetUrl` (not `urlWithQuery`); query params are part of the target URL passed in from `BridgeResource`. Verify variable name in the template.

- [ ] **Step 5: Wrap upstream call with CB+Retry**

Inside the `try` block, find the block that makes the JAX-RS client call. Replace:
```java
            if (requestBody != null && !requestBody.isBlank()) {
                upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
            } else {
                upstream = target.method(method.toUpperCase());
            }
```

With:

```java
<#if (flags.enableCircuitBreaker)!false>
            final var targetFinal = target;
            final String methodFinal = method.toUpperCase();
            final String bodyFinal = requestBody;
            final String ctFinal = contentType;
            Supplier<Response> call = CircuitBreaker.decorateSupplier(circuitBreaker,
                    Retry.decorateSupplier(retry, () -> {
                        if (bodyFinal != null && !bodyFinal.isBlank()) {
                            return targetFinal.method(methodFinal, Entity.entity(bodyFinal, ctFinal));
                        } else {
                            return targetFinal.method(methodFinal);
                        }
                    }));
            upstream = call.get();
<#else>
            if (requestBody != null && !requestBody.isBlank()) {
                upstream = target.method(method.toUpperCase(), Entity.entity(requestBody, contentType));
            } else {
                upstream = target.method(method.toUpperCase());
            }
</#if>
```

- [ ] **Step 6: Add cache put after reading response body**

After `String body = upstream.readEntity(String.class);`, add:

```java
<#if (flags.enableResponseCache)!false>
            if ("GET".equalsIgnoreCase(method) && body != null) {
                responseCache.put(targetUrl, body);
            }
</#if>
```

- [ ] **Step 7: Add CallNotPermittedException catch**

In the catch block (before `catch (Exception e)`), add:

```java
<#if (flags.enableCircuitBreaker)!false>
        } catch (CallNotPermittedException e) {
            return Response.status(503)
                    .entity("{\"error\":\"Service Unavailable\",\"circuit\":\"open\"}")
                    .type(MediaType.APPLICATION_JSON)
                    .build();
</#if>
```

---

## Task 7: Quarkus application.properties.ftl — ENV VAR docs

**Files:**
- Modify: `apibridge-cartridges/backend/quarkus/src/main/resources/application.properties.ftl`

- [ ] **Step 1: Add CB and cache ENV VAR comments after audit log block**

```
<#if (flags.enableCircuitBreaker)!false>
#   CB_FAILURE_RATE_THRESHOLD=50    % failures (of CB_SLIDING_WINDOW_SIZE calls) to open circuit
#   CB_WAIT_DURATION_SECONDS=30     Seconds circuit stays OPEN before moving to HALF-OPEN
#   CB_SLIDING_WINDOW_SIZE=10       Number of calls sampled for failure rate calculation
#   CB_RETRY_MAX_ATTEMPTS=3         Total attempts per call (original + retries)
#   CB_RETRY_WAIT_MS=500            Wait between retry attempts in milliseconds
</#if>
<#if (flags.enableResponseCache)!false>
#   CACHE_TTL_SECONDS=60            TTL for cached GET responses
#   CACHE_MAX_SIZE=1000             Maximum cached entries (LRU eviction)
</#if>
```

---

## Task 8: DevOps cartridges — ENV VAR blocks

**Files:**
- Modify: `apibridge-cartridges/devops/docker-compose/docker-compose.yml.ftl`
- Modify: `apibridge-cartridges/devops/k8s/kubernetes/configmap.yaml.ftl`

- [ ] **Step 1: docker-compose.yml.ftl — add CB + cache blocks**

After the audit log environment block (before `deploy:`), add:

```yaml
<#if (flags.enableCircuitBreaker)!false>
      # ── Circuit breaker + retry ────────────────────────────────────────────────
      CB_FAILURE_RATE_THRESHOLD: "50"
      CB_WAIT_DURATION_SECONDS: "30"
      CB_SLIDING_WINDOW_SIZE: "10"
      CB_RETRY_MAX_ATTEMPTS: "3"
      CB_RETRY_WAIT_MS: "500"
</#if>
<#if (flags.enableResponseCache)!false>
      # ── Response cache ─────────────────────────────────────────────────────────
      CACHE_TTL_SECONDS: "60"
      CACHE_MAX_SIZE: "1000"
</#if>
```

- [ ] **Step 2: configmap.yaml.ftl — add CB + cache blocks**

After the audit log ConfigMap block, add:

```yaml
<#if (flags.enableCircuitBreaker)!false>
  # ── Circuit breaker + retry ──────────────────────────────────────────────────
  CB_FAILURE_RATE_THRESHOLD: "50"
  CB_WAIT_DURATION_SECONDS: "30"
  CB_SLIDING_WINDOW_SIZE: "10"
  CB_RETRY_MAX_ATTEMPTS: "3"
  CB_RETRY_WAIT_MS: "500"
</#if>
<#if (flags.enableResponseCache)!false>
  # ── Response cache ────────────────────────────────────────────────────────────
  CACHE_TTL_SECONDS: "60"
  CACHE_MAX_SIZE: "1000"
</#if>
```

---

## Task 9: Parser tests — 6 new tests

**Files:**
- Modify: `apibridge-generator/src/test/java/com/apibridge/engine/YamlParserTest.java`

- [ ] **Step 1: Add 6 tests in the enableAuditLog section (after the existing 3 audit tests)**

```java
@Test
public void testEnableCircuitBreakerDefaultsFalse(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags: {}
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertFalse(model.getFlags().isEnableCircuitBreaker(), "enableCircuitBreaker must default to false");
}

@Test
public void testEnableCircuitBreakerExplicitTrue(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableCircuitBreaker: true
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertTrue(model.getFlags().isEnableCircuitBreaker());
}

@Test
public void testEnableCircuitBreakerExplicitFalse(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableCircuitBreaker: false
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertFalse(model.getFlags().isEnableCircuitBreaker());
}

@Test
public void testEnableResponseCacheDefaultsFalse(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags: {}
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertFalse(model.getFlags().isEnableResponseCache(), "enableResponseCache must default to false");
}

@Test
public void testEnableResponseCacheExplicitTrue(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableResponseCache: true
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertTrue(model.getFlags().isEnableResponseCache());
}

@Test
public void testEnableResponseCacheExplicitFalse(@TempDir Path tempDir) throws Exception {
    File file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableResponseCache: false
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertFalse(model.getFlags().isEnableResponseCache());
}
```

- [ ] **Step 2: Run tests**

```bash
cd apibridge-generator && mvn test -q
```

Expected: `BUILD SUCCESS` — 125/125 PASS

---

## Task 10: Engine tests — 12 new tests

**Files:**
- Modify: `apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeCartridgeEngineTest.java`

- [ ] **Step 1: Add helper `createTestModel()` doesn't need changes — `enableCircuitBreaker` and `enableResponseCache` default to false, which is correct for existing tests**

- [ ] **Step 2: Add 6 circuit breaker engine tests**

```java
// --- Circuit breaker cartridge tests ---

@Test
public void testSpringBootPomContainsCircuitBreakerDep(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertTrue(pom.contains("resilience4j-circuitbreaker"), "Spring Boot pom must include resilience4j-circuitbreaker");
    assertTrue(pom.contains("resilience4j-retry"), "Spring Boot pom must include resilience4j-retry");
}

@Test
public void testSpringBootPomNoCircuitBreakerDepWhenDisabled(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(false);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertFalse(pom.contains("resilience4j-circuitbreaker"), "No CB dep when flag off");
}

@Test
public void testSpringBootProxyServiceContainsCircuitBreakerCode(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath()
            .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
    assertTrue(content.contains("CircuitBreaker"), "ProxyService must reference CircuitBreaker");
    assertTrue(content.contains("Retry"), "ProxyService must reference Retry");
    assertTrue(content.contains("CallNotPermittedException"), "ProxyService must catch CallNotPermittedException");
    assertTrue(content.contains("Service Unavailable"), "ProxyService must return 503 fallback");
}

@Test
public void testQuarkusPomContainsCircuitBreakerDep(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/quarkus");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertTrue(pom.contains("resilience4j-circuitbreaker"), "Quarkus pom must include resilience4j-circuitbreaker");
    assertTrue(pom.contains("resilience4j-retry"), "Quarkus pom must include resilience4j-retry");
}

@Test
public void testQuarkusProxyServiceContainsCircuitBreakerCode(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/quarkus");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath()
            .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
    assertTrue(content.contains("CircuitBreaker"), "Quarkus ProxyService must reference CircuitBreaker");
    assertTrue(content.contains("CallNotPermittedException"), "Quarkus ProxyService must catch CallNotPermittedException");
}

@Test
public void testK8sConfigmapCircuitBreakerEnvVars(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableCircuitBreaker(true);
    File cartridgeDir = findCartridgeDir("devops/k8s/kubernetes");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath().resolve("k8s/configmap.yaml"));
    assertTrue(content.contains("CB_FAILURE_RATE_THRESHOLD"), "ConfigMap must have CB threshold env var");
    assertTrue(content.contains("CB_RETRY_MAX_ATTEMPTS"), "ConfigMap must have CB retry env var");
}
```

- [ ] **Step 3: Add 6 response cache engine tests**

```java
// --- Response cache cartridge tests ---

@Test
public void testSpringBootPomContainsCacheDep(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertTrue(pom.contains("caffeine"), "Spring Boot pom must include caffeine when cache enabled");
}

@Test
public void testSpringBootPomNoCacheDepWhenDisabled(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(false);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertFalse(pom.contains("caffeine"), "No caffeine dep when cache disabled");
}

@Test
public void testSpringBootProxyServiceContainsCacheCode(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/spring-boot");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath()
            .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
    assertTrue(content.contains("responseCache"), "ProxyService must have responseCache field");
    assertTrue(content.contains("getIfPresent"), "ProxyService must check cache on GET");
    assertTrue(content.contains("invalidateAll"), "ProxyService must evict cache on non-GET");
}

@Test
public void testQuarkusPomContainsCacheDep(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/quarkus");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
    assertTrue(pom.contains("caffeine"), "Quarkus pom must include caffeine when cache enabled");
}

@Test
public void testQuarkusProxyServiceContainsCacheCode(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(true);
    model.getFlags().setEnableTelemetry(false);
    File cartridgeDir = findCartridgeDir("backend/quarkus");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath()
            .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
    assertTrue(content.contains("responseCache"), "Quarkus ProxyService must have responseCache field");
    assertTrue(content.contains("getIfPresent"), "Quarkus ProxyService must check cache on GET");
}

@Test
public void testDockerComposeResponseCacheEnvVars(@TempDir Path tempDir) throws Exception {
    BridgeSchemaModel model = createTestModel();
    model.getFlags().setEnableResponseCache(true);
    File cartridgeDir = findCartridgeDir("devops/docker-compose");
    File outputDir = tempDir.resolve("out").toFile();
    engine.generate(model, cartridgeDir, outputDir);

    String content = Files.readString(outputDir.toPath().resolve("docker-compose.yml"));
    assertTrue(content.contains("CACHE_TTL_SECONDS"), "docker-compose must have CACHE_TTL_SECONDS");
    assertTrue(content.contains("CACHE_MAX_SIZE"), "docker-compose must have CACHE_MAX_SIZE");
}
```

- [ ] **Step 4: Run all tests**

```bash
cd apibridge-generator && mvn test -q
```

Expected: `BUILD SUCCESS` — 131/131 PASS

- [ ] **Step 5: Commit all implementation work**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java \
        apibridge-cartridges/backend/spring-boot/ \
        apibridge-cartridges/backend/quarkus/ \
        apibridge-cartridges/devops/docker-compose/docker-compose.yml.ftl \
        apibridge-cartridges/devops/k8s/kubernetes/configmap.yaml.ftl \
        apibridge-generator/src/test/java/com/apibridge/engine/YamlParserTest.java \
        apibridge-generator/src/test/java/com/apibridge/engine/ApiBridgeCartridgeEngineTest.java
git commit -m "feat: Phase 5 — enableCircuitBreaker and enableResponseCache flags"
```

---

## Task 11: Docs + sample-schema

**Files:**
- Modify: `sample-schema.yaml`
- Modify: `docs/schema-reference.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `HANDOFF.md`
- Modify: `TODO.md`

- [ ] **Step 1: sample-schema.yaml — add both flags**

Add to the `flags:` block:

```yaml
  enableCircuitBreaker: true
  enableResponseCache: true
```

- [ ] **Step 2: schema-reference.md — add two rows to flags table**

After the `enableAuditLog` row:

```
| `enableCircuitBreaker` | boolean | `false` | `true` \| `false` | When `true`, wraps all proxy calls with a Resilience4j circuit breaker + retry. Circuit opens after `CB_FAILURE_RATE_THRESHOLD`% failures in a `CB_SLIDING_WINDOW_SIZE`-call window; stays open for `CB_WAIT_DURATION_SECONDS`s. Returns `503 {"error":"Service Unavailable","circuit":"open"}` when open. Retry fires before the CB counts a failure; up to `CB_RETRY_MAX_ATTEMPTS` attempts with `CB_RETRY_WAIT_MS`ms wait. |
| `enableResponseCache` | boolean | `false` | `true` \| `false` | When `true`, caches GET proxy responses in-process using Caffeine. Cache key = full request URL + query string. TTL = `CACHE_TTL_SECONDS` (default 60). Max entries = `CACHE_MAX_SIZE` (default 1000, LRU eviction). Non-GET requests (PUT/POST/DELETE/PATCH) invalidate the entire cache. No additional infrastructure required. |
```

- [ ] **Step 3: README.md — add rows to template variables table and flags YAML example**

In the template variables table, after `flags.enableAuditLog`:

```
| `flags.enableCircuitBreaker` | boolean | `true` wraps all proxy calls with Resilience4j CB + retry; configurable via `CB_*` ENV VARs |
| `flags.enableResponseCache` | boolean | `true` adds Caffeine in-process GET cache; configurable via `CACHE_*` ENV VARs |
```

In the full flags YAML example, add:

```yaml
  enableCircuitBreaker: true
  enableResponseCache: true
```

- [ ] **Step 4: CHANGELOG.md — add [Unreleased] section**

Add above the existing `[Unreleased]` content (or replace if empty):

```markdown
## [Unreleased]

### Added — Circuit breaker + retry (`flags.enableCircuitBreaker`)

- New schema flag `flags.enableCircuitBreaker: true` generates Resilience4j circuit breaker + retry wrapping every upstream proxy call.
- **Spring Boot**: `resilience4j-circuitbreaker` + `resilience4j-retry` added to `pom.xml`. `ProxyService` initializes `CircuitBreaker` + `Retry` programmatically from ENV VARs in constructor.
- **Quarkus**: Same dependencies + `@PostConstruct` initialization.
- Circuit opens after `CB_FAILURE_RATE_THRESHOLD`% failures in `CB_SLIDING_WINDOW_SIZE` calls; stays open `CB_WAIT_DURATION_SECONDS`s. Returns `503 {"error":"Service Unavailable","circuit":"open"}` on open circuit.
- Retry fires up to `CB_RETRY_MAX_ATTEMPTS` times with `CB_RETRY_WAIT_MS`ms wait between attempts, BEFORE the CB counts a failure.
- `docker-compose.yml.ftl` + `configmap.yaml.ftl` gain conditional `CB_*` ENV VAR blocks.
- 9 new tests: `YamlParserTest` (3 flag parsing) + `ApiBridgeCartridgeEngineTest` (6 cartridge assertions).

### Added — Response cache (`flags.enableResponseCache`)

- New schema flag `flags.enableResponseCache: true` generates an in-process Caffeine GET response cache in `ProxyService`. No additional infrastructure required.
- **Spring Boot**: `caffeine` added to `pom.xml` (version managed by Spring Boot BOM). Cache built in constructor with TTL + max-size from ENV VARs.
- **Quarkus**: `caffeine:3.1.8` added to `pom.xml`. Cache built in `@PostConstruct init()`.
- Cache key = full request URL + query string. GET hit → return immediately without upstream call. Non-GET request → `invalidateAll()` for consistency.
- `docker-compose.yml.ftl` + `configmap.yaml.ftl` gain conditional `CACHE_*` ENV VAR blocks.
- 9 new tests: `YamlParserTest` (3 flag parsing) + `ApiBridgeCartridgeEngineTest` (6 cartridge assertions).
- Test count: 119 → 131.
```

- [ ] **Step 5: HANDOFF.md — update test count and move planned → implemented**

Replace "Planned features (Phase 5)" section with implementation details, update test count to 131.

- [ ] **Step 6: TODO.md — mark Phase 5 complete**

Replace Phase 5 content with:

```markdown
All Phase 1, 2, 3, 4, and 5 items are complete. See CHANGELOG.md for details.

There are no remaining backlog items.
```

- [ ] **Step 7: Commit docs**

```bash
git add sample-schema.yaml docs/schema-reference.md README.md CHANGELOG.md HANDOFF.md TODO.md
git commit -m "docs: Phase 5 complete — update schema-reference, README, CHANGELOG, HANDOFF, TODO"
```

- [ ] **Step 8: Push**

```bash
git push
```
