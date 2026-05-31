package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileWriter;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

public class CoreCartridgeEngineTest extends ApiBridgeCartridgeEngineTestBase {

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
}
