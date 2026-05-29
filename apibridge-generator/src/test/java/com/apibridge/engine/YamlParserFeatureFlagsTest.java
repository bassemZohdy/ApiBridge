package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserFeatureFlagsTest extends YamlParserTestBase {

    // --- enableAuditLog ---

    @Test
    public void testEnableAuditLogDefaultsFalse(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        boolean auditEnabled = model.getFlags() != null && model.getFlags().isEnableAuditLog();
        assertFalse(auditEnabled, "enableAuditLog must default to false when flags absent");
    }

    @Test
    public void testEnableAuditLogParsedTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  enableAuditLog: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model.getFlags());
        assertTrue(model.getFlags().isEnableAuditLog());
    }

    @Test
    public void testEnableAuditLogExplicitFalse(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "svc"
                basePath: "/api"
                flags:
                  enableAuditLog: false
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertFalse(model.getFlags().isEnableAuditLog());
    }

    // --- enableCircuitBreaker ---

    @Test
    public void testEnableCircuitBreakerDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableCircuitBreaker(), "enableCircuitBreaker must default to false");
    }

    @Test
    public void testEnableCircuitBreakerExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
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
        var file = writeYaml(tempDir, "schema.yaml", """
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

    // --- enableResponseCache ---

    @Test
    public void testEnableResponseCacheDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableResponseCache(), "enableResponseCache must default to false");
    }

    @Test
    public void testEnableResponseCacheExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
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
        var file = writeYaml(tempDir, "schema.yaml", """
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

    // --- enableRateLimiter ---

    @Test
    public void testEnableRateLimiterDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableRateLimiter(), "enableRateLimiter must default to false");
    }

    @Test
    public void testEnableRateLimiterExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableRateLimiter: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableRateLimiter());
    }

    // --- apiVersion ---

    @Test
    public void testApiVersionValidV1(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  apiVersion: "v1"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("v1", model.getFlags().getApiVersion());
    }

    @Test
    public void testApiVersionValidV2(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  apiVersion: "v2"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("v2", model.getFlags().getApiVersion());
    }

    @Test
    public void testApiVersionInvalidFormatThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  apiVersion: "x1"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("apiVersion"));
    }

    @Test
    public void testApiVersionNullIsValid(@TempDir Path tempDir) throws Exception {
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
        assertNull(model.getFlags().getApiVersion());
    }

    // --- enableHealthCheck ---

    @Test
    public void testEnableHealthCheckDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableHealthCheck(), "enableHealthCheck must default to false");
    }
}
