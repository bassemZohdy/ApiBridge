package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class RateLimiterEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootPomContainsRateLimiterDep(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("resilience4j-ratelimiter"), "Spring Boot pom must include resilience4j-ratelimiter");
    }

    @Test
    public void testSpringBootPomNoRateLimiterDepWhenDisabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertFalse(pom.contains("resilience4j-ratelimiter"), "No rate limiter dep when flag off");
    }

    @Test
    public void testSpringBootProxyServiceContainsRateLimiterCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("RateLimiter"), "ProxyService must reference RateLimiter");
        assertTrue(content.contains("RequestNotPermitted"), "ProxyService must catch RequestNotPermitted");
        assertTrue(content.contains("Too Many Requests"), "ProxyService must return 429 fallback");
    }

    @Test
    public void testQuarkusPomContainsRateLimiterDep(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("resilience4j-ratelimiter"), "Quarkus pom must include resilience4j-ratelimiter");
    }

    @Test
    public void testQuarkusProxyServiceContainsRateLimiterCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("RateLimiter"), "Quarkus ProxyService must reference RateLimiter");
        assertTrue(content.contains("RequestNotPermitted"), "Quarkus ProxyService must catch RequestNotPermitted");
    }

    @Test
    public void testDockerComposeRateLimiterEnvVars(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableRateLimiter(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("RATE_LIMIT_PERMITS"), "docker-compose must have RATE_LIMIT_PERMITS");
        assertTrue(content.contains("RATE_LIMIT_PERIOD_SECONDS"), "docker-compose must have RATE_LIMIT_PERIOD_SECONDS");
    }
}
