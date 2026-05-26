package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class ApiBridgeCartridgeEngineTest {

    private YamlParser parser;
    private ApiBridgeCartridgeEngine engine;

    @BeforeEach
    public void setUp() {
        parser = new YamlParser();
        engine = new ApiBridgeCartridgeEngine();
    }

    @Test
    public void testParserValidYaml(@TempDir Path tempDir) throws Exception {
        File yamlFile = tempDir.resolve("valid-schema.yaml").toFile();
        String validYaml = """
                id: "test-service"
                basePath: "/api/test"
                flags:
                  enableTelemetry: true
                  securityLevel: "apiKey"
                endpoints:
                  - path: "/run"
                    method: "POST"
                    backendUrl: "https://auth.internal/run"
                    telemetryName: "apibridge_test_run"
                """;
        
        try (FileWriter writer = new FileWriter(yamlFile)) {
            writer.write(validYaml);
        }

        BridgeSchemaModel model = parser.parse(yamlFile);
        assertNotNull(model);
        assertEquals("test-service", model.getId());
        assertEquals("/api/test", model.getBasePath());
        assertEquals("apiKey", model.getFlags().getSecurityLevel());
    }

    @Test
    public void testSpringBootCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend-spring-boot");
        File outputDir = tempDir.resolve("output-spring").toFile();

        // Execute Cartridge Projection
        engine.generate(model, cartridgeDir, outputDir);

        // Verify Output Suffix Stripped (.ftl is gone)
        Path controllerPath = outputDir.toPath().resolve("Controller.java");
        Path pomPath = outputDir.toPath().resolve("pom.xml");
        
        assertTrue(Files.exists(controllerPath));
        assertTrue(Files.exists(pomPath));

        String controllerContent = Files.readString(controllerPath);
        assertTrue(controllerContent.contains("public class UserAuthServiceController"));
        assertTrue(controllerContent.contains("@RestController"));

        String pomContent = Files.readString(pomPath);
        assertTrue(pomContent.contains("<artifactId>user-auth-service</artifactId>"));
        assertTrue(pomContent.contains("<version>${spring.boot.version}</version>"));
    }

    @Test
    public void testQuarkusCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend-quarkus");
        File outputDir = tempDir.resolve("output-quarkus").toFile();

        // Execute Cartridge Projection
        engine.generate(model, cartridgeDir, outputDir);

        Path resourcePath = outputDir.toPath().resolve("Resource.java");
        Path pomPath = outputDir.toPath().resolve("pom.xml");

        assertTrue(Files.exists(resourcePath));
        assertTrue(Files.exists(pomPath));

        String resourceContent = Files.readString(resourcePath);
        assertTrue(resourceContent.contains("public class UserAuthServiceResource"));
        assertTrue(resourceContent.contains("import jakarta.ws.rs.*;"));
        assertTrue(resourceContent.contains("@Path(\"/api/auth\")"));

        String pomContent = Files.readString(pomPath);
        assertTrue(pomContent.contains("<artifactId>quarkus-bom</artifactId>"));
        assertTrue(pomContent.contains("<artifactId>quarkus-rest-jackson</artifactId>"));
    }

    @Test
    public void testFrontendCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("frontend-ui-schema");
        File outputDir = tempDir.resolve("output-frontend").toFile();

        // Execute Cartridge Projection
        engine.generate(model, cartridgeDir, outputDir);

        Path uiSchemaPath = outputDir.toPath().resolve("UiLayoutSchema.json");
        assertTrue(Files.exists(uiSchemaPath));

        String uiContent = Files.readString(uiSchemaPath);
        assertTrue(uiContent.contains("\"id\": \"user-auth-service\""));
        assertTrue(uiContent.contains("\"endpointPath\": \"/login\""));
    }

    @Test
    public void testAngularCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setUiPattern("form-engine");
        
        File cartridgeDir = findCartridgeDir("frontend-angular");
        File outputDir = tempDir.resolve("output-angular").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsPath = outputDir.toPath().resolve("bridge-form.component.ts");
        Path htmlPath = outputDir.toPath().resolve("bridge-form.component.html");

        assertTrue(Files.exists(tsPath));
        assertTrue(Files.exists(htmlPath));

        String tsContent = Files.readString(tsPath);
        assertTrue(tsContent.contains("export class BridgeFormComponent"));
        assertTrue(tsContent.contains("form = new FormGroup({})"));
        assertTrue(tsContent.contains("fields: FormlyFieldConfig[]"));

        String htmlContent = Files.readString(htmlPath);
        assertTrue(htmlContent.contains("formly-form"));
    }

    @Test
    public void testReactCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setUiPattern("web-component");
        
        File cartridgeDir = findCartridgeDir("frontend-react");
        File outputDir = tempDir.resolve("output-react").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsxPath = outputDir.toPath().resolve("ApiBridgeForm.tsx");
        assertTrue(Files.exists(tsxPath));

        String tsxContent = Files.readString(tsxPath);
        assertTrue(tsxContent.contains("export const ApiBridgeForm"));
        assertTrue(tsxContent.contains("webComponentRef"));
        assertTrue(tsxContent.contains("api-bridge-form"));
    }

    @Test
    public void testVueCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setUiPattern("form-engine");
        
        File cartridgeDir = findCartridgeDir("frontend-vue");
        File outputDir = tempDir.resolve("output-vue").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path vuePath = outputDir.toPath().resolve("ApiBridgeForm.vue");
        assertTrue(Files.exists(vuePath));

        String vueContent = Files.readString(vuePath);
        assertTrue(vueContent.contains("<template>"));
        assertTrue(vueContent.contains("export default defineComponent"));
        assertTrue(vueContent.contains("formData"));
        assertTrue(vueContent.contains("errors"));
    }

    private BridgeSchemaModel createTestModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("user-auth-service");
        model.setBasePath("/api/auth");
        
        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(true);
        flags.setSecurityLevel("bearer-token");
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint endpoint = new BridgeSchemaModel.Endpoint();
        endpoint.setPath("/login");
        endpoint.setMethod("POST");
        endpoint.setBackendUrl("https://auth.internal/login");
        endpoint.setTelemetryName("apibridge_auth_login");
        model.setEndpoints(java.util.List.of(endpoint));

        return model;
    }

    // --- Subdirectory routing tests ---

    @Test
    public void testFlavorDirSelectionPicksMatchingBeDir(@TempDir Path tempDir) throws Exception {
        // Build a minimal cartridge with backend-spring-boot/ and backend-quarkus/ subdirs
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "backend-spring-boot/result.txt", "spring");
        writeFtl(cartridge, "backend-quarkus/result.txt", "quarkus");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("spring-boot");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        // Only backend/result.txt from spring-boot should exist
        assertTrue(new File(output, "backend/result.txt").exists());
        assertEquals("spring", Files.readString(new File(output, "backend/result.txt").toPath()));
        assertFalse(new File(output, "backend-quarkus/result.txt").exists());
    }

    @Test
    public void testFlavorDirSelectionSkipsMismatchedFeDir(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "frontend-angular/component.ts", "angular-component");
        writeFtl(cartridge, "frontend-react/App.tsx", "react-component");
        writeFtl(cartridge, "frontend-vue/App.vue", "vue-component");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "frontend/App.tsx").exists());
        assertFalse(new File(output, "frontend/component.ts").exists());
        assertFalse(new File(output, "frontend/App.vue").exists());
    }

    @Test
    public void testOutputPathMappingStripsFlavorPrefix(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "backend-spring-boot/src/main/java/App.java", "// App");
        writeFtl(cartridge, "Dockerfile", "FROM amazoncorretto:21");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("spring-boot");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "backend/src/main/java/App.java").exists());
        assertTrue(new File(output, "Dockerfile").exists());
        assertFalse(new File(output, "backend-spring-boot/src/main/java/App.java").exists());
    }

    @Test
    public void testSkipsEmptyRenderedOutput(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        // Template that produces content
        writeFtl(cartridge, "real.txt", "has content");
        // Template that produces only whitespace (simulates conditional that evaluates to nothing)
        writeFtl(cartridge, "empty.txt", "   \n  \n  ");

        BridgeSchemaModel model = createTestModel();
        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "real.txt").exists());
        assertFalse(new File(output, "empty.txt").exists());
    }

    @Test
    public void testRootTemplatesStillOutputToRoot(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "docker-compose.yml", "version: '3'");
        writeFtl(cartridge, ".dockerignore", "target/");
        writeFtl(cartridge, "backend-spring-boot/pom.xml", "<project/>");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("spring-boot");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "docker-compose.yml").exists());
        assertTrue(new File(output, ".dockerignore").exists());
        assertTrue(new File(output, "backend/pom.xml").exists());
    }

    // --- Input guard tests ---

    @Test
    public void testNullModelThrows(@TempDir Path tempDir) throws IOException {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "file.txt", "content");
        File output = tempDir.resolve("out").toFile();
        assertThrows(IllegalArgumentException.class, () -> engine.generate(null, cartridge, output));
    }

    @Test
    public void testNullCartridgeDirThrows(@TempDir Path tempDir) throws IOException {
        File output = tempDir.resolve("out").toFile();
        assertThrows(IllegalArgumentException.class,
                () -> engine.generate(createTestModel(), null, output));
    }

    @Test
    public void testNonExistentCartridgeDirThrows(@TempDir Path tempDir) throws IOException {
        File missing = tempDir.resolve("does-not-exist").toFile();
        File output = tempDir.resolve("out").toFile();
        assertThrows(IllegalArgumentException.class,
                () -> engine.generate(createTestModel(), missing, output));
    }

    @Test
    public void testFileAsCartridgeDirThrows(@TempDir Path tempDir) throws IOException {
        File file = tempDir.resolve("notadir.txt").toFile();
        file.createNewFile();
        File output = tempDir.resolve("out").toFile();
        assertThrows(IllegalArgumentException.class,
                () -> engine.generate(createTestModel(), file, output));
    }

    @Test
    public void testNullOutputDirThrows(@TempDir Path tempDir) throws IOException {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "file.txt", "content");
        assertThrows(IllegalArgumentException.class,
                () -> engine.generate(createTestModel(), cartridge, null));
    }

    @Test
    public void testEmptyCartridgeThrows(@TempDir Path tempDir) {
        File cartridge = tempDir.resolve("cartridge").toFile();
        cartridge.mkdirs();
        File output = tempDir.resolve("out").toFile();
        assertThrows(IllegalArgumentException.class,
                () -> engine.generate(createTestModel(), cartridge, output));
    }

    @Test
    public void testOutputDirCreatedIfAbsent(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "hello.txt", "world");
        File output = tempDir.resolve("nested/output/dir").toFile();
        assertFalse(output.exists());
        engine.generate(createTestModel(), cartridge, output);
        assertTrue(output.exists());
        assertTrue(new File(output, "hello.txt").exists());
    }

    // --- deployTarget context tests ---

    @Test
    public void testDeployTargetConditionalSkipWhenAbsent(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "docker-compose.yml",
                "<#if deployTarget == \"docker-compose\">docker-compose content</#if>");

        BridgeSchemaModel model = createTestModel();
        model.setFlags(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertFalse(new File(output, "docker-compose.yml").exists());
    }

    @Test
    public void testDeployTargetConditionalRenderWhenSet(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "docker-compose.yml",
                "<#if deployTarget == \"docker-compose\">docker-compose content</#if>");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setDeployTarget("docker-compose");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "docker-compose.yml").exists());
        assertEquals("docker-compose content",
                Files.readString(new File(output, "docker-compose.yml").toPath()));
    }

    // --- Default flavor routing tests ---

    @Test
    public void testDefaultBeFlavorRoutesToSpringBoot(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "backend-spring-boot/marker.txt", "spring-boot");

        BridgeSchemaModel model = createTestModel();
        model.setFlags(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "backend/marker.txt").exists());
        assertEquals("spring-boot",
                Files.readString(new File(output, "backend/marker.txt").toPath()));
    }

    @Test
    public void testDefaultFeFlavorRoutesToReact(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "frontend-react/marker.txt", "react");

        BridgeSchemaModel model = createTestModel();
        model.setFlags(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "frontend/marker.txt").exists());
        assertEquals("react",
                Files.readString(new File(output, "frontend/marker.txt").toPath()));
    }

    private void writeFtl(File cartridgeDir, String relativePath, String content) throws IOException {
        File target = new File(cartridgeDir, relativePath + ".ftl");
        target.getParentFile().mkdirs();
        try (FileWriter fw = new FileWriter(target)) {
            fw.write(content);
        }
    }

    private File findCartridgeDir(String cartridgeName) {
        // Look up cartridge directory relative to test runtime environment
        File dir = new File("../apibridge-cartridges/" + cartridgeName);
        if (!dir.exists()) {
            dir = new File("apibridge-cartridges/" + cartridgeName);
        }
        if (!dir.exists()) {
            throw new IllegalStateException("Cartridge folder not found: " + cartridgeName);
        }
        return dir;
    }
}
