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

    // --- Real cartridge integration tests ---

    @Test
    public void testSpringBootCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-spring").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path controllerPath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java");
        Path pomPath = outputDir.toPath().resolve("backend/pom.xml");

        assertTrue(Files.exists(controllerPath), "BridgeController.java must exist under backend/");
        assertTrue(Files.exists(pomPath), "pom.xml must exist under backend/");

        String controllerContent = Files.readString(controllerPath);
        assertTrue(controllerContent.contains("public class BridgeController"));
        assertTrue(controllerContent.contains("@RestController"));

        String pomContent = Files.readString(pomPath);
        assertTrue(pomContent.contains("<artifactId>user-auth-service</artifactId>") ||
                   pomContent.contains("<artifactId>user-auth-service-backend</artifactId>"));
        assertTrue(pomContent.contains("spring-boot-starter-parent"));
    }

    @Test
    public void testQuarkusCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend/quarkus");
        File outputDir = tempDir.resolve("output-quarkus").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path resourcePath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeResource.java");
        Path pomPath = outputDir.toPath().resolve("backend/pom.xml");

        assertTrue(Files.exists(resourcePath), "BridgeResource.java must exist under backend/");
        assertTrue(Files.exists(pomPath), "pom.xml must exist under backend/");

        String resourceContent = Files.readString(resourcePath);
        assertTrue(resourceContent.contains("public class BridgeResource"));
        assertTrue(resourceContent.contains("import jakarta.ws.rs.*;"));
        assertTrue(resourceContent.contains("@Path(\"/api/auth\")"));

        String pomContent = Files.readString(pomPath);
        assertTrue(pomContent.contains("<artifactId>quarkus-bom</artifactId>"));
        assertTrue(pomContent.contains("<artifactId>quarkus-rest-jackson</artifactId>"));
    }

    @Test
    public void testFrontendUiSchemaCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("frontend/ui-schema");
        File outputDir = tempDir.resolve("output-frontend").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path uiSchemaPath = outputDir.toPath().resolve("frontend/UiLayoutSchema.json");
        assertTrue(Files.exists(uiSchemaPath));
        String uiContent = Files.readString(uiSchemaPath);
        assertTrue(uiContent.contains("\"id\": \"user-auth-service\""));
        assertTrue(uiContent.contains("\"endpointPath\": \"/login\""));
    }

    @Test
    public void testAngularCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("angular");
        File cartridgeDir = findCartridgeDir("frontend/angular");
        File outputDir = tempDir.resolve("output-angular").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsPath = outputDir.toPath()
                .resolve("frontend/src/app/bridge-form.component.ts");
        Path htmlPath = outputDir.toPath()
                .resolve("frontend/src/app/bridge-form.component.html");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(tsPath));
        assertTrue(Files.exists(htmlPath));
        assertTrue(Files.exists(pkgPath));
        String tsContent = Files.readString(tsPath);
        assertTrue(tsContent.contains("export class BridgeFormComponent"));
    }

    @Test
    public void testReactCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");
        File cartridgeDir = findCartridgeDir("frontend/react");
        File outputDir = tempDir.resolve("output-react").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path tsxPath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.tsx");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(tsxPath));
        assertTrue(Files.exists(pkgPath));
        String tsxContent = Files.readString(tsxPath);
        assertTrue(tsxContent.contains("export const ApiBridgeForm"));
    }

    @Test
    public void testVueCartridge(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("vue");
        File cartridgeDir = findCartridgeDir("frontend/vue");
        File outputDir = tempDir.resolve("output-vue").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path vuePath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.vue");
        Path pkgPath = outputDir.toPath().resolve("frontend/package.json");
        assertTrue(Files.exists(vuePath));
        assertTrue(Files.exists(pkgPath));
        String vueContent = Files.readString(vuePath);
        assertTrue(vueContent.contains("<template>"));
    }

    @Test
    public void testReactCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        File cartridgeDir = findCartridgeDir("frontend/react");
        File outputDir = tempDir.resolve("output-react-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listPath = outputDir.toPath().resolve("frontend/src/ApiBridgeList.tsx");
        Path viewPath = outputDir.toPath().resolve("frontend/src/ApiBridgeView.tsx");
        Path formPath = outputDir.toPath().resolve("frontend/src/ApiBridgeForm.tsx");
        Path appPath  = outputDir.toPath().resolve("frontend/src/App.tsx");
        assertTrue(Files.exists(listPath), "ApiBridgeList.tsx must be generated");
        assertTrue(Files.exists(viewPath), "ApiBridgeView.tsx must be generated");
        assertTrue(Files.exists(formPath), "ApiBridgeForm.tsx must be generated");
        assertTrue(Files.exists(appPath),  "App.tsx must be generated");

        String listContent = Files.readString(listPath);
        assertTrue(listContent.contains("ApiBridgeList"));
        assertTrue(listContent.contains("apib-table"));

        String viewContent = Files.readString(viewPath);
        assertTrue(viewContent.contains("ApiBridgeView"));
        assertTrue(viewContent.contains("apib-detail-grid"));
    }

    @Test
    public void testAngularCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        model.getFlags().setFeFlavor("angular");
        File cartridgeDir = findCartridgeDir("frontend/angular");
        File outputDir = tempDir.resolve("output-angular-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listTs   = outputDir.toPath().resolve("frontend/src/app/bridge-list.component.ts");
        Path listHtml = outputDir.toPath().resolve("frontend/src/app/bridge-list.component.html");
        Path viewTs   = outputDir.toPath().resolve("frontend/src/app/bridge-view.component.ts");
        Path viewHtml = outputDir.toPath().resolve("frontend/src/app/bridge-view.component.html");
        assertTrue(Files.exists(listTs),   "bridge-list.component.ts must be generated");
        assertTrue(Files.exists(listHtml), "bridge-list.component.html must be generated");
        assertTrue(Files.exists(viewTs),   "bridge-view.component.ts must be generated");
        assertTrue(Files.exists(viewHtml), "bridge-view.component.html must be generated");

        assertTrue(Files.readString(listTs).contains("BridgeListComponent"));
        assertTrue(Files.readString(viewTs).contains("BridgeViewComponent"));
    }

    @Test
    public void testVueCartridgeWithListViewForm(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createListViewFormModel();
        File cartridgeDir = findCartridgeDir("frontend/vue");
        File outputDir = tempDir.resolve("output-vue-lvf").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path listPath = outputDir.toPath().resolve("frontend/src/ApiBridgeList.vue");
        Path viewPath = outputDir.toPath().resolve("frontend/src/ApiBridgeView.vue");
        assertTrue(Files.exists(listPath), "ApiBridgeList.vue must be generated");
        assertTrue(Files.exists(viewPath), "ApiBridgeView.vue must be generated");

        assertTrue(Files.readString(listPath).contains("apib-table"));
        assertTrue(Files.readString(viewPath).contains("apib-detail-grid"));
    }

    // --- Composable cartridge tests ---

    @Test
    public void testMultipleCartridgesComposeToSameOutput(@TempDir Path tempDir) throws Exception {
        File cartridgeA = tempDir.resolve("cartridge-a").toFile();
        File cartridgeB = tempDir.resolve("cartridge-b").toFile();
        writeFtl(cartridgeA, "backend/pom.xml", "<project>backend</project>");
        writeFtl(cartridgeB, "frontend/package.json", "{\"name\":\"fe\"}");

        BridgeSchemaModel model = createTestModel();
        File output = tempDir.resolve("out").toFile();

        engine.generate(model, cartridgeA, output);
        engine.generate(model, cartridgeB, output);

        assertTrue(new File(output, "backend/pom.xml").exists());
        assertTrue(new File(output, "frontend/package.json").exists());
    }

    @Test
    public void testDirectoryStructureMirroredDirectly(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "backend/src/main/java/App.java", "// App");
        writeFtl(cartridge, "backend/pom.xml", "<project/>");
        writeFtl(cartridge, "Dockerfile", "FROM amazoncorretto:21");

        BridgeSchemaModel model = createTestModel();
        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "backend/src/main/java/App.java").exists());
        assertTrue(new File(output, "backend/pom.xml").exists());
        assertTrue(new File(output, "Dockerfile").exists());
        // old routing prefix must NOT appear
        assertFalse(new File(output, "backend-spring-boot").exists());
    }

    @Test
    public void testFeFlavorEmptyByDefaultWhenFlagsAbsent(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "Dockerfile",
                "<#if (feFlavor!\"\") != \"\">HAS_FE<#else>NO_FE</#if>");

        BridgeSchemaModel model = createTestModel();
        model.setFlags(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertEquals("NO_FE", Files.readString(new File(output, "Dockerfile").toPath()));
    }

    @Test
    public void testFeFlavorEmptyByDefaultWhenFlagsSetWithoutFeFlavor(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "Dockerfile",
                "<#if (feFlavor!\"\") != \"\">HAS_FE<#else>NO_FE</#if>");

        BridgeSchemaModel model = createTestModel();
        // Flags present but feFlavor NOT set
        model.getFlags().setFeFlavor(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertEquals("NO_FE", Files.readString(new File(output, "Dockerfile").toPath()));
    }

    @Test
    public void testFeFlavorSetWhenExplicit(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "Dockerfile",
                "<#if (feFlavor!\"\") != \"\">HAS_FE<#else>NO_FE</#if>");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertEquals("HAS_FE", Files.readString(new File(output, "Dockerfile").toPath()));
    }

    @Test
    public void testSkipsEmptyRenderedOutput(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "real.txt", "has content");
        writeFtl(cartridge, "empty.txt", "   \n  \n  ");

        BridgeSchemaModel model = createTestModel();
        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "real.txt").exists());
        assertFalse(new File(output, "empty.txt").exists());
    }

    @Test
    public void testNonFtlFilesIgnored(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "output.txt", "generated");
        File readme = new File(cartridge, "README.md");
        readme.getParentFile().mkdirs();
        try (FileWriter fw = new FileWriter(readme)) { fw.write("not a template"); }

        BridgeSchemaModel model = createTestModel();
        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertTrue(new File(output, "output.txt").exists());
        assertFalse(new File(output, "README.md").exists());
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

    // --- FreeMarker context tests ---

    @Test
    public void testDeployTargetContextAvailable(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "info.txt", "target=${deployTarget}");

        BridgeSchemaModel model = createTestModel();
        model.getFlags().setDeployTarget("kubernetes");

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertEquals("target=kubernetes",
                Files.readString(new File(output, "info.txt").toPath()));
    }

    @Test
    public void testDeployTargetEmptyWhenAbsent(@TempDir Path tempDir) throws Exception {
        File cartridge = tempDir.resolve("cartridge").toFile();
        writeFtl(cartridge, "info.txt", "target=${deployTarget}");

        BridgeSchemaModel model = createTestModel();
        model.setFlags(null);

        File output = tempDir.resolve("out").toFile();
        engine.generate(model, cartridge, output);

        assertEquals("target=", Files.readString(new File(output, "info.txt").toPath()));
    }

    // --- L8: API method name tests ---

    @Test
    public void testSpringBootMethodNamesSingleEndpoint(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-method-names").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path controllerPath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java");
        String content = Files.readString(controllerPath);
        assertTrue(content.contains("public ResponseEntity<String> postLogin("),
                "Expected method 'postLogin' for POST /login");
    }

    @Test
    public void testSpringBootMethodNamesMultipleEndpoints(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createMultiEndpointModel();
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-multi-method").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path controllerPath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java");
        String content = Files.readString(controllerPath);
        assertTrue(content.contains("public ResponseEntity<String> get("),
                "Expected method 'get' for GET /");
        assertTrue(content.contains("public ResponseEntity<String> getSubmissions("),
                "Expected method 'getSubmissions' for GET /submissions");
        assertTrue(content.contains("public ResponseEntity<String> postSubmissions("),
                "Expected method 'postSubmissions' for POST /submissions");
        assertTrue(content.contains("public ResponseEntity<String> getSubmissions("),
                "Expected method 'getSubmissions' for GET /submissions/{id}");
        assertTrue(content.contains("public ResponseEntity<String> putSubmissions("),
                "Expected method 'putSubmissions' for PUT /submissions/{id}");
        assertTrue(content.contains("public ResponseEntity<String> deleteSubmissions("),
                "Expected method 'deleteSubmissions' for DELETE /submissions/{id}");
    }

    @Test
    public void testQuarkusMethodNamesMultipleEndpoints(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createMultiEndpointModel();
        File cartridgeDir = findCartridgeDir("backend/quarkus");
        File outputDir = tempDir.resolve("output-quarkus-method").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path resourcePath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeResource.java");
        String content = Files.readString(resourcePath);
        assertTrue(content.contains("public Response get("),
                "Expected method 'get' for GET /");
        assertTrue(content.contains("public Response getSubmissions("),
                "Expected method 'getSubmissions' for GET /submissions");
        assertTrue(content.contains("public Response postSubmissions("),
                "Expected method 'postSubmissions' for POST /submissions");
        assertTrue(content.contains("public Response putSubmissions("),
                "Expected method 'putSubmissions' for PUT /submissions/{id}");
        assertTrue(content.contains("public Response deleteSubmissions("),
                "Expected method 'deleteSubmissions' for DELETE /submissions/{id}");
    }

    @Test
    public void testMethodNamesWithHyphenatedPaths(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("test-service");
        model.setBasePath("/api/test");
        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        model.setFlags(flags);
        BridgeSchemaModel.Endpoint ep = new BridgeSchemaModel.Endpoint();
        ep.setPath("/user-profiles");
        ep.setMethod("GET");
        ep.setBackendUrl("https://example.com/user-profiles");
        model.setEndpoints(java.util.List.of(ep));

        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-hyphen").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path controllerPath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java");
        String content = Files.readString(controllerPath);
        assertTrue(content.contains("public ResponseEntity<String> getUserProfiles("),
                "Hyphens should be removed and segments capitalized: 'getUserProfiles'");
    }

    // --- L9: DevOps cartridge tests ---

    @Test
    public void testDockerfileCartridgeSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("devops/dockerfile");
        File outputDir = tempDir.resolve("output-dockerfile-sb").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path dockerfilePath = outputDir.toPath().resolve("Dockerfile");
        assertTrue(Files.exists(dockerfilePath), "Dockerfile must be generated");
        String content = Files.readString(dockerfilePath);
        assertTrue(content.contains("FROM maven:3.9-amazoncorretto-21-alpine"), "Backend build stage");
        assertTrue(content.contains("FROM amazoncorretto:21-alpine"), "Runtime stage");
        assertTrue(content.contains("SERVER_PORT=8080"), "Spring Boot port env var");
        assertTrue(content.contains("BACKEND_URL_LOGIN="), "Per-endpoint URL env var");
        assertTrue(content.contains("AUTH_SERVER_URL="), "Bearer token env var");
        assertTrue(content.contains("USER 1001"), "Non-root user");
        assertTrue(content.contains("actuator/health/liveness"), "Spring Boot health check");
    }

    @Test
    public void testDockerfileCartridgeQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        File cartridgeDir = findCartridgeDir("devops/dockerfile");
        File outputDir = tempDir.resolve("output-dockerfile-q").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path dockerfilePath = outputDir.toPath().resolve("Dockerfile");
        assertTrue(Files.exists(dockerfilePath), "Dockerfile must be generated");
        String content = Files.readString(dockerfilePath);
        assertTrue(content.contains("QUARKUS_HTTP_PORT=8080"), "Quarkus port env var");
        assertTrue(content.contains("q/health/live"), "Quarkus health check");
        assertFalse(content.contains("actuator/health"), "No Spring Boot health check in Quarkus build");
    }

    @Test
    public void testDockerfileCartridgeWithFrontend(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setFeFlavor("react");
        File cartridgeDir = findCartridgeDir("devops/dockerfile");
        File outputDir = tempDir.resolve("output-dockerfile-fe").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path dockerfilePath = outputDir.toPath().resolve("Dockerfile");
        String content = Files.readString(dockerfilePath);
        assertTrue(content.contains("FROM node:20-alpine AS frontend-build"),
                "Frontend build stage must be present when feFlavor is set");
        assertTrue(content.contains("npm run build"), "npm build step");
        assertTrue(content.contains("static"), "Static assets copy");
    }

    @Test
    public void testDockerfileCartridgeNoFrontend(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("devops/dockerfile");
        File outputDir = tempDir.resolve("output-dockerfile-nofe").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path dockerfilePath = outputDir.toPath().resolve("Dockerfile");
        String content = Files.readString(dockerfilePath);
        assertFalse(content.contains("frontend-build"), "No frontend stage when feFlavor is empty");
    }

    @Test
    public void testDockerComposeCartridgeSpringBoot(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("devops/docker-compose");
        File outputDir = tempDir.resolve("output-compose-sb").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path composePath = outputDir.toPath().resolve("docker-compose.yml");
        assertTrue(Files.exists(composePath), "docker-compose.yml must be generated");
        String content = Files.readString(composePath);
        assertTrue(content.contains("services:"), "Must have services section");
        assertTrue(content.contains("user-auth-service:"), "Service named after id");
        assertTrue(content.contains("SERVER_PORT: \"8080\""), "Spring Boot port");
        assertTrue(content.contains("BACKEND_URL_LOGIN:"), "Per-endpoint URL");
        assertTrue(content.contains("user-auth-service-net"), "Network definition");
        assertTrue(content.contains("cpus: \"1.0\""), "Resource limits");
        assertTrue(content.contains("restart: unless-stopped"), "Restart policy");
    }

    @Test
    public void testDockerComposeCartridgeQuarkus(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setBackendFlavor("quarkus");
        File cartridgeDir = findCartridgeDir("devops/docker-compose");
        File outputDir = tempDir.resolve("output-compose-q").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path composePath = outputDir.toPath().resolve("docker-compose.yml");
        String content = Files.readString(composePath);
        assertTrue(content.contains("QUARKUS_HTTP_PORT: \"8080\""), "Quarkus port");
        assertFalse(content.contains("SERVER_PORT"), "No Spring Boot port in Quarkus build");
    }

    @Test
    public void testDockerComposeCartridgeWithApiKey(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setSecurityLevel("apiKey");
        File cartridgeDir = findCartridgeDir("devops/docker-compose");
        File outputDir = tempDir.resolve("output-compose-apikey").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path composePath = outputDir.toPath().resolve("docker-compose.yml");
        String content = Files.readString(composePath);
        assertTrue(content.contains("API_KEY:"), "API key env var");
        assertFalse(content.contains("AUTH_SERVER_URL"), "No bearer-token env in apiKey build");
    }

    // --- Helpers ---

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

    private BridgeSchemaModel createListViewFormModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("customer-service");
        model.setBasePath("/api/customers");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        flags.setEnableTelemetry(false);
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint listEp = new BridgeSchemaModel.Endpoint();
        listEp.setPath("/");
        listEp.setMethod("GET");
        listEp.setBackendUrl("https://example.com/customers");
        BridgeSchemaModel.UiLayout listLayout = new BridgeSchemaModel.UiLayout();
        listLayout.setComponent("List");
        model.getEndpoints();

        BridgeSchemaModel.Endpoint viewEp = new BridgeSchemaModel.Endpoint();
        viewEp.setPath("/{id}");
        viewEp.setMethod("GET");
        viewEp.setBackendUrl("https://example.com/customers/1");
        BridgeSchemaModel.UiLayout viewLayout = new BridgeSchemaModel.UiLayout();
        viewLayout.setComponent("View");
        viewEp.setUiLayout(viewLayout);

        BridgeSchemaModel.Endpoint formEp = new BridgeSchemaModel.Endpoint();
        formEp.setPath("/");
        formEp.setMethod("POST");
        formEp.setBackendUrl("https://example.com/customers");
        BridgeSchemaModel.UiLayout formLayout = new BridgeSchemaModel.UiLayout();
        formLayout.setComponent("Form");
        BridgeSchemaModel.Field nameField = new BridgeSchemaModel.Field();
        nameField.setName("name");
        nameField.setType("string");
        nameField.setRequired(true);
        formLayout.setFields(java.util.List.of(nameField));
        formEp.setUiLayout(formLayout);

        listEp.setUiLayout(listLayout);
        model.setEndpoints(java.util.List.of(listEp, viewEp, formEp));
        return model;
    }

    private BridgeSchemaModel createMultiEndpointModel() {
        BridgeSchemaModel model = new BridgeSchemaModel();
        model.setId("submission-service");
        model.setBasePath("/api/v1/submissions");

        BridgeSchemaModel.Flags flags = new BridgeSchemaModel.Flags();
        model.setFlags(flags);

        BridgeSchemaModel.Endpoint ep1 = new BridgeSchemaModel.Endpoint();
        ep1.setPath("/");
        ep1.setMethod("GET");
        ep1.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep2 = new BridgeSchemaModel.Endpoint();
        ep2.setPath("/submissions");
        ep2.setMethod("GET");
        ep2.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep3 = new BridgeSchemaModel.Endpoint();
        ep3.setPath("/submissions");
        ep3.setMethod("POST");
        ep3.setBackendUrl("https://backend.test/submissions");

        BridgeSchemaModel.Endpoint ep4 = new BridgeSchemaModel.Endpoint();
        ep4.setPath("/submissions/{id}");
        ep4.setMethod("GET");
        ep4.setBackendUrl("https://backend.test/submissions/1");

        BridgeSchemaModel.Endpoint ep5 = new BridgeSchemaModel.Endpoint();
        ep5.setPath("/submissions/{id}");
        ep5.setMethod("PUT");
        ep5.setBackendUrl("https://backend.test/submissions/1");

        BridgeSchemaModel.Endpoint ep6 = new BridgeSchemaModel.Endpoint();
        ep6.setPath("/submissions/{id}");
        ep6.setMethod("DELETE");
        ep6.setBackendUrl("https://backend.test/submissions/1");

        model.setEndpoints(java.util.List.of(ep1, ep2, ep3, ep4, ep5, ep6));
        return model;
    }

    @Test
    public void testSpringBootCartridgeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-spring-audit").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path auditDir = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/audit");
        assertTrue(Files.exists(auditDir), "audit/ package must be generated");
        assertTrue(Files.exists(auditDir.resolve("ProxySendEvent.java")), "ProxySendEvent.java");
        assertTrue(Files.exists(auditDir.resolve("ProxySuccessEvent.java")), "ProxySuccessEvent.java");
        assertTrue(Files.exists(auditDir.resolve("ProxyFailEvent.java")), "ProxyFailEvent.java");
        assertTrue(Files.exists(auditDir.resolve("AuditRecord.java")), "AuditRecord.java");
        assertTrue(Files.exists(auditDir.resolve("RedisAuditPublisher.java")), "RedisAuditPublisher.java");
        assertTrue(Files.exists(auditDir.resolve("AuditStreamConsumer.java")), "AuditStreamConsumer.java");

        String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
        assertTrue(pom.contains("spring-boot-starter-data-redis"), "Redis dep in pom");
        assertTrue(pom.contains("spring-boot-starter-data-mongodb"), "MongoDB dep in pom");

        String proxy = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("ApplicationEventPublisher"), "Event publisher injected");
        assertTrue(proxy.contains("ProxySendEvent"), "SEND event published");
        assertTrue(proxy.contains("ProxySuccessEvent"), "SUCCESS event published");
        assertTrue(proxy.contains("ProxyFailEvent"), "FAIL event published");

        String app = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/Application.java"));
        assertTrue(app.contains("@EnableAsync"), "@EnableAsync on Application");
    }

    @Test
    public void testSpringBootCartridgeAuditLogDisabledByDefault(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-spring-no-audit").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path auditDir = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/audit");
        assertFalse(Files.exists(auditDir.resolve("ProxySendEvent.java")),
                "No audit files when enableAuditLog=false");

        String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
        assertFalse(pom.contains("spring-boot-starter-data-redis"), "No Redis dep without audit");
    }

    @Test
    public void testQuarkusCartridgeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        model.getFlags().setBackendFlavor("quarkus");
        model.getFlags().setEnableTelemetry(false);
        File cartridgeDir = findCartridgeDir("backend/quarkus");
        File outputDir = tempDir.resolve("output-quarkus-audit").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        Path auditDir = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/audit");
        assertTrue(Files.exists(auditDir), "audit/ package must be generated");
        assertTrue(Files.exists(auditDir.resolve("RedisAuditPublisher.java")), "RedisAuditPublisher.java");
        assertTrue(Files.exists(auditDir.resolve("AuditStreamConsumer.java")), "AuditStreamConsumer.java");

        String pom = Files.readString(outputDir.toPath().resolve("backend/pom.xml"));
        assertTrue(pom.contains("quarkus-redis-client"), "Redis dep in pom");
        assertTrue(pom.contains("quarkus-mongodb-panache"), "MongoDB dep in pom");

        String proxy = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/ProxyService.java"));
        assertTrue(proxy.contains("fireAsync"), "CDI async events fired");
        assertTrue(proxy.contains("ProxySendEvent"), "SEND event fired");
    }

    @Test
    public void testDockerComposeWithAuditLog(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setEnableAuditLog(true);
        File cartridgeDir = findCartridgeDir("devops/docker-compose");
        File outputDir = tempDir.resolve("output-compose-audit").toFile();

        engine.generate(model, cartridgeDir, outputDir);

        String compose = Files.readString(outputDir.toPath().resolve("docker-compose.yml"));
        assertTrue(compose.contains("redis:"), "Redis service");
        assertTrue(compose.contains("mongo:"), "MongoDB service");
        assertTrue(compose.contains("SPRING_DATA_REDIS_URL"), "Redis URI env");
        assertTrue(compose.contains("SPRING_DATA_MONGODB_URI"), "MongoDB URI env");
        assertTrue(compose.contains("depends_on"), "App depends on redis and mongo");
    }

    private void writeFtl(File cartridgeDir, String relativePath, String content) throws IOException {
        File target = new File(cartridgeDir, relativePath + ".ftl");
        target.getParentFile().mkdirs();
        try (FileWriter fw = new FileWriter(target)) {
            fw.write(content);
        }
    }

    private File findCartridgeDir(String cartridgePath) {
        File dir = new File("../apibridge-cartridges/" + cartridgePath);
        if (!dir.exists()) {
            dir = new File("apibridge-cartridges/" + cartridgePath);
        }
        if (!dir.exists()) {
            throw new IllegalStateException("Cartridge folder not found: " + cartridgePath);
        }
        return dir;
    }
}
