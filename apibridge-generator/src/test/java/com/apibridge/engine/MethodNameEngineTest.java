package com.apibridge.engine;

import com.apibridge.engine.model.BridgeSchemaModel;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

public class MethodNameEngineTest extends ApiBridgeCartridgeEngineTestBase {

    // --- API method name tests ---

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
        model.setEndpoints(List.of(ep));

        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("output-hyphen").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        Path controllerPath = outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java");
        String content = Files.readString(controllerPath);
        assertTrue(content.contains("public ResponseEntity<String> getUserProfiles("),
                "Hyphens should be removed and segments capitalized: 'getUserProfiles'");
    }

    // --- BridgeController security branches ---

    @Test
    public void testSpringBootBridgeControllerBearerToken(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("out").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        String content = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("AUTH_SERVER_URL"), "Bearer-token auth server URL");
        assertFalse(content.contains("X-API-Key"), "No apiKey header in bearer-token build");
    }

    @Test
    public void testSpringBootBridgeControllerApiKey(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setSecurityLevel("apiKey");
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("out").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        String content = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertTrue(content.contains("X-API-Key"), "apiKey header validation");
        assertFalse(content.contains("AUTH_SERVER_URL"), "No bearer-token URL in apiKey build");
    }

    @Test
    public void testSpringBootBridgeControllerNoSecurity(@TempDir Path tempDir) throws Exception {
        BridgeSchemaModel model = createTestModel();
        model.getFlags().setSecurityLevel(null);
        File cartridgeDir = findCartridgeDir("backend/spring-boot");
        File outputDir = tempDir.resolve("out").toFile();
        engine.generate(model, cartridgeDir, outputDir);

        String content = Files.readString(outputDir.toPath()
                .resolve("backend/src/main/java/com/apibridge/generated/BridgeController.java"));
        assertFalse(content.contains("AUTH_SERVER_URL"), "No bearer-token code without security");
        assertFalse(content.contains("X-API-Key"), "No apiKey code without security");
    }
}
