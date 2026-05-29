package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserFlagsTest extends YamlParserTestBase {

    // --- backendFlavor ---

    @Test
    public void testInvalidBackendFlavorThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  backendFlavor: "django"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("backendFlavor"));
    }

    @Test
    public void testBackendFlavorValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  backendFlavor: "Spring-Boot"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("Spring-Boot", model.getFlags().getBackendFlavor());
    }

    // --- feFlavor ---

    @Test
    public void testInvalidFeFlavorThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  feFlavor: "svelte"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("feFlavor"));
    }

    @Test
    public void testFeFlavorValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  feFlavor: "Angular"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("Angular", model.getFlags().getFeFlavor());
    }

    @Test
    public void testFeFlavorDefaultsToNull(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  backendFlavor: "spring-boot"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertNull(model.getFlags().getFeFlavor());
    }

    // --- securityLevel ---

    @Test
    public void testInvalidSecurityLevelThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  securityLevel: "oauth2"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("securityLevel"));
    }

    @Test
    public void testValidSecurityLevelBearerToken(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  securityLevel: "bearer-token"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("bearer-token", model.getFlags().getSecurityLevel());
    }

    @Test
    public void testValidSecurityLevelApiKey(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  securityLevel: "apiKey"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("apiKey", model.getFlags().getSecurityLevel());
    }

    @Test
    public void testSecurityLevelValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  securityLevel: "Bearer-Token"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("Bearer-Token", model.getFlags().getSecurityLevel());
    }

    @Test
    public void testSecurityLevelAbsentIsValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  backendFlavor: "spring-boot"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertNull(model.getFlags().getSecurityLevel());
    }

    // --- deployTarget ---

    @Test
    public void testInvalidDeployTargetThrows(@TempDir Path tempDir) throws IOException {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  deployTarget: "heroku"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("deployTarget"));
    }

    @Test
    public void testValidDeployTargetDockerCompose(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  deployTarget: "docker-compose"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("docker-compose", model.getFlags().getDeployTarget());
    }

    @Test
    public void testValidDeployTargetKubernetes(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  deployTarget: "kubernetes"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("kubernetes", model.getFlags().getDeployTarget());
    }

    @Test
    public void testValidDeployTargetOpenShift(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  deployTarget: "openshift"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("openshift", model.getFlags().getDeployTarget());
    }

    @Test
    public void testDeployTargetAbsentMeansNullFlags(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertNull(model.getFlags());
    }

    @Test
    public void testDeployTargetValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  deployTarget: "Docker-Compose"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("Docker-Compose", model.getFlags().getDeployTarget());
    }

    // --- T.2: backendFlavor "quarkus" valid parse ---

    @Test
    public void testBackendFlavorQuarkusValid(@TempDir Path tempDir) throws Exception {
        var file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  backendFlavor: "quarkus"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertEquals("quarkus", model.getFlags().getBackendFlavor());
    }

    // --- T.17: backendFlavor defaults "spring-boot" when omitted ---

    @Test
    public void testBackendFlavorDefaultSpringBoot(@TempDir Path tempDir) throws Exception {
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
        assertNotNull(model.getFlags());
        assertEquals("spring-boot", model.getFlags().getBackendFlavor());
    }
}
