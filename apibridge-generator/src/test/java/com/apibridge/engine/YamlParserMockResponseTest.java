package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserMockResponseTest extends YamlParserTestBase {

    @Test
    public void testMockResponseValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    mockResponse:
                      statusCode: 201
                      body: '{"status":"ok"}'
                      delayMs: 100
                """);
        BridgeSchemaModel model = parser.parse(file);
        BridgeSchemaModel.MockResponse mock = model.getEndpoints().get(0).getMockResponse();
        assertEquals(201, mock.getStatusCode());
        assertEquals("{\"status\":\"ok\"}", mock.getBody());
        assertEquals(100, mock.getDelayMs());
    }

    @Test
    public void testMockResponseInvalidStatusCodeThrows(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    mockResponse:
                      statusCode: 99
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("statusCode"));
    }

    @Test
    public void testMockResponseStatusCode600Throws(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    mockResponse:
                      statusCode: 600
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("statusCode"));
    }

    @Test
    public void testMockResponseNegativeDelayThrows(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    mockResponse:
                      delayMs: -1
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("delayMs"));
    }
}
