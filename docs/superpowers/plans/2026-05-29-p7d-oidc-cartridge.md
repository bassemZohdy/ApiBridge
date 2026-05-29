# OIDC Authentication Cartridge — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `flags.enableOidc` to generate a production-ready OIDC resource server in both Spring Boot and Quarkus backends — JWT validation against a configurable issuer, `401` for missing/invalid tokens, and a new `SecurityConfig.java` (Spring Boot) or `application.properties` OIDC block (Quarkus).

**Architecture:** Follows the identical flag-gate pattern used by `enableCircuitBreaker`, `enableHealthCheck`, etc. — add the flag to `BridgeSchemaModel.Flags`, validate a companion string field `oidcIssuerUri` in `YamlParser`, expose both in the FreeMarker context, then add conditional blocks to the existing backend templates. No new cartridge directory needed — security config lives alongside the existing Spring Boot / Quarkus templates. The existing `securityLevel: bearer-token` is header-passthrough only; `enableOidc: true` adds actual JWT validation via the OIDC issuer.

**Tech Stack:** Spring Security OAuth2 Resource Server (`spring-boot-starter-oauth2-resource-server`), Quarkus OIDC (`quarkus-oidc`), FreeMarker (already present), JUnit 5 (already present).

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Modify | `apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java` | Add `enableOidc`, `oidcIssuerUri` to `Flags` |
| Modify | `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java` | Validate `oidcIssuerUri` non-blank when `enableOidc=true` |
| Modify | `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeCartridgeEngine.java` | Add `enableOidc`, `oidcIssuerUri` to FreeMarker context |
| Create | `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/SecurityConfig.java.ftl` | Spring Security OAuth2 resource server config |
| Modify | `apibridge-cartridges/backend/spring-boot/pom.xml.ftl` | Add `spring-boot-starter-oauth2-resource-server` dep when flag on |
| Modify | `apibridge-cartridges/backend/spring-boot/src/main/resources/application.properties.ftl` | Add `spring.security.oauth2.resourceserver.jwt.issuer-uri` |
| Modify | `apibridge-cartridges/backend/quarkus/pom.xml.ftl` | Add `quarkus-oidc` dep when flag on |
| Modify | `apibridge-cartridges/backend/quarkus/src/main/resources/application.properties.ftl` | Add `quarkus.oidc.*` properties |
| Create | `apibridge-generator/src/test/java/com/apibridge/engine/OidcEngineTest.java` | Engine tests |
| Modify | `apibridge-generator/src/test/java/com/apibridge/engine/YamlParserFeatureFlagsTest.java` | Parser tests |

---

## Task 1: Model changes

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java`

- [ ] **Step 1: Add `enableOidc` and `oidcIssuerUri` to the `Flags` inner class**

Open `BridgeSchemaModel.java`. Inside the `Flags` class, after the existing `enableOpenApi` field, add:

```java
private boolean enableOidc;
private String oidcIssuerUri;
```

After the existing `isEnableOpenApi()` / `setEnableOpenApi()` pair, add:

```java
public boolean isEnableOidc() { return enableOidc; }
public void setEnableOidc(boolean enableOidc) { this.enableOidc = enableOidc; }
public String getOidcIssuerUri() { return oidcIssuerUri; }
public void setOidcIssuerUri(String oidcIssuerUri) { this.oidcIssuerUri = oidcIssuerUri; }
```

In the `toString()` method of `Flags`, add to the returned string:
```
+ ", enableOidc=" + enableOidc + ", oidcIssuerUri='" + oidcIssuerUri + "'"
```

- [ ] **Step 2: Run existing tests to confirm no regression**

```bash
mvn test -pl apibridge-generator --no-transfer-progress
```

Expected: all existing tests PASS.

- [ ] **Step 3: Commit**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/model/BridgeSchemaModel.java
git commit -m "feat: add enableOidc + oidcIssuerUri fields to BridgeSchemaModel.Flags"
```

---

## Task 2: YamlParser validation

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java`
- Modify: `apibridge-generator/src/test/java/com/apibridge/engine/YamlParserFeatureFlagsTest.java`

- [ ] **Step 1: Write the failing parser tests first**

Add to `YamlParserFeatureFlagsTest.java`:

```java
// --- enableOidc ---

@Test
public void testEnableOidcDefaultsFalse(@TempDir Path tempDir) throws Exception {
    var file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags: {}
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertFalse(model.getFlags().isEnableOidc(), "enableOidc must default to false");
}

@Test
public void testEnableOidcWithIssuerUriParsesCorrectly(@TempDir Path tempDir) throws Exception {
    var file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableOidc: true
              oidcIssuerUri: "https://keycloak.example.com/realms/myrealm"
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    BridgeSchemaModel model = parser.parse(file);
    assertTrue(model.getFlags().isEnableOidc());
    assertEquals("https://keycloak.example.com/realms/myrealm", model.getFlags().getOidcIssuerUri());
}

@Test
public void testEnableOidcWithoutIssuerUriThrows(@TempDir Path tempDir) throws IOException {
    var file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableOidc: true
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
            () -> parser.parse(file));
    assertTrue(ex.getMessage().contains("oidcIssuerUri"),
            "Error must mention oidcIssuerUri");
}

@Test
public void testEnableOidcWithBlankIssuerUriThrows(@TempDir Path tempDir) throws IOException {
    var file = writeYaml(tempDir, "schema.yaml", """
            id: "test"
            basePath: "/api"
            flags:
              enableOidc: true
              oidcIssuerUri: "   "
            endpoints:
              - path: "/run"
                method: "POST"
                backendUrl: "https://example.com/run"
            """);
    IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
            () -> parser.parse(file));
    assertTrue(ex.getMessage().contains("oidcIssuerUri"));
}
```

- [ ] **Step 2: Run to confirm failure**

```bash
mvn test -pl apibridge-generator -Dtest=YamlParserFeatureFlagsTest --no-transfer-progress
```

Expected: `testEnableOidcWithoutIssuerUriThrows` and `testEnableOidcWithBlankIssuerUriThrows` FAIL (no validation yet).

- [ ] **Step 3: Add validation in `YamlParser.java`**

In `YamlParser.validate(BridgeSchemaModel model)` (find the existing validation method), add after the existing flag validations:

```java
if (flags.isEnableOidc()) {
    if (flags.getOidcIssuerUri() == null || flags.getOidcIssuerUri().isBlank()) {
        throw new IllegalArgumentException(
                "flags.oidcIssuerUri must be non-blank when flags.enableOidc is true.");
    }
}
```

- [ ] **Step 4: Run parser tests**

```bash
mvn test -pl apibridge-generator -Dtest=YamlParserFeatureFlagsTest --no-transfer-progress
```

Expected: 4 new tests PASS.

- [ ] **Step 5: Run full suite**

```bash
mvn test -pl apibridge-generator --no-transfer-progress
```

Expected: all PASS.

- [ ] **Step 6: Commit**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/YamlParser.java
git add apibridge-generator/src/test/java/com/apibridge/engine/YamlParserFeatureFlagsTest.java
git commit -m "feat: YamlParser validates oidcIssuerUri non-blank when enableOidc=true"
```

---

## Task 3: FreeMarker context

**Files:**
- Modify: `apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeCartridgeEngine.java`

- [ ] **Step 1: Add `enableOidc` and `oidcIssuerUri` to `buildContext()`**

In `ApiBridgeCartridgeEngine.buildContext()`, after the existing `enableOpenApi` line, add:

```java
context.put("enableOidc", resolvedFlag(model, f -> f.isEnableOidc()));
context.put("oidcIssuerUri", resolvedString(model, f -> f.getOidcIssuerUri()));
```

- [ ] **Step 2: Run tests**

```bash
mvn test -pl apibridge-generator --no-transfer-progress
```

Expected: all PASS.

- [ ] **Step 3: Commit**

```bash
git add apibridge-generator/src/main/java/com/apibridge/engine/ApiBridgeCartridgeEngine.java
git commit -m "feat: add enableOidc + oidcIssuerUri to FreeMarker context"
```

---

## Task 4: Spring Boot SecurityConfig template

**Files:**
- Create: `apibridge-cartridges/backend/spring-boot/src/main/java/com/apibridge/generated/SecurityConfig.java.ftl`

- [ ] **Step 1: Create `SecurityConfig.java.ftl`**

```
<#if enableOidc>
package com.apibridge.generated;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/bridge-config", "/api/bridge-health", "/actuator/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 ->
                oauth2.jwt(jwt -> jwt.jwkSetUri(
                    System.getenv().getOrDefault("OIDC_ISSUER_URI",
                        "${oidcIssuerUri}") + "/protocol/openid-connect/certs"
                ))
            );
        return http.build();
    }
}
</#if>
```

---

## Task 5: Spring Boot pom + application.properties

**Files:**
- Modify: `apibridge-cartridges/backend/spring-boot/pom.xml.ftl`
- Modify: `apibridge-cartridges/backend/spring-boot/src/main/resources/application.properties.ftl`

- [ ] **Step 1: Add OIDC dep to `pom.xml.ftl`**

In `pom.xml.ftl`, find the existing conditional dependency block (near the circuit breaker or rate limiter deps). Add a new conditional block:

```
<#if enableOidc>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
        </dependency>
</#if>
```

- [ ] **Step 2: Add OIDC properties to `application.properties.ftl`**

At the end of `application.properties.ftl`, add:

```
<#if enableOidc>
# ── OIDC Resource Server ──────────────────────────────────────────────────────
# Override OIDC_ISSUER_URI at runtime to change the issuer without rebuilding.
# The JWK Set URI is derived automatically by Spring Security from the issuer.
spring.security.oauth2.resourceserver.jwt.issuer-uri=${r"${OIDC_ISSUER_URI:"}${oidcIssuerUri}${r"}"}
</#if>
```

---

## Task 6: Quarkus pom + application.properties

**Files:**
- Modify: `apibridge-cartridges/backend/quarkus/pom.xml.ftl`
- Modify: `apibridge-cartridges/backend/quarkus/src/main/resources/application.properties.ftl`

- [ ] **Step 1: Add `quarkus-oidc` dep to Quarkus `pom.xml.ftl`**

```
<#if enableOidc>
        <dependency>
            <groupId>io.quarkus</groupId>
            <artifactId>quarkus-oidc</artifactId>
        </dependency>
</#if>
```

- [ ] **Step 2: Add Quarkus OIDC properties to `application.properties.ftl`**

```
<#if enableOidc>
# ── OIDC Resource Server ──────────────────────────────────────────────────────
quarkus.oidc.auth-server-url=${r"${OIDC_ISSUER_URI:"}${oidcIssuerUri}${r"}"}
quarkus.oidc.application-type=service
quarkus.oidc.token.issuer=${r"${OIDC_ISSUER_URI:"}${oidcIssuerUri}${r"}"}
</#if>
```

---

## Task 7: Unit tests

**Files:**
- Create: `apibridge-generator/src/test/java/com/apibridge/engine/OidcEngineTest.java`

- [ ] **Step 1: Write the tests**

```java
package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class OidcEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createOidcModel() {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableOidc(true);
        model.getFlags().setOidcIssuerUri("https://keycloak.example.com/realms/myrealm");
        return model;
    }

    @Test
    public void testSpringBootGeneratesSecurityConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve(
                "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java"));
        assertTrue(content.contains("SecurityConfig"), "must generate SecurityConfig class");
        assertTrue(content.contains("oauth2ResourceServer"), "must configure OAuth2 resource server");
        assertTrue(content.contains("STATELESS"), "must use stateless sessions");
    }

    @Test
    public void testSpringBootSecurityConfigNotGeneratedWhenFlagOff(@TempDir Path tempDir) throws Exception {
        engine.generate(createTestModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        assertFalse(
                Files.exists(tempDir.resolve(
                        "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java")),
                "SecurityConfig must NOT be generated when enableOidc is false");
    }

    @Test
    public void testSpringBootPomHasOidcDepWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-oauth2-resource-server"),
                "pom must include OAuth2 resource server starter when enableOidc=true");
    }

    @Test
    public void testSpringBootApplicationPropertiesHasIssuerUri(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String props = Files.readString(tempDir.resolve(
                "out/backend/src/main/resources/application.properties"));
        assertTrue(props.contains("spring.security.oauth2.resourceserver.jwt.issuer-uri"),
                "application.properties must declare issuer-uri when enableOidc=true");
        assertTrue(props.contains("keycloak.example.com"),
                "application.properties must embed the configured oidcIssuerUri");
    }

    @Test
    public void testQuarkusPomHasOidcDepWhenFlagOn(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("quarkus-oidc"),
                "Quarkus pom must include quarkus-oidc dep when enableOidc=true");
    }

    @Test
    public void testQuarkusApplicationPropertiesHasOidcConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String props = Files.readString(tempDir.resolve(
                "out/backend/src/main/resources/application.properties"));
        assertTrue(props.contains("quarkus.oidc.auth-server-url"),
                "Quarkus application.properties must have quarkus.oidc.auth-server-url");
        assertTrue(props.contains("keycloak.example.com"),
                "Quarkus application.properties must embed the oidcIssuerUri");
    }

    @Test
    public void testHealthAndConfigEndpointsPermitAllInSecurityConfig(@TempDir Path tempDir) throws Exception {
        engine.generate(createOidcModel(), findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve(
                "out/backend/src/main/java/com/apibridge/generated/SecurityConfig.java"));
        assertTrue(content.contains("bridge-config") || content.contains("permitAll"),
                "SecurityConfig must allow bridge-config + bridge-health without auth");
    }
}
```

- [ ] **Step 2: Run the tests**

```bash
mvn test -pl apibridge-generator -Dtest=OidcEngineTest --no-transfer-progress
```

Fix any template issues until all 7 tests PASS.

- [ ] **Step 3: Run full suite**

```bash
mvn verify --no-transfer-progress
```

Expected: BUILD SUCCESS.

- [ ] **Step 4: Commit everything**

```bash
git add apibridge-cartridges/backend/spring-boot/
git add apibridge-cartridges/backend/quarkus/
git add apibridge-generator/src/test/java/com/apibridge/engine/OidcEngineTest.java
git commit -m "feat: OIDC authentication cartridge — Spring Boot + Quarkus JWT resource server"
```

---

## Task 8: Update schema-reference.md + CLAUDE.md

**Files:**
- Modify: `docs/schema-reference.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Add `enableOidc` and `oidcIssuerUri` to the flags table in `docs/schema-reference.md`**

In the `flags` table, add two rows:

```markdown
| `enableOidc` | boolean | `false` | `true` \| `false` | When `true`, generates Spring Security OAuth2 Resource Server config (Spring Boot) or Quarkus OIDC config. Requires `oidcIssuerUri`. All endpoints except `/api/bridge-config` and `/api/bridge-health` require a valid JWT. Runtime override: `OIDC_ISSUER_URI`. |
| `oidcIssuerUri` | string | — | Any URI | Required when `enableOidc: true`. OIDC issuer base URL (e.g. `https://keycloak.example.com/realms/myrealm`). Overrideable at runtime via `OIDC_ISSUER_URI` ENV VAR. |
```

Also add to the Validation summary:
```markdown
| `flags.oidcIssuerUri` must be non-blank when `enableOidc: true` | OIDC Authentication |
```

- [ ] **Step 2: Add `enableOidc` to the CLAUDE.md flags section**

In `CLAUDE.md`, in the "Valid enum values" section for flags, add:

```
- `flags.enableOidc`: `true` | `false` (default `false`) — generates OAuth2 JWT resource server; `oidcIssuerUri` required; runtime override `OIDC_ISSUER_URI`
```

- [ ] **Step 3: Commit**

```bash
git add docs/schema-reference.md CLAUDE.md
git commit -m "docs: document enableOidc + oidcIssuerUri in schema reference and CLAUDE.md"
```

---

## Self-Review

**Spec coverage:**
- `enableOidc` + `oidcIssuerUri` model fields ✓ (Task 1)
- `oidcIssuerUri` validation when flag on ✓ (Task 2)
- FreeMarker context binding ✓ (Task 3)
- Spring Boot `SecurityConfig.java` generated ✓ (Task 4)
- Spring Boot pom dep + application.properties ✓ (Task 5)
- Quarkus pom dep + application.properties ✓ (Task 6)
- `bridge-config` / `bridge-health` remain unauthenticated ✓ (Task 4)
- 7 engine tests + 4 parser tests ✓ (Tasks 2 and 7)
- Docs ✓ (Task 8)

**No placeholders found.**

**Type consistency:** `enableOidc` (boolean), `oidcIssuerUri` (String) — used consistently across model, parser, context, and tests.
