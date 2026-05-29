package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class MockModeEngineTest extends ApiBridgeCartridgeEngineTestBase {

    private BridgeSchemaModel createMockResponseTestModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("mock-service");
        model.setBasePath("/api/mock");
        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(false);
        model.setFlags(flags);
        BridgeSchemaModel.Endpoint endpoint = new BridgeSchemaModel.Endpoint();
        endpoint.setPath("/items");
        endpoint.setMethod("GET");
        endpoint.setBackendUrl("https://upstream.example.com/items");
        BridgeSchemaModel.MockResponse mock = new BridgeSchemaModel.MockResponse();
        mock.setStatusCode(201);
        mock.setBody("{\"status\":\"ok\"}");
        mock.setDelayMs(0);
        endpoint.setMockResponse(mock);
        model.setEndpoints(java.util.List.of(endpoint));
        return model;
    }

    @Test
    public void testSpringBootControllerUsesSchemaDefinedMockBody(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createMockResponseTestModel();
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/spring-boot"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("status\\\":\\\"ok\\\"") || content.contains("{\\\"status\\\":\\\"ok\\\"}"),
                "BridgeController must contain schema-defined mock body");
        assertTrue(content.contains("ResponseEntity.status(201)"), "BridgeController must use schema-defined status code 201");
    }

    @Test
    public void testQuarkusResourceUsesSchemaDefinedMockBody(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createMockResponseTestModel();
        model.getFlags().setEnableTelemetry(false);
        engine.generate(model, findCartridgeDir("backend/quarkus"), tempDir.resolve("out").toFile());

        String content = Files.readString(tempDir.resolve("out/backend/src/main/java/com/apibridge/generated/BridgeResource.java"));
        assertTrue(content.contains("status\\\":\\\"ok\\\"") || content.contains("{\\\"status\\\":\\\"ok\\\"}"),
                "BridgeResource must contain schema-defined mock body");
        assertTrue(content.contains("Response.status(201)"), "BridgeResource must use schema-defined status code 201");
    }
}
