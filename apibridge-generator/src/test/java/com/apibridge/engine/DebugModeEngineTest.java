package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class DebugModeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootDebugFilterGenerated(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        Path filterFile = tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/DebugLoggingFilter.java");
        assertTrue(Files.exists(filterFile), "DebugLoggingFilter.java must be generated");
        String content = Files.readString(filterFile);
        assertTrue(content.contains("OncePerRequestFilter"), "must extend OncePerRequestFilter");
        assertTrue(content.contains("debugMode"), "must check debugMode flag");
    }

    @Test
    public void testQuarkusDebugFilterGenerated(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        Path filterFile = tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/DebugLoggingFilter.java");
        assertTrue(Files.exists(filterFile), "DebugLoggingFilter.java must be generated");
        String content = Files.readString(filterFile);
        assertTrue(content.contains("ContainerRequestFilter"), "must implement ContainerRequestFilter");
        assertTrue(content.contains("ContainerResponseFilter"), "must implement ContainerResponseFilter");
    }

    @Test
    public void testDockerComposeContainsDebugMode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/docker-compose"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/docker-compose.yml"));
        assertTrue(content.contains("DEBUG_MODE"), "docker-compose must have DEBUG_MODE");
    }

    @Test
    public void testK8sConfigmapContainsDebugMode(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        engine.generate(model, findCartridgeDir("devops/k8s/kubernetes"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/k8s/configmap.yaml"));
        assertTrue(content.contains("DEBUG_MODE"), "configmap must have DEBUG_MODE");
    }
}
