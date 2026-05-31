package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

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

    // --- T.12: enableTelemetry default false + explicit true ---

    @Test
    public void testEnableTelemetryDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableTelemetry());
    }

    @Test
    public void testEnableTelemetryExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableTelemetry: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    telemetryName: "span"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableTelemetry());
    }

    // --- T.13: enableSearch default false + explicit true ---

    @Test
    public void testEnableSearchDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableSearch());
    }

    @Test
    public void testEnableSearchExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableSearch: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableSearch());
    }

    // --- T.14: enableOfflineSupport default false + explicit true ---

    @Test
    public void testEnableOfflineSupportDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableOfflineSupport());
    }

    @Test
    public void testEnableOfflineSupportExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableOfflineSupport: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableOfflineSupport());
    }

    // --- T.15: enableOpenApi default false + explicit true ---

    @Test
    public void testEnableOpenApiDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableOpenApi());
    }

    @Test
    public void testEnableOpenApiExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableOpenApi: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableOpenApi());
    }

    // --- T.16: enableTransform default false + explicit true ---

    @Test
    public void testEnableTransformDefaultsFalse(@TempDir Path tempDir) throws Exception {
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
        assertFalse(model.getFlags().isEnableTransform());
    }

    @Test
    public void testEnableTransformExplicitTrue(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  enableTransform: true
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertTrue(model.getFlags().isEnableTransform());
    }
}
