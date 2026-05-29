package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class HealthCheckEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootGeneratesHealthCheckService(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/HealthCheckService.java"));
        assertTrue(content.contains("HealthCheckService"), "must generate HealthCheckService");
        assertTrue(content.contains("runHealthChecks"), "must have scheduled probe method");
    }

    @Test
    public void testSpringBootGeneratesBridgeHealthController(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeHealthController.java"));
        assertTrue(content.contains("BridgeHealthController"), "must generate BridgeHealthController");
        assertTrue(content.contains("/bridge-health"), "must expose /api/bridge-health endpoint");
    }

    @Test
    public void testQuarkusGeneratesHealthCheckService(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/HealthCheckService.java"));
        assertTrue(content.contains("HealthCheckService"), "must generate HealthCheckService");
        assertTrue(content.contains("@Scheduled"), "must have Quarkus @Scheduled");
    }

    @Test
    public void testQuarkusGeneratesBridgeHealthResource(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeHealthResource.java"));
        assertTrue(content.contains("BridgeHealthResource"), "must generate BridgeHealthResource");
        assertTrue(content.contains("/bridge-health"), "must expose /api/bridge-health");
    }

    @Test
    public void testBridgeConfigContainsEnableHealthCheck(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeConfigController.java"));
        assertTrue(content.contains("enableHealthCheck"), "BridgeConfigController must expose enableHealthCheck");
    }

    @Test
    public void testDockerComposeContainsHealthCheckEnvVars(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("HEALTH_CHECK_INTERVAL_SECONDS"), "docker-compose must have HEALTH_CHECK_INTERVAL_SECONDS");
        assertTrue(content.contains("HEALTH_CHECK_TIMEOUT_MS"), "docker-compose must have HEALTH_CHECK_TIMEOUT_MS");
    }

    @Test
    public void testConfigmapContainsHealthCheckEnvVars(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableHealthCheck(true);
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("HEALTH_CHECK_INTERVAL_SECONDS"), "configmap must have HEALTH_CHECK_INTERVAL_SECONDS");
    }
}
