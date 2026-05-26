package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class YamlParserTest {

    private YamlParser parser;

    @BeforeEach
    public void setUp() {
        parser = new YamlParser();
    }

    // --- File access validation ---

    @Test
    public void testNullFileThrows() {
        assertThrows(IllegalArgumentException.class, () -> parser.parse(null));
    }

    @Test
    public void testNonExistentFileThrows(@TempDir Path tempDir) {
        File ghost = tempDir.resolve("does-not-exist.yaml").toFile();
        assertThrows(FileNotFoundException.class, () -> parser.parse(ghost));
    }

    @Test
    public void testDirectoryThrows(@TempDir Path tempDir) {
        File dir = tempDir.toFile();
        assertThrows(IllegalArgumentException.class, () -> parser.parse(dir));
    }

    @Test
    public void testMalformedYamlThrows(@TempDir Path tempDir) throws IOException {
        // Unclosed double-quoted scalar — guaranteed SnakeYAML ScannerException
        File file = writeYaml(tempDir, "malformed.yaml", """
                id: "unclosed
                basePath: /api
                """);
        assertThrows(IOException.class, () -> parser.parse(file));
    }

    // --- Required top-level field validation ---

    @Test
    public void testMissingIdThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("id"));
    }

    @Test
    public void testBlankIdThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "   "
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("id"));
    }

    @Test
    public void testBlankBasePathThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "   "
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("basePath"));
    }

    @Test
    public void testMissingBasePathThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("basePath"));
    }

    @Test
    public void testEmptyEndpointsThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints: []
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("endpoints"));
    }

    // --- Flags validation ---

    @Test
    public void testInvalidBackendFlavorThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testInvalidUiPatternThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  uiPattern: "wizard"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("uiPattern"));
    }

    @Test
    public void testInvalidFeFlavorThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testInvalidDeployTargetThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testDeployTargetAbsentMeansNullNoDeploymentConfig(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testFeFlavorValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testFeFlavorDefaultsToReact(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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
        assertEquals("react", model.getFlags().getFeFlavor());
    }

    @Test
    public void testUiPatternValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                flags:
                  uiPattern: "Form-Engine"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals("Form-Engine", model.getFlags().getUiPattern());
    }

    @Test
    public void testDeployTargetValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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

    @Test
    public void testBackendFlavorValidationIsCaseInsensitive(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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

    // --- Endpoint field validation ---

    @Test
    public void testMissingEndpointPathThrows(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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
        File file = writeYaml(tempDir, "schema.yaml", """
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

    @Test
    public void testTelemetryEnabledRequiresTelemetryName(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
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
    public void testTelemetryNameOptionalWhenDisabled(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
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

    // --- UiLayout validation ---

    @Test
    public void testUiLayoutRequiresComponent(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      fields: []
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("uiLayout"));
        assertTrue(ex.getMessage().contains("component"));
    }

    @Test
    public void testUiLayoutFieldRequiresName(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - type: "string"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("fields[0]"));
        assertTrue(ex.getMessage().contains("name"));
    }

    @Test
    public void testUiLayoutFieldRequiresType(@TempDir Path tempDir) throws IOException {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                """);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> parser.parse(file));
        assertTrue(ex.getMessage().contains("fields[0]"));
        assertTrue(ex.getMessage().contains("type"));
    }

    @Test
    public void testValidSchemaWithUiLayout(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test-service"
                basePath: "/api/test"
                endpoints:
                  - path: "/submit"
                    method: "POST"
                    backendUrl: "https://example.com/submit"
                    uiLayout:
                      component: "Form"
                      fields:
                        - name: "email"
                          type: "string"
                          required: true
                        - name: "age"
                          type: "number"
                          required: false
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        assertEquals(1, model.getEndpoints().size());
        BridgeSchemaModel.UiLayout layout = model.getEndpoints().get(0).getUiLayout();
        assertNotNull(layout);
        assertEquals("Form", layout.getComponent());
        assertEquals(2, layout.getFields().size());
        assertEquals("email", layout.getFields().get(0).getName());
        assertTrue(layout.getFields().get(0).isRequired());
        assertFalse(layout.getFields().get(1).isRequired());
    }

    @Test
    public void testUiLayoutWithNullFieldsIsValid(@TempDir Path tempDir) throws Exception {
        File file = writeYaml(tempDir, "schema.yaml", """
                id: "test"
                basePath: "/api"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://example.com/run"
                    uiLayout:
                      component: "Form"
                """);
        BridgeSchemaModel model = parser.parse(file);
        assertNotNull(model);
        BridgeSchemaModel.UiLayout layout = model.getEndpoints().get(0).getUiLayout();
        assertNotNull(layout);
        assertEquals("Form", layout.getComponent());
        assertNull(layout.getFields());
    }

    // --- Helper ---

    private File writeYaml(Path dir, String name, String content) throws IOException {
        File file = dir.resolve(name).toFile();
        try (FileWriter writer = new FileWriter(file)) {
            writer.write(content);
        }
        return file;
    }
}
