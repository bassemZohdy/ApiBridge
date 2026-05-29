package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserEndpointTest extends YamlParserTestBase {

    // --- Required endpoint fields ---

    @Test
    public void testMissingEndpointPathThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("path"));
    }

    @Test
    public void testMissingEndpointMethodThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("method"));
    }

    @Test
    public void testMissingEndpointBackendUrlThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("backendUrl"));
    }

    @Test
    public void testBlankEndpointPathThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "   "
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("path"));
    }

    @Test
    public void testBlankEndpointMethodThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "   "
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("method"));
    }

    @Test
    public void testBlankEndpointBackendUrlThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "   "
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[0]"));
        assertTrue(ex.getMessage().contains("backendUrl"));
    }

    @Test
    public void testSecondEndpointValidated(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/first"
                    method: "GET"
                    backendUrl: "https://example.com/first"
                  - path: "/second"
                    backendUrl: "https://example.com/second"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints[1]"));
        assertTrue(ex.getMessage().contains("method"));
    }

    // --- HTTP method coverage ---

    @Test
    public void testPatchMethodIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items/{id}"
                    method: "PATCH"
                    backendUrl: "https://example.com/items/1"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("PATCH", model.getEndpoints().get(0).getMethod());
    }

    @Test
    public void testInvalidMethodErrorMessageContainsMethodName(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "TRACE"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("TRACE"));
    }

    // --- Duplicate endpoint detection ---

    @Test
    public void testDuplicateEndpointLowercaseMethodDetected(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                  - path: "/items"
                    method: "get"
                    backendUrl: "https://example.com/items"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("Duplicate"));
    }

    // --- Telemetry validation ---

    @Test
    public void testTelemetryEnabledRequiresTelemetryName(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableTelemetry: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("telemetryName"));
    }

    @Test
    public void testBlankTelemetryNameThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableTelemetry: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    telemetryName: "   "
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("telemetryName"));
    }

    @Test
    public void testTelemetryNameOptionalWhenDisabled(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableTelemetry: false
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertNull(model.getEndpoints().get(0).getTelemetryName());
    }

    @Test
    public void testTelemetryEnabledSecondEndpointMissingNameThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  enableTelemetry: true
                endpoints:
                  - path: "/a"
                    method: "GET"
                    backendUrl: "https://example.com/a"
                    telemetryName: "span_a"
                  - path: "/b"
                    method: "POST"
                    backendUrl: "https://example.com/b"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("telemetryName"));
        assertTrue(ex.getMessage().contains("endpoints[1]"));
    }

    // --- T.3: Valid HTTP methods PUT / DELETE ---

    @Test
    public void testPutMethodIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items/{id}"
                    method: "PUT"
                    backendUrl: "https://example.com/items/1"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("PUT", model.getEndpoints().get(0).getMethod());
    }

    @Test
    public void testDeleteMethodIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items/{id}"
                    method: "DELETE"
                    backendUrl: "https://example.com/items/1"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("DELETE", model.getEndpoints().get(0).getMethod());
    }

    // --- T.4: Lowercase HTTP method accepted ---

    @Test
    public void testLowercaseGetMethodAccepted(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "get"
                    backendUrl: "https://example.com/items"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("get", model.getEndpoints().get(0).getMethod());
    }

    // --- T.5: Duplicate endpoint exact same case detected ---

    @Test
    public void testDuplicateEndpointExactSameCase(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items2"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("Duplicate"));
    }

    // --- T.6: Same path different methods allowed ---

    @Test
    public void testSamePathDifferentMethodsAllowed(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/items"
                    method: "GET"
                    backendUrl: "https://example.com/items"
                  - path: "/items"
                    method: "POST"
                    backendUrl: "https://example.com/items"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals(2, model.getEndpoints().size());
        assertEquals("GET", model.getEndpoints().get(0).getMethod());
        assertEquals("POST", model.getEndpoints().get(1).getMethod());
    }

    // --- T.30: telemetryName stored correctly on model ---

    @Test
    public void testTelemetryNameStoredOnModel(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  enableTelemetry: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    telemetryName: "my_span"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("my_span", model.getEndpoints().get(0).getTelemetryName());
    }
}
