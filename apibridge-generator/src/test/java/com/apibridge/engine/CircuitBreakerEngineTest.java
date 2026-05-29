package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class CircuitBreakerEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootPomContainsCircuitBreakerDep(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableCircuitBreaker(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("resilience4j-circuitbreaker"), "Spring Boot pom must include resilience4j-circuitbreaker");
        assertTrue(pom.contains("resilience4j-retry"), "Spring Boot pom must include resilience4j-retry");
    }

    @Test
    public void testSpringBootPomNoCircuitBreakerDepWhenDisabled(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableCircuitBreaker(false);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertFalse(pom.contains("resilience4j-circuitbreaker"), "No CB dep when flag off");
    }

    @Test
    public void testSpringBootProxyServiceContainsCircuitBreakerCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableCircuitBreaker(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
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
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String pom = Files.readString(tempDir.resolve("out/backend/pom.xml"));
        assertTrue(pom.contains("resilience4j-circuitbreaker"), "Quarkus pom must include resilience4j-circuitbreaker");
        assertTrue(pom.contains("resilience4j-retry"), "Quarkus pom must include resilience4j-retry");
    }

    @Test
    public void testQuarkusProxyServiceContainsCircuitBreakerCode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableCircuitBreaker(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(content.contains("CircuitBreaker"), "Quarkus ProxyService must reference CircuitBreaker");
        assertTrue(content.contains("CallNotPermittedException"), "Quarkus ProxyService must catch CallNotPermittedException");
    }

    @Test
    public void testK8sConfigmapCircuitBreakerEnvVars(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableCircuitBreaker(true);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("CB_FAILURE_RATE_THRESHOLD"), "ConfigMap must have CB threshold env var");
        assertTrue(content.contains("CB_RETRY_MAX_ATTEMPTS"), "ConfigMap must have CB retry env var");
    }
}
