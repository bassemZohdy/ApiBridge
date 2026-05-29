package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class ApiVersioningEngineTest extends ApiBridgeCartridgeEngineTestBase {

    @Test
    public void testSpringBootControllerHasVersionPrefix(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setApiVersion("v1");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("/v1"), "BridgeController must include /v1 version prefix");
        assertTrue(content.contains("@RequestMapping"), "BridgeController must have @RequestMapping");
    }

    @Test
    public void testQuarkusResourceHasVersionPrefix(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setApiVersion("v1");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeResource.java"));
        assertTrue(content.contains("/v1"), "BridgeResource must include /v1 version prefix");
        assertTrue(content.contains("@Path"), "BridgeResource must have @Path");
    }

    @Test
    public void testReactBridgeApiIncludesVersionPrefix(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setApiVersion("v1");
        engine.generate(model, findCartridgeDir("frontend/react"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/frontend/src/api/bridgeApi.ts"));
        assertTrue(content.contains("/v1"), "bridgeApi.ts must include /v1 version prefix in URL");
    }

    @Test
    public void testBridgeConfigControllerContainsApiVersion(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setApiVersion("v1");
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeConfigController.java"));
        assertTrue(content.contains("apiVersion"), "BridgeConfigController must expose apiVersion in config response");
        assertTrue(content.contains("v1"), "BridgeConfigController must contain the versioned value");
    }
}
